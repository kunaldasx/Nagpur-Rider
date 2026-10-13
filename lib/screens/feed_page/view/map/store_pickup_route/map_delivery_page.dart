// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/map/google_map_helpers.dart';
import '../../../../../utils/widgets/custom_appbar_without_navbar.dart';
import '../../../model/available_orders.dart';
import 'widgets/index.dart';
import 'dart:math' as math;

class MapDeliveryPage extends StatefulWidget {
  final Orders order;
  final String? currentLat;
  final String? currentLng;

  const MapDeliveryPage({
    super.key,
    required this.order,
    this.currentLat,
    this.currentLng,
  });

  @override
  State<MapDeliveryPage> createState() => _MapDeliveryPageState();
}

class _MapDeliveryPageState extends State<MapDeliveryPage>
    with TickerProviderStateMixin {
  gm.GoogleMapController? _mapController;
  LocationData? _currentLocation;
  bool _isLoadingLocation = true;
  bool _hasReachedDestination = false;
  // Stage indicator: 0 = heading to stores, 1 = arrived at stores
  int get _currentStage => _hasReachedDestination ? 1 : 0;
  double _distanceToStores = 0.0;
  List<RouteDetails> _filteredStores = [];
  List<LatLng> _accurateRoutePoints = [];
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isFetchingRoute = false;
  DateTime? _lastRerouteTime;
  double _riderRotation = 0;
  LatLng? _animatedRiderLatLng;
  AnimationController? _animationController;

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
    _initializeData();
    _getCurrentLocation();
  }

  void _initializeData() {
    // Get filtered stores
    _filteredStores = MapService.getFilteredStores(
      widget.order.deliveryRoute?.routeDetails,
    );

    if (widget.order.deliveryRoute != null) {
      if (widget.order.deliveryRoute!.routeDetails != null) {
        for (
          int i = 0;
          i < widget.order.deliveryRoute!.routeDetails!.length;
          i++
        ) {
          //
        }
      }
    }

    // If we have route details, try to calculate distance (will be updated when location is available)
    if (widget.order.deliveryRoute?.routeDetails != null &&
        widget.order.deliveryRoute!.routeDetails!.isNotEmpty) {}
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await LocationService.getCurrentLocation();

      if (locationData != null) {
        setState(() {
          _currentLocation = locationData;
          _isLoadingLocation = false;
        });

        // Calculate distance to stores
        _calculateDistanceToStores();

        // Fit map to show all points
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitMapToAllPoints();
          _fetchAccurateRoute();
          _startLocationUpdates();
        });
      } else {
        _setFallbackLocation();
      }
    } catch (e) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    setState(() {
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

      _currentLocation = LocationService.setFallbackLocation(
        fallbackLat,
        fallbackLng,
      );
      _isLoadingLocation = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToAllPoints();
      _calculateDistanceToStores(); // Calculate distance after setting fallback location
    });
  }

  void _calculateDistanceToStores() {
    if (_currentLocation != null) {
      _distanceToStores = MapService.calculateDistanceToStores(
        _currentLocation,
        widget.order.deliveryRoute?.routeDetails,
      );

      // Force UI update
      setState(() {});
    } else {}
  }

  bool _isValidLatLng(LatLng point) {
    return !point.latitude.isNaN &&
        !point.latitude.isInfinite &&
        !point.longitude.isNaN &&
        !point.longitude.isInfinite;
  }

  void _fitMapToAllPoints() {
    if (_currentLocation == null) return;

    try {
      final List<LatLng> allPoints = [];

      // Add current location
      final currentLatLng = LocationService.locationDataToLatLng(_currentLocation);
      if (currentLatLng != null && _isValidLatLng(currentLatLng)) {
        allPoints.add(currentLatLng);
      }

      // Add filtered store locations
      for (int i = 0; i < _filteredStores.length; i++) {
        final store = _filteredStores[i];
        if (store.latitude != null && store.longitude != null) {
          final storePoint = LatLng(store.latitude!, store.longitude!);
          if (_isValidLatLng(storePoint)) {
            allPoints.add(storePoint);
          }
        }
      }

      // Add destination if not already present
      final destLatLng = _getDestinationLocation();
      if (_isValidLatLng(destLatLng)) {
        allPoints.add(destLatLng);
      }

      GoogleMapHelpers.fitPoints(
        _mapController,
        allPoints,
        padding: 50.w,
        singlePointZoom: 15.0,
      );
    } catch (e) {
      //
    }
  }

  Future<void> _fetchAccurateRoute() async {
    if (_currentLocation == null || _isFetchingRoute) return;

    _isFetchingRoute = true;
    _lastRerouteTime = DateTime.now();

    try {
      final routePoints = MapService.generatePickupRoutePoints(
        _currentLocation,
        widget.order.deliveryRoute?.routeDetails,
      );

      if (routePoints.length >= 2) {
        final accuratePoints = await MapService.fetchAccurateRoute(routePoints);
        if (mounted) {
          setState(() {
            _accurateRoutePoints = accuratePoints;
          });
        }
      }
    } finally {
      _isFetchingRoute = false;
    }
  }

  void _startLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = LocationService.getLocationStream().listen((
      locationData,
    ) {
      if (!mounted) return;

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
        if (newLatLng != null && _accurateRoutePoints.isNotEmpty) {
          final firstPoint = _accurateRoutePoints.first;
          if (MapService.calculateDistance(firstPoint, newLatLng) > 0.01) {
            _accurateRoutePoints = [newLatLng, ..._accurateRoutePoints.skip(1)];
          }
        }
      });

      // Update distance if location moved significantly
      if (oldLocation == null ||
          MapService.calculateDistance(
                LatLng(oldLocation.latitude!, oldLocation.longitude!),
                LatLng(locationData.latitude!, locationData.longitude!),
              ) >
              0.005) { // Reduced threshold for better responsiveness
        _calculateDistanceToStores();
      }

      _maybeRefreshRouteOnMovement();
      // Check for rerouting
      _checkReroute(locationData);
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

  void _checkReroute(LocationData currentLocation) {
    if (_isFetchingRoute || _accurateRoutePoints.isEmpty) return;

    // Throttle reroutes: wait at least 10 seconds between reroutes
    if (_lastRerouteTime != null &&
        DateTime.now().difference(_lastRerouteTime!) <
            const Duration(seconds: 10)) {
      return;
    }

    final currentLatLng = LatLng(
      currentLocation.latitude!,
      currentLocation.longitude!,
    );

    // If the user is more than 40 meters off the route
    if (MapService.isPointOffRoute(
      currentLatLng,
      _accurateRoutePoints,
      thresholdMeters: 40.0,
    )) {
      _fetchAccurateRoute();
    }
  }

  void _maybeRefreshRouteOnMovement() {
    if (_currentLocation == null || _isFetchingRoute) return;

    final now = DateTime.now();
    if (_lastRerouteTime != null &&
        now.difference(_lastRerouteTime!) < const Duration(seconds: 6)) {
      return;
    }

    _fetchAccurateRoute();
  }

  List<LatLng> _generateRoute() {
    if (_currentLocation == null) return [];

    final List<LatLng> routePoints = [
      LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
    ];

    if (widget.order.deliveryRoute?.routeDetails != null &&
        widget.order.deliveryRoute!.routeDetails!.isNotEmpty) {
      // Add store locations (filtered stores)
      for (final store in _filteredStores) {
        if (store.latitude != null && store.longitude != null) {
          final storePoint = LatLng(store.latitude!, store.longitude!);
          if (_isValidLatLng(storePoint)) {
            routePoints.add(storePoint);
          }
        }
      }

      // If we've reached stores (stage 1), we might show route to destination
      if (_currentStage >= 1) {
        final destLatLng = _getDestinationLocation();
        if (_isValidLatLng(destLatLng)) {
          routePoints.add(destLatLng);
        }
      }
    }

    return routePoints;
  }

  LatLng _getDestinationLocation() {
    return LocationService.getDestinationLocation(
      widget.order.deliveryRoute?.routeDetails,
    );
  }

  Set<gm.Polyline> _buildRoutePolylines() {
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
        color: const Color(0xFF059669),
        startCap: gm.Cap.roundCap,
        endCap: gm.Cap.roundCap,
        jointType: gm.JointType.round,
      ),
    };
  }

  Set<gm.Marker> _buildAllMarkers() {
    // Convert animated location back to LocationData format for the service
    LocationData? animatedLocation;
    if (_animatedRiderLatLng != null) {
      animatedLocation = LocationData.fromMap({
        'latitude': _animatedRiderLatLng!.latitude,
        'longitude': _animatedRiderLatLng!.longitude,
      });
    }

    return MapService.buildPickupMarkers(
      animatedLocation ?? _currentLocation,
      widget.order.deliveryRoute?.routeDetails,
      rotation: _riderRotation,
    );
  }

  void _onNavigationPressed() {
    if (_currentLocation == null) {
      return;
    }

    final currentLatLng = LocationService.locationDataToLatLng(
      _currentLocation,
    );
    if (currentLatLng != null) {
      // Use filtered stores for navigation (excludes shipping address)
      final storesForNavigation = _filteredStores;

      for (int i = 0; i < storesForNavigation.length; i++) {}

      NavigationService.openGoogleMapsToStores(
        currentLatLng,
        storesForNavigation,
      );
    } else {}
  }

  void _onMapCreated(gm.GoogleMapController controller) {
    _mapController = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToAllPoints();
      _calculateDistanceToStores(); // Calculate distance when map is ready
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.pop(true);
        return false;
      },
      child: Scaffold(
        appBar: CustomAppBarWithoutNavbar(
          title:
              _hasReachedDestination
                  ? AppLocalizations.of(context)!.deliveryRoute
                  : AppLocalizations.of(context)!.storePickupRoute,
          showRefreshButton: false,
          showThemeToggle: false,
        ),
        body: Stack(
          children: [
            // Map
            MapViewWidget(
              initialCenter:
                  (() {
                    final center = _getDestinationLocation();
                    return _isValidLatLng(center)
                        ? center
                        : const LatLng(23.2488453, 69.6696795);
                  })(),
              polylines: _buildRoutePolylines(),
              markers: _buildAllMarkers(),
              onMapCreated: _onMapCreated,
              showMapContent: _currentLocation != null,
            ),

            // Loading overlay
            if (_isLoadingLocation) const LoadingOverlayWidget(),

            // Distance Indicator
            Positioned(
              top: 20.h,
              left: 20.w,
              child: DistanceIndicatorWidget(distance: _distanceToStores),
            ),

            // Navigation Button
            Positioned(
              top: 20.h,
              right: 20.w,
              child: NavigationButtonWidget(onPressed: _onNavigationPressed),
            ),

            // Bottom Card
            BottomCardWidget(
              order: widget.order,
              hasReachedDestination: _hasReachedDestination,
              filteredStores: _filteredStores,
              shouldShowNumbers: _filteredStores.length > 1,
              distanceToStores:
                  _distanceToStores, // Pass the calculated distance
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _animationController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
