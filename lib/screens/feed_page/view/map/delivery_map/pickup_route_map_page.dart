import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:nagpur_rider/screens/feed_page/view/map/store_pickup_route/services/location_service.dart';
import 'package:nagpur_rider/screens/feed_page/view/map/store_pickup_route/services/map_service.dart';
import 'package:nagpur_rider/utils/widgets/custom_scaffold.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import '../../../../../config/colors.dart';
import '../../../../../utils/map/google_map_helpers.dart';
import '../../../../../config/theme_bloc.dart';
import '../../../model/available_orders.dart';
import '../../../bloc/order_details_bloc/order_details_bloc.dart';
import '../../../bloc/order_details_bloc/order_details_event.dart';
import '../../../bloc/order_details_bloc/order_details_state.dart';
import '../../../../../utils/widgets/custom_button.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../utils/widgets/custom_appbar_without_navbar.dart';
import 'package:go_router/go_router.dart';
import '../../../../../router/app_routes.dart';
import '../../../../../utils/widgets/toast_message.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../navigation/navigation_widgets.dart';
import '../navigation/turn_by_turn_navigator.dart';
import '../navigation/voice_guidance.dart';

class PickupRouteMapPage extends StatefulWidget {
  final Orders order;
  final OrderDetailsBloc? bloc;

  const PickupRouteMapPage({super.key, required this.order, this.bloc});

  @override
  State<PickupRouteMapPage> createState() => _PickupRouteMapPageState();
}

class _PickupRouteMapPageState extends State<PickupRouteMapPage>
    with TickerProviderStateMixin {
  gm.GoogleMapController? _mapController;
  LocationData? _currentLocation;
  bool _isLoadingLocation = true;
  List<LatLng> _accurateRoutePoints = [];
  List<RouteOption> _routeOptions = [];
  int _selectedRouteIndex = 0;
  Map<int, gm.BitmapDescriptor> _routeLabelIcons = {};
  StreamSubscription<geo.Position>? _locationSubscription;
  double _riderRotation = 0;
  LatLng? _animatedRiderLatLng;
  AnimationController? _animationController;
  DateTime? _lastRerouteTime;
  bool _isFetchingRoute = false;
  bool _hasFittedToRoute = false;
  static const LatLng _nagpurCenter = LatLng(21.1458, 79.0882);
  bool _isUsingFallbackLocation = false;
  bool _isRetryingRoute = false;

  // In-app turn-by-turn navigation
  bool _isNavigating = false;
  bool _isFollowingRider = true;
  TurnByTurnNavigator? _navigator;
  NavProgress? _navProgress;
  final VoiceGuidance _voice = VoiceGuidance();
  double _navBearing = 0;
  double _speedMps = 0;

  // Manual confirmation variables
  bool _hasReachedDestination = false;
  bool _hasConfirmedArrival = false;

  // Stage indicator: 0 = heading to destination, 1 = arrived
  int get _currentStage => _hasReachedDestination ? 1 : 0;

  @override
  void initState() {
    super.initState();

    MapService.preloadMarkerIcons().then((_) {
      if (mounted) setState(() {});
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.bloc != null) {
      final currentState = widget.bloc!.state;
      if (currentState is OrderDetailsSuccess) {
        final hasAnyReachedDestination =
            currentState.order.items?.any(
              (item) => item.reachedDestination == true,
            ) ??
            false;
        if (hasAnyReachedDestination) {
          _hasReachedDestination = true;
        }
      }
    }

    // Also check the order data directly if bloc is not available
    if (widget.order.items != null) {
      final hasAnyReachedDestination = widget.order.items!.any(
        (item) => item.reachedDestination == true,
      );
      if (hasAnyReachedDestination) {
        _hasReachedDestination = true;
      }
    }

    Future.delayed(const Duration(seconds: 6), () {
      if (_isLoadingLocation) {
        _setFallbackLocation();
      }
    });

    _getCurrentLocation();
    _startLocationUpdates();
    _voice.init();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = Location();

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          _setFallbackLocation();
          return;
        }
      }

      PermissionStatus permissionGranted;
      try {
        permissionGranted = await Future.microtask(
          () async => await location.hasPermission(),
        );
      } catch (e) {
        _setFallbackLocation();
        return;
      }

      if (permissionGranted == PermissionStatus.denied) {
        try {
          permissionGranted = await Future.microtask(
            () async => await location.requestPermission(),
          );
          if (permissionGranted != PermissionStatus.granted) {
            _setFallbackLocation();
            return;
          }
        } catch (e) {
          _setFallbackLocation();
          return;
        }
      }

      final locationData = await location.getLocation().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Location request timed out'),
      );

      _applyInitialLocation(locationData);
    } catch (e) {
      // The location plugin can time out without a fresh GPS fix; try
      // geolocator before falling back to the delivery address.
      final fix = await _getGeolocatorFix();
      if (!mounted) return;
      if (fix != null) {
        _applyInitialLocation(fix);
      } else {
        _setFallbackLocation();
      }
    }
  }

  void _applyInitialLocation(LocationData locationData) {
    setState(() {
      _currentLocation = locationData;
      _isUsingFallbackLocation = false;
      _isLoadingLocation = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToAllPoints();
      _fetchAccurateRoute();
    });
  }

  Future<LocationData?> _getGeolocatorFix() async {
    try {
      final lastKnown = await geo.Geolocator.getLastKnownPosition();
      if (lastKnown != null) return _positionToLocationData(lastKnown);

      final current = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return _positionToLocationData(current);
    } catch (_) {
      return null;
    }
  }

  LocationData _positionToLocationData(geo.Position position) {
    return LocationData.fromMap({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'heading': position.heading,
      'speed': position.speed,
    });
  }

  void _checkArrivalStatus() {
    // Check if arrival has already been confirmed based on order data
    if (widget.order.items != null) {
      final hasAnyReachedDestination = widget.order.items!.any(
        (item) => item.reachedDestination == true,
      );
      if (hasAnyReachedDestination && !_hasReachedDestination) {
        setState(() {
          _hasReachedDestination = true;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check arrival status whenever dependencies change
    _checkArrivalStatus();
  }

  void _setFallbackLocation() {
    setState(() {
      _isUsingFallbackLocation = true;
      // Use shipping address coordinates as fallback location
      double fallbackLat = _nagpurCenter.latitude;
      double fallbackLng = _nagpurCenter.longitude;

      if (widget.order.deliveryRoute?.routeDetails != null &&
          widget.order.deliveryRoute!.routeDetails!.isNotEmpty) {
        final lastIndex = widget.order.deliveryRoute!.routeDetails!.length - 1;
        final shippingAddress =
            widget.order.deliveryRoute!.routeDetails![lastIndex];

        if (shippingAddress.latitude != null &&
            shippingAddress.longitude != null) {
          fallbackLat = shippingAddress.latitude!;
          fallbackLng = shippingAddress.longitude!;
        } else {}
      }

      _currentLocation = LocationData.fromMap({
        'latitude': fallbackLat,
        'longitude': fallbackLng,
      });
      _isLoadingLocation = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToAllPoints();
      _fetchAccurateRoute();
    });
  }

  bool _isValidLatLng(LatLng point) {
    return !point.latitude.isNaN &&
        !point.latitude.isInfinite &&
        !point.longitude.isNaN &&
        !point.longitude.isInfinite;
  }

  void _fitMapToAllPoints() {
    if (_currentLocation == null) return;

    final routePoints = MapService.generateDeliveryRoutePoints(
      _currentLocation,
      widget.order.deliveryRoute?.routeDetails,
    );

    final List<LatLng> allPoints = List.of(routePoints);

    if (allPoints.isEmpty) {
      final currentLatLng = _getCurrentLocationLatLng();
      if (_isValidLatLng(currentLatLng)) {
        allPoints.add(currentLatLng);
      }
      final destLatLng = _getDestinationLocation();
      if (_isValidLatLng(destLatLng)) {
        allPoints.add(destLatLng);
      }
    }

    GoogleMapHelpers.fitPoints(
      _mapController,
      allPoints,
      padding: 50,
      singlePointZoom: 13.0,
    );
  }

  Future<void> _fetchAccurateRoute() async {
    if (_currentLocation == null || _isFetchingRoute) return;

    _isFetchingRoute = true;
    _lastRerouteTime = DateTime.now();

    final routePoints = MapService.generateDeliveryRoutePoints(
      _currentLocation,
      widget.order.deliveryRoute?.routeDetails,
    );

    if (routePoints.length >= 2) {
      final options = await MapService.fetchRouteOptions(
        routePoints.first,
        routePoints.last,
      );
      if (!mounted) {
        _isFetchingRoute = false;
        return;
      }
      final selectedIndex =
          _isNavigating
              ? _routeMatchingCurrent(options)
              : (_selectedRouteIndex < options.length
                  ? _selectedRouteIndex
                  : 0);
      final accuratePoints =
          options.isNotEmpty ? options[selectedIndex].points : routePoints;
      final labelIcons = await _loadRouteLabelIcons(options, selectedIndex);
      if (mounted) {
        setState(() {
          _routeOptions = options;
          _selectedRouteIndex = selectedIndex;
          _routeLabelIcons = labelIcons;
          _accurateRoutePoints = accuratePoints;
        });
        final navigator = _navigator;
        if (_isNavigating && navigator != null && options.isNotEmpty) {
          navigator.setRoute(options[selectedIndex]);
          setState(() {
            _navProgress = navigator.update(_getCurrentLocationLatLng());
          });
        }
        // Zoom to the road route the first time it arrives
        if (!_hasFittedToRoute && _mapController != null && !_isNavigating) {
          _hasFittedToRoute = true;
          GoogleMapHelpers.fitPoints(
            _mapController,
            [for (final option in options) ...option.points, ...accuratePoints],
            padding: 80,
            singlePointZoom: 15.0,
          );
        }
      }
    }
    _isFetchingRoute = false;
  }

  Future<void> _selectRoute(int index) async {
    if (index == _selectedRouteIndex || index >= _routeOptions.length) return;
    final labelIcons = await _loadRouteLabelIcons(_routeOptions, index);
    if (!mounted) return;
    setState(() {
      _selectedRouteIndex = index;
      _accurateRoutePoints = _routeOptions[index].points;
      _routeLabelIcons = labelIcons;
    });
  }

  // "X min" bubbles shown on each route, highlighted for the selected one
  Future<Map<int, gm.BitmapDescriptor>> _loadRouteLabelIcons(
    List<RouteOption> options,
    int selectedIndex,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final icons = <int, gm.BitmapDescriptor>{};
    for (int i = 0; i < options.length; i++) {
      final isSelected = i == selectedIndex;
      icons[i] = await MapLabelIcons.load(
        text: l10n.routeMinutes(options[i].durationMinutes),
        background: isSelected ? AppColors.primaryColor : Colors.white,
        textColor: isSelected ? Colors.white : Colors.grey.shade800,
      );
    }
    return icons;
  }

  // Point on a route that is farthest from the other routes, so its label
  // sits where the routes split apart (like Google Maps)
  LatLng _routeLabelPosition(int index) {
    final points = _routeOptions[index].points;
    final others = [
      for (int i = 0; i < _routeOptions.length; i++)
        if (i != index) _routeOptions[i].points,
    ];
    if (others.isEmpty) return points[points.length ~/ 2];

    LatLng best = points[points.length ~/ 2];
    double bestDistance = -1;
    final step = math.max(1, points.length ~/ 40);
    for (int i = step; i < points.length - step; i += step) {
      final distance = others
          .map((other) => MapService.minDistanceToPolyline(points[i], other))
          .reduce(math.min);
      if (distance > bestDistance) {
        bestDistance = distance;
        best = points[i];
      }
    }
    return best;
  }

  void _startLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (!mounted) return;
      final locationData = _positionToLocationData(position);

      // A real fix replaces the delivery-address fallback: redraw right away
      if (_isUsingFallbackLocation) {
        _isUsingFallbackLocation = false;
        _isLoadingLocation = false;
        _lastRerouteTime = null;
        _hasFittedToRoute = false;
      }

      final oldLocation = _currentLocation;
      final newLatLng = LocationService.locationDataToLatLng(locationData);

      if (oldLocation != null && newLatLng != null) {
        final oldLatLng = LatLng(oldLocation.latitude!, oldLocation.longitude!);
        _animateRider(oldLatLng, newLatLng);
      } else if (newLatLng != null) {
        setState(() {
          _animatedRiderLatLng = newLatLng;
          _currentLocation = locationData;
        });
      }

      setState(() {
        _currentLocation = locationData;
      });

      if (_isNavigating) _onNavigationPosition(position);
      _maybeRefreshRouteOnMovement();
    });
  }

  // While navigating, keep the route the rider is already on when the
  // refreshed options come in; after leaving the route take the fastest.
  int _routeMatchingCurrent(List<RouteOption> options) {
    if (options.length < 2 || _accurateRoutePoints.length < 2) return 0;
    final rider = _getCurrentLocationLatLng();
    if (MapService.minDistanceToPolyline(rider, _accurateRoutePoints) > 50) {
      return 0;
    }
    int best = 0;
    double bestScore = double.infinity;
    for (int i = 0; i < options.length; i++) {
      final points = options[i].points;
      final step = math.max(1, points.length ~/ 20);
      double total = 0;
      int count = 0;
      for (int j = 0; j < points.length; j += step) {
        total += MapService.minDistanceToPolyline(
          points[j],
          _accurateRoutePoints,
        );
        count++;
      }
      final score = total / math.max(1, count);
      if (score < bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  Future<void> _retryRouteAndNavigate() async {
    setState(() => _isRetryingRoute = true);
    // Wait out a fetch already in flight before starting a new one
    while (_isFetchingRoute && mounted) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (_routeOptions.isEmpty) await _fetchAccurateRoute();
    if (!mounted) return;
    setState(() => _isRetryingRoute = false);

    if (_routeOptions.isEmpty) {
      ToastManager.show(
        context: context,
        message: 'Could not load route. Check your internet and try again.',
        type: ToastType.error,
      );
      return;
    }
    _startNavigation();
  }

  void _startNavigation() {
    if (_routeOptions.isEmpty) return;
    if (_isUsingFallbackLocation) {
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)!.waitingForGps,
        type: ToastType.info,
      );
      return;
    }

    final navigator = TurnByTurnNavigator(_routeOptions[_selectedRouteIndex]);
    final progress = navigator.update(_getCurrentLocationLatLng());
    final speed = _currentLocation?.speed;
    final heading = _currentLocation?.heading;
    setState(() {
      _navigator = navigator;
      _navProgress = progress;
      _isNavigating = true;
      _isFollowingRider = true;
      _speedMps = speed != null && speed > 0 ? speed : 0;
      _navBearing =
          heading != null && heading >= 0 && (speed ?? 0) > 1.5
              ? heading
              : _initialRouteBearing();
    });
    WakelockPlus.enable().catchError((_) {});
    _voice.speak(navigator.announcement(progress, isFirst: true) ?? '');
    _followRider();
  }

  // Direction of the first stretch of road, so the map faces the right way
  // before the rider starts moving
  double _initialRouteBearing() {
    final points = _routeOptions[_selectedRouteIndex].points;
    if (points.length < 2) return _riderRotation;
    final start = points.first;
    final ahead = points.firstWhere(
      (p) => MapService.calculateDistance(start, p) > 0.02,
      orElse: () => points[1],
    );
    return _calculateBearing(start, ahead);
  }

  void _stopNavigation({bool silenceVoice = true}) {
    if (silenceVoice) _voice.stop();
    WakelockPlus.disable().catchError((_) {});
    setState(() {
      _isNavigating = false;
      _navigator = null;
      _navProgress = null;
    });
    _showRouteOverview();
  }

  void _onNavigationPosition(geo.Position position) {
    final navigator = _navigator;
    if (navigator == null) return;

    _speedMps = position.speed > 0 ? position.speed : 0;
    // Heading is noise when standing still; keep the last good one
    if (position.speed > 1.5 && position.heading >= 0) {
      _navBearing = position.heading;
    }

    final progress = navigator.update(
      LatLng(position.latitude, position.longitude),
    );
    setState(() => _navProgress = progress);

    final text = navigator.announcement(progress, isFirst: false);
    if (text != null) _voice.speak(text);

    if (progress.arrived) {
      _stopNavigation(silenceVoice: false);
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)!.youHaveArrived,
        type: ToastType.success,
      );
      return;
    }

    if (_isFollowingRider) _followRider();
  }

  void _followRider() {
    _mapController?.animateCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: GoogleMapHelpers.toGm(_getCurrentLocationLatLng()),
          zoom: 17.5,
          tilt: 55,
          bearing: _navBearing,
        ),
      ),
    );
  }

  void _recenter() {
    setState(() => _isFollowingRider = true);
    _followRider();
  }

  // Flat, north-up view of the whole remaining route
  Future<void> _showRouteOverview() async {
    if (_isNavigating) setState(() => _isFollowingRider = false);
    final controller = _mapController;
    if (controller == null) return;
    final current = _getCurrentLocationLatLng();
    await controller.moveCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(target: GoogleMapHelpers.toGm(current), zoom: 15),
      ),
    );
    await GoogleMapHelpers.fitPoints(
      controller,
      [current, ..._accurateRoutePoints],
      padding: 80,
      singlePointZoom: 15.0,
    );
  }

  void _showSteps({required bool isDarkTheme}) {
    if (_routeOptions.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final route = _navigator?.route ?? _routeOptions[_selectedRouteIndex];
    final progress = _navProgress;
    final minutes =
        progress != null
            ? (progress.remainingSeconds / 60).ceil().clamp(1, 100000)
            : route.durationMinutes;
    final meters = progress?.remainingMeters ?? route.distanceMeters;
    showRouteStepsSheet(
      context,
      steps: route.steps,
      currentStepIndex: progress?.stepIndex ?? -1,
      summary:
          '${l10n.routeMinutes(minutes)} · ${TurnByTurnNavigator.displayDistance(meters)}',
      destination: widget.order.shippingAddress1 ?? '',
      isDarkTheme: isDarkTheme,
      onOpenInGoogleMaps: _openInGoogleMaps,
    );
  }

  Future<void> _callCustomer() async {
    final phone = (widget.order.shippingPhone ?? '').replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );
    if (phone.isEmpty) {
      ToastManager.show(
        context: context,
        message: AppLocalizations.of(context)!.customerPhoneUnavailable,
        type: ToastType.error,
      );
      return;
    }
    final code = (widget.order.shippingPhonecode ?? '').replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final number =
        phone.startsWith('+') || code.isEmpty ? phone : '+$code$phone';
    await launchUrl(Uri(scheme: 'tel', path: number));
  }

  void _animateRider(LatLng from, LatLng to) {
    if (from == to || !_isValidLatLng(from) || !_isValidLatLng(to)) return;

    // Calculate rotation
    final double bearing = _calculateBearing(from, to);

    final latTween = Tween<double>(begin: from.latitude, end: to.latitude);
    final lngTween = Tween<double>(begin: from.longitude, end: to.longitude);

    _animationController!.reset();
    final Animation<double> localAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.linear,
    );

    localAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _animatedRiderLatLng = LatLng(
            latTween.evaluate(localAnimation),
            lngTween.evaluate(localAnimation),
          );
          _riderRotation = bearing;
        });
      }
    });

    _animationController!.forward();
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180;
    final double lon1 = from.longitude * math.pi / 180;
    final double lat2 = to.latitude * math.pi / 180;
    final double lon2 = to.longitude * math.pi / 180;

    final double dLon = lon2 - lon1;

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final double radians = math.atan2(y, x);
    return (radians * 180 / math.pi + 360) % 360;
  }

  void _maybeRefreshRouteOnMovement() {
    if (_currentLocation == null || _isFetchingRoute) return;

    // Routes API requests are billed: refetch only when the rider leaves the
    // selected route, or once a minute to refresh traffic-aware times.
    final now = DateTime.now();
    final sinceLast =
        _lastRerouteTime == null ? null : now.difference(_lastRerouteTime!);
    if (sinceLast != null && sinceLast < const Duration(seconds: 10)) return;

    final current = _getCurrentLocationLatLng();
    final isOffRoute =
        _accurateRoutePoints.length < 2 ||
        MapService.minDistanceToPolyline(current, _accurateRoutePoints) > 50;
    final isTimeForRefresh =
        sinceLast == null || sinceLast >= const Duration(seconds: 60);
    if (!isOffRoute && !isTimeForRefresh) return;

    _fetchAccurateRoute();
  }

  List<LatLng> _generateRoute() {
    if (_currentLocation == null) return [];

    final List<LatLng> routePoints = [
      LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
    ];

    if (widget.order.deliveryRoute?.routeDetails != null &&
        widget.order.deliveryRoute!.routeDetails!.isNotEmpty) {
      // Add destination location (usually the last detail in delivery route)
      final destLocation = widget.order.deliveryRoute!.routeDetails!.last;

      if (destLocation.latitude != null && destLocation.longitude != null) {
        final destPoint = LatLng(
          destLocation.latitude!,
          destLocation.longitude!,
        );
        if (_isValidLatLng(destPoint)) {
          // In stage 0, we show the route to the destination
          if (_currentStage == 0) {
            routePoints.add(destPoint);
          }
        }
      }
    }

    return routePoints;
  }

  Set<gm.Polyline> _buildRoutePolylines() {
    final navRoute = _navigator?.route;
    if (_isNavigating && navRoute != null) {
      return {
        gm.Polyline(
          polylineId: const gm.PolylineId('nav_route'),
          points: GoogleMapHelpers.toGmList(navRoute.points),
          width: 9,
          color: AppColors.primaryColor,
          startCap: gm.Cap.roundCap,
          endCap: gm.Cap.roundCap,
          jointType: gm.JointType.round,
        ),
      };
    }

    if (_routeOptions.isNotEmpty && _currentStage == 0) {
      return {
        for (int i = 0; i < _routeOptions.length; i++)
          gm.Polyline(
            polylineId: gm.PolylineId('route_$i'),
            points: GoogleMapHelpers.toGmList(_routeOptions[i].points),
            width: i == _selectedRouteIndex ? 7 : 6,
            color:
                i == _selectedRouteIndex
                    ? AppColors.primaryColor
                    : AppColors.primaryColor.withValues(alpha: 0.35),
            zIndex: i == _selectedRouteIndex ? 2 : 1,
            startCap: gm.Cap.roundCap,
            endCap: gm.Cap.roundCap,
            jointType: gm.JointType.round,
            consumeTapEvents: true,
            onTap: () => _selectRoute(i),
          ),
      };
    }

    final routePoints =
        _accurateRoutePoints.isNotEmpty
            ? _accurateRoutePoints
            : _generateRoute();

    if (routePoints.length < 2) return {};

    return {
      gm.Polyline(
        polylineId: const gm.PolylineId('route'),
        points: GoogleMapHelpers.toGmList(routePoints),
        width: 5,
        color: AppColors.primaryColor,
        startCap: gm.Cap.roundCap,
        endCap: gm.Cap.roundCap,
        jointType: gm.JointType.round,
      ),
    };
  }

  LatLng _getDestinationLocation() {
    if (widget.order.deliveryRoute?.routeDetails != null &&
        widget.order.deliveryRoute!.routeDetails!.isNotEmpty) {
      final lastIndex = widget.order.deliveryRoute!.routeDetails!.length - 1;
      final destination = widget.order.deliveryRoute!.routeDetails![lastIndex];
      if (destination.latitude != null && destination.longitude != null) {
        return LatLng(destination.latitude!, destination.longitude!);
      }
    }

    final lat = double.tryParse(widget.order.shippingLatitude ?? '');
    final lng = double.tryParse(widget.order.shippingLongitude ?? '');
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }

    return _nagpurCenter;
  }

  // Remaining distance from current location to the customer. Uses the road
  // route when it has been fetched, otherwise the straight-line distance.
  double _calculateRemainingDistanceKm() {
    if (_currentLocation == null) return 0.0;

    if (_routeOptions.isNotEmpty) {
      return _routeOptions[_selectedRouteIndex].distanceKm;
    }

    if (_accurateRoutePoints.length >= 2) {
      double total = 0.0;
      for (int i = 1; i < _accurateRoutePoints.length; i++) {
        total += _haversineKm(
          _accurateRoutePoints[i - 1],
          _accurateRoutePoints[i],
        );
      }
      return total;
    }

    final currentPoint = _getCurrentLocationLatLng();
    final destination = _getDestinationLocation();
    if (!_isValidLatLng(currentPoint) || !_isValidLatLng(destination)) {
      return 0.0;
    }
    return _haversineKm(currentPoint, destination);
  }

  double _haversineKm(LatLng from, LatLng to) {
    const double earthRadius = 6371; // kilometers
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final deltaLat = (to.latitude - from.latitude) * pi / 180;
    final deltaLng = (to.longitude - from.longitude) * pi / 180;

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    if (a > 1.0 || a < 0.0) return 0.0; // Prevent NaN from sqrt
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  LatLng _getCurrentLocationLatLng() {
    if (_currentLocation != null &&
        _currentLocation!.latitude != null &&
        _currentLocation!.longitude != null &&
        !_currentLocation!.latitude!.isNaN &&
        !_currentLocation!.latitude!.isInfinite &&
        !_currentLocation!.longitude!.isNaN &&
        !_currentLocation!.longitude!.isInfinite) {
      return LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    }

    // Use shipping address coordinates as fallback
    if (widget.order.deliveryRoute?.routeDetails != null &&
        widget.order.deliveryRoute!.routeDetails!.isNotEmpty) {
      final lastIndex = widget.order.deliveryRoute!.routeDetails!.length - 1;
      final shippingAddress =
          widget.order.deliveryRoute!.routeDetails![lastIndex];

      if (shippingAddress.latitude != null &&
          shippingAddress.longitude != null &&
          !shippingAddress.latitude!.isNaN &&
          !shippingAddress.latitude!.isInfinite &&
          !shippingAddress.longitude!.isNaN &&
          !shippingAddress.longitude!.isInfinite) {
        return LatLng(shippingAddress.latitude!, shippingAddress.longitude!);
      }
    }

    // Secondary fallback to shipping coordinates from order properties
    final orderLat = double.tryParse(widget.order.shippingLatitude ?? '');
    final orderLng = double.tryParse(widget.order.shippingLongitude ?? '');
    if (orderLat != null &&
        orderLng != null &&
        !orderLat.isNaN &&
        !orderLat.isInfinite &&
        !orderLng.isNaN &&
        !orderLng.isInfinite) {
      return LatLng(orderLat, orderLng);
    }

    // Final fallback to the city centre
    return _nagpurCenter;
  }

  @override
  void dispose() {
    _voice.stop();
    if (_isNavigating) WakelockPlus.disable().catchError((_) {});
    _locationSubscription?.cancel();
    _animationController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _showArrivalConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.green),
              SizedBox(width: 8.w),
              CustomText(
                text: AppLocalizations.of(context)!.confirmArrival,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          content: CustomText(
            text: AppLocalizations.of(context)!.haveYouReachedAddress,
            fontSize: 14.sp,
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: CustomText(
                text: AppLocalizations.of(context)!.cancel,
                fontSize: 14.sp,
              ),
            ),
            CustomButton(
              textSize: 15.sp,
              text: AppLocalizations.of(context)!.yesImHere,
              onPressed: () {
                context.pop();
                setState(() {
                  _hasConfirmedArrival = true;
                  _hasReachedDestination =
                      true; // Set this to true to show "Arrival Confirmed"
                });

                // Mark ALL items as reached destination using the bloc from widget
                if (widget.order.items != null &&
                    widget.order.items!.isNotEmpty &&
                    widget.bloc != null) {
                  for (final item in widget.order.items!) {
                    if (item.id != null) {
                      widget.bloc!.add(
                        MarkItemReachedDestination(widget.order.id!, item.id!),
                      );
                    }
                  }
                } else {
                  //
                }

                // Show success message
                ToastManager.show(
                  context: context,
                  message: AppLocalizations.of(context)!.arrivalNextStepHint,
                  type: ToastType.success,
                );
              },
              backgroundColor: AppColors.primaryColor,
              textColor: Colors.white,
            ),
          ],
        );
      },
    );
  }

  void _openOrderDetails() {
    context.push(
      AppRoutes.orderDetails,
      extra: {
        'orderId': widget.order.id!,
        'from': true,
        'sourceTab':
            1, // 1 = My Orders tab (since this is from accepted orders)
        'arrivalConfirmed': _hasReachedDestination || _hasConfirmedArrival,
      },
    );
  }

  Set<gm.Marker> _buildMarkers() {
    // Convert animated location back to LocationData format for the service
    LocationData? animatedLocation;
    if (_animatedRiderLatLng != null) {
      animatedLocation = LocationData.fromMap({
        'latitude': _animatedRiderLatLng!.latitude,
        'longitude': _animatedRiderLatLng!.longitude,
      });
    }

    final markers = MapService.buildDeliveryMarkers(
      animatedLocation ?? _currentLocation,
      widget.order.deliveryRoute?.routeDetails,
      rotation: _riderRotation,
    );

    if (_currentStage == 0 && !_isNavigating) {
      for (int i = 0; i < _routeOptions.length; i++) {
        final icon = _routeLabelIcons[i];
        if (icon == null) continue;
        markers.add(
          gm.Marker(
            markerId: gm.MarkerId('route_label_$i'),
            position: GoogleMapHelpers.toGm(_routeLabelPosition(i)),
            icon: icon,
            anchor: const Offset(0.5, 1.0),
            zIndexInt: i == _selectedRouteIndex ? 4 : 3,
            onTap: () => _selectRoute(i),
          ),
        );
      }
    }

    return markers;
  }

  // "3 min (1.4 km)" with "Fastest route" / "+2 min slower" below
  Widget _buildDriveSummary() {
    final l10n = AppLocalizations.of(context)!;
    final selected = _routeOptions[_selectedRouteIndex];
    final extraMinutes =
        selected.durationMinutes - _routeOptions.first.durationMinutes;
    final isFastest = _selectedRouteIndex == 0 || extraMinutes <= 0;
    final subtitle =
        isFastest ? l10n.fastestRoute : l10n.routeMinutesSlower(extraMinutes);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car,
                color: AppColors.primaryColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              CustomText(
                text:
                    '${l10n.routeMinutes(selected.durationMinutes)} (${selected.distanceKm.toStringAsFixed(1)} ${l10n.km})',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          CustomText(
            text:
                _routeOptions.length > 1
                    ? '$subtitle · ${l10n.tapRouteToSwitch}'
                    : subtitle,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: isFastest ? Colors.green[700] : Colors.grey[600],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Hands the trip to the Google Maps app: current location to the
  // customer's shipping address
  Future<void> _openInGoogleMaps() async {
    try {
      final currentLocation = _getCurrentLocationLatLng();
      final currentLat = currentLocation.latitude.toString();
      final currentLng = currentLocation.longitude.toString();

      final destination = _getDestinationLocation();
      final destinationAddress =
          '${destination.latitude},${destination.longitude}';

      final googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1'
          '&origin=${Uri.encodeComponent('$currentLat,$currentLng')}'
          '&destination=${Uri.encodeComponent(destinationAddress)}'
          '&travelmode=driving';

      await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (!mounted) return;
      ToastManager.show(
        context: context,
        message: 'Could not open navigation: $e',
        type: ToastType.error,
      );
    }
  }

  // Start / Steps / Call row on the route preview card
  Widget _buildRouteActions(bool isDarkTheme) {
    final l10n = AppLocalizations.of(context)!;
    final outlinedStyle = OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryColor,
      side: const BorderSide(color: AppColors.primaryColor),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
    );
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: _startNavigation,
            icon: const Icon(Icons.navigation, color: Colors.white),
            label: Text(
              l10n.startNavigation,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () => _showSteps(isDarkTheme: isDarkTheme),
            icon: const Icon(Icons.format_list_bulleted),
            label: Text(
              l10n.routeSteps,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            style: outlinedStyle,
          ),
        ),
        SizedBox(width: 8.w),
        Tooltip(
          message: l10n.call,
          child: OutlinedButton(
            onPressed: _callCustomer,
            style: outlinedStyle.copyWith(
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
              ),
              minimumSize: const WidgetStatePropertyAll(Size.zero),
            ),
            child: const Icon(Icons.phone),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildNavigationOverlay(bool isDarkTheme) {
    final progress = _navProgress;
    if (progress == null) return const [];
    final l10n = AppLocalizations.of(context)!;
    return [
      Positioned(
        top: 8.h,
        left: 8.w,
        right: 8.w,
        child: NavigationBanner(progress: progress),
      ),
      Positioned(
        top: 150.h,
        right: 12.w,
        child: Column(
          children: [
            NavigationMapButton(
              icon: _voice.muted ? Icons.volume_off : Icons.volume_up,
              tooltip: _voice.muted ? l10n.unmuteVoice : l10n.muteVoice,
              onPressed: () {
                setState(() => _voice.muted = !_voice.muted);
                if (_voice.muted) _voice.stop();
              },
            ),
            SizedBox(height: 10.h),
            NavigationMapButton(
              icon: Icons.alt_route,
              tooltip: l10n.routeOverview,
              onPressed: _showRouteOverview,
            ),
          ],
        ),
      ),
      Positioned(
        left: 12.w,
        bottom: 96.h,
        child: SpeedBubble(speedMetersPerSecond: _speedMps),
      ),
      if (!_isFollowingRider)
        Positioned(
          right: 12.w,
          bottom: 100.h,
          child: RecenterButton(onPressed: _recenter),
        ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: NavigationBottomBar(
          progress: progress,
          isDarkTheme: isDarkTheme,
          onExit: _stopNavigation,
          onShowSteps: () => _showSteps(isDarkTheme: isDarkTheme),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isDarkTheme = themeState.currentTheme == 'dark';
        final showRouteActions =
            _routeOptions.isNotEmpty &&
            _currentStage == 0 &&
            !_hasReachedDestination;

        return PopScope(
          // Back exits navigation first, like Google Maps
          canPop: !_isNavigating,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _isNavigating) _stopNavigation();
          },
          child: CustomScaffold(
            appBar:
                _isNavigating
                    ? null
                    : CustomAppBarWithoutNavbar(
                      title: AppLocalizations.of(context)!.deliveryRoute,
                      showRefreshButton: false,
                      showThemeToggle: false,
                    ),
            body: Stack(
              children: [
                Listener(
                  // Any touch on the map while navigating stops following
                  onPointerDown: (_) {
                    if (_isNavigating && _isFollowingRider) {
                      setState(() => _isFollowingRider = false);
                    }
                  },
                  child: gm.GoogleMap(
                    initialCameraPosition: gm.CameraPosition(
                      target: GoogleMapHelpers.toGm(
                        (() {
                          // Before GPS arrives, open on the customer rather
                          // than an arbitrary city
                          final center =
                              _currentLocation != null
                                  ? _getCurrentLocationLatLng()
                                  : _getDestinationLocation();
                          return _isValidLatLng(center)
                              ? center
                              : _nagpurCenter;
                        })(),
                      ),
                      zoom: 13.0,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // The map needs a moment to lay out before bounds can be applied
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted && _currentLocation != null) {
                          _fitMapToAllPoints();
                        }
                      });
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: !_isNavigating,
                    trafficEnabled: _isNavigating,
                    // While navigating, the big top padding puts the rider in
                    // the lower part of the screen so more road ahead shows
                    padding:
                        _isNavigating
                            ? EdgeInsets.only(top: 260.h, bottom: 80.h)
                            : EdgeInsets.only(
                              top: 60.h,
                              bottom: showRouteActions ? 290.h : 230.h,
                            ),
                    polylines:
                        _currentLocation != null
                            ? _buildRoutePolylines()
                            : const {},
                    markers:
                        _currentLocation != null ? _buildMarkers() : const {},
                  ),
                ),
                if (_isLoadingLocation)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: 16.h),
                          CustomText(
                            text: AppLocalizations.of(context)!.loadingMap,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isNavigating)
                  ..._buildNavigationOverlay(isDarkTheme)
                else ...[
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _routeOptions.isNotEmpty
                                ? Icons.directions_car
                                : Icons.straighten,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          CustomText(
                            text:
                                _routeOptions.isNotEmpty
                                    ? '${AppLocalizations.of(context)!.routeMinutes(_routeOptions[_selectedRouteIndex].durationMinutes)} · ${_calculateRemainingDistanceKm().toStringAsFixed(1)} km'
                                    : '${_calculateRemainingDistanceKm().toStringAsFixed(1)} km',
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                        minHeight: 150.h,
                      ),
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color:
                            isDarkTheme
                                ? AppColors.cardDarkColor
                                : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15.r,
                            offset: Offset(0, 5.h),
                            spreadRadius: 2.r,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 32.h,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(4.w),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(
                                            4.r,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.store,
                                          color: Colors.white,
                                          size: 14.sp,
                                        ),
                                      ),
                                      SizedBox(width: 7.w),
                                      CustomText(
                                        text:
                                            AppLocalizations.of(
                                              context,
                                            )!.deliveryRoute,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.oppColorChange,
                                      ),
                                    ],
                                  ),

                                  if ((!_hasReachedDestination ||
                                          !_hasConfirmedArrival) &&
                                      _routeOptions.isEmpty)
                                    CustomText(
                                      text:
                                          '${_calculateRemainingDistanceKm().toStringAsFixed(1)} km',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  if (_hasReachedDestination ||
                                      _hasConfirmedArrival)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 14.sp,
                                          ),
                                          SizedBox(width: 4.w),
                                          CustomText(
                                            text:
                                                AppLocalizations.of(
                                                  context,
                                                )!.arrivalConfirmed,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Drive time for the selected route
                            SizedBox(height: 12.h),
                            if (_routeOptions.isNotEmpty &&
                                _currentStage == 0) ...[
                              _buildDriveSummary(),
                              SizedBox(height: 4.h),
                            ],

                            // Shipping Address Section
                            if (widget.order.shippingAddress1 != null)
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: CustomText(
                                        text: widget.order.shippingAddress1!,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(height: 8.h),
                            if (_hasReachedDestination) ...[
                              CustomText(
                                text:
                                    AppLocalizations.of(
                                      context,
                                    )!.arrivalNextStepHint,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                              SizedBox(height: 8.h),
                            ],

                            if (showRouteActions) ...[
                              _buildRouteActions(isDarkTheme),
                              SizedBox(height: 8.h),
                            ],

                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                textSize: 15.sp,
                                text:
                                    _hasReachedDestination
                                        ? AppLocalizations.of(
                                          context,
                                        )!.continueToDelivery
                                        : AppLocalizations.of(
                                          context,
                                        )!.confirmArrival,
                                onPressed:
                                    _hasReachedDestination
                                        ? _openOrderDetails
                                        : _showArrivalConfirmationDialog,
                                icon: Icon(
                                  _hasReachedDestination
                                      ? Icons.arrow_forward
                                      : Icons.location_on,
                                  color:
                                      showRouteActions
                                          ? AppColors.primaryColor
                                          : Colors.white,
                                ),
                                // With Start shown, arrival is the secondary action
                                backgroundColor:
                                    _hasReachedDestination
                                        ? Colors.green
                                        : showRouteActions
                                        ? AppColors.primaryColor.withValues(
                                          alpha: 0.1,
                                        )
                                        : AppColors.primaryColor,
                                textColor:
                                    showRouteActions
                                        ? AppColors.primaryColor
                                        : Colors.white,
                                borderRadius: 8.r,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                textStyle: TextStyle(
                                  color:
                                      showRouteActions
                                          ? AppColors.primaryColor
                                          : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Route not loaded yet: the button retries it and then
                  // starts in-app navigation (no hand-off to Google Maps)
                  if (_routeOptions.isEmpty)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: FloatingActionButton(
                        onPressed:
                            _isRetryingRoute ? null : _retryRouteAndNavigate,
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        child:
                            _isRetryingRoute
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                : const Icon(Icons.navigation),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
