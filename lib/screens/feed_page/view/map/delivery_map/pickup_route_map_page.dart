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
  bool _isUsingFallbackLocation = false;

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
      double fallbackLat = 23.2488453; // Default Bhuj coordinates
      double fallbackLng = 69.6696795;

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
          _selectedRouteIndex < options.length ? _selectedRouteIndex : 0;
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
        // Zoom to the road route the first time it arrives
        if (!_hasFittedToRoute && _mapController != null) {
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

      _maybeRefreshRouteOnMovement();
    });
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

    return const LatLng(23.2488453, 69.6696795);
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

    // Final fallback to default Bhuj coordinates
    return const LatLng(23.2488453, 69.6696795);
  }

  @override
  void dispose() {
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

    if (_currentStage == 0) {
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

  @override
  Widget build(BuildContext context) {
    // if (widget.order.items != null) {
    //   final reachedDestinationItems =
    //       widget.order.items!
    //           .where((item) => item.reachedDestination == true)
    //           .length;
    //
    //   // Check if View Details button should be shown
    //   final shouldShowViewDetails =
    //       _hasReachedDestination || _hasConfirmedArrival;
    // }

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isDarkTheme = themeState.currentTheme == 'dark';

        if (widget.order.deliveryRoute?.routeDetails != null) {
          for (
            int i = 0;
            i < widget.order.deliveryRoute!.routeDetails!.length;
            i++
          ) {
            // final store = widget.order.deliveryRoute!.routeDetails![i];
          }
        }

        return CustomScaffold(
          appBar: CustomAppBarWithoutNavbar(
            title: AppLocalizations.of(context)!.deliveryRoute,

            showRefreshButton: false,
            showThemeToggle: false,
          ),
          body: Stack(
            children: [
              gm.GoogleMap(
                initialCameraPosition: gm.CameraPosition(
                  target: GoogleMapHelpers.toGm(
                    (() {
                      final center =
                          _currentLocation != null
                              ? _getCurrentLocationLatLng()
                              : const LatLng(23.2530, 69.6693);
                      return _isValidLatLng(center)
                          ? center
                          : const LatLng(23.2530, 69.6693);
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
                // Keep the route clear of the top chip and the bottom card
                padding: EdgeInsets.only(top: 60.h, bottom: 230.h),
                polylines:
                    _currentLocation != null
                        ? _buildRoutePolylines()
                        : const {},
                markers: _currentLocation != null ? _buildMarkers() : const {},
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
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                    minHeight: 150.h,
                  ),
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: isDarkTheme ? AppColors.cardDarkColor : Colors.white,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 32.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4.r),
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
                            if (_hasReachedDestination || _hasConfirmedArrival)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12.r),
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
                      if (_routeOptions.isNotEmpty && _currentStage == 0) ...[
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
                              AppLocalizations.of(context)!.arrivalNextStepHint,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
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
                            color: Colors.white,
                          ),
                          backgroundColor:
                              _hasReachedDestination
                                  ? Colors.green
                                  : AppColors.primaryColor,
                          textColor: Colors.white,
                          borderRadius: 8.r,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () async {
                    try {
                      final currentLocation = _getCurrentLocationLatLng();
                      final currentLat = currentLocation.latitude.toString();
                      final currentLng = currentLocation.longitude.toString();

                      // String destinationLat = '0', destinationLng = '0';

                      // Use shipping address coordinates for navigation (final destination)
                      if (widget.order.shippingLatitude != null &&
                          widget.order.shippingLongitude != null) {
                        // destinationLat = widget.order.shippingLatitude!;
                        // destinationLng = widget.order.shippingLongitude!;
                      } else if (widget.order.deliveryRoute?.routeDetails !=
                              null &&
                          widget
                              .order
                              .deliveryRoute!
                              .routeDetails!
                              .isNotEmpty) {
                        // Fallback to last item in route_details (shipping address)
                        final lastIndex =
                            widget.order.deliveryRoute!.routeDetails!.length -
                            1;
                        final shippingAddress =
                            widget
                                .order
                                .deliveryRoute!
                                .routeDetails![lastIndex];
                        if (shippingAddress.latitude != null &&
                            shippingAddress.longitude != null) {
                          // destinationLat = shippingAddress.latitude!.toString();
                          // destinationLng =
                          //     shippingAddress.longitude!.toString();
                        }
                      }

                      // For PickupRouteMapPage: Only navigate to shipping address (no store addresses)
                      String destinationAddress =
                          'Bhuj, Gujarat, India'; // Default fallback

                      // Use shipping address directly (this is a pickup route to seller)
                      if (widget.order.shippingAddress1 != null) {
                        destinationAddress = widget.order.shippingAddress1!;
                        if (widget.order.shippingAddress2 != null) {
                          destinationAddress +=
                              ', ${widget.order.shippingAddress2}';
                        }
                      } else if (widget.order.deliveryRoute?.routeDetails !=
                              null &&
                          widget
                              .order
                              .deliveryRoute!
                              .routeDetails!
                              .isNotEmpty) {
                        // Fallback to last item in route_details (shipping address)
                        final lastIndex =
                            widget.order.deliveryRoute!.routeDetails!.length -
                            1;
                        final shippingAddress =
                            widget
                                .order
                                .deliveryRoute!
                                .routeDetails![lastIndex];
                        if (shippingAddress.address != null &&
                            shippingAddress.address!.isNotEmpty) {
                          destinationAddress = shippingAddress.address!;
                        }
                      }

                      // Build Google Maps URL: Current location to shipping address only
                      final googleMapsUrl =
                          'https://www.google.com/maps/dir/?api=1'
                          '&origin=${Uri.encodeComponent('$currentLat,$currentLng')}'
                          '&destination=${Uri.encodeComponent(destinationAddress)}'
                          '&travelmode=driving';

                      final url = Uri.parse(googleMapsUrl);
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ToastManager.show(
                        context: context,
                        message: 'Could not open navigation: $e',
                        type: ToastType.error,
                      );
                    }
                  },
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.navigation),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
