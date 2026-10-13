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
  StreamSubscription<LocationData>? _locationSubscription;
  double _riderRotation = 0;
  LatLng? _animatedRiderLatLng;
  AnimationController? _animationController;
  DateTime? _lastRerouteTime;
  bool _isFetchingRoute = false;

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

      setState(() {
        _currentLocation = locationData;
        _isLoadingLocation = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToAllPoints();
        _fetchAccurateRoute();
      });
    } catch (e) {
      _setFallbackLocation();
    }
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
      final accuratePoints = await MapService.fetchAccurateRoute(routePoints);
      if (mounted) {
        setState(() {
          _accurateRoutePoints = accuratePoints;
        });
      }
    }
    _isFetchingRoute = false;
  }

  void _startLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = Location.instance.onLocationChanged.listen((
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

    final now = DateTime.now();
    if (_lastRerouteTime != null &&
        now.difference(_lastRerouteTime!) < const Duration(seconds: 10)) {
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
      // Add destination location (usually the last detail in delivery route)
      final destLocation = widget.order.deliveryRoute!.routeDetails!.last;

      if (destLocation.latitude != null &&
          destLocation.longitude != null) {
        final destPoint = LatLng(destLocation.latitude!, destLocation.longitude!);
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

  // Calculate distance from current location to stores (excluding shipping address)
  double _calculateDistanceToStores() {
    if (_currentLocation == null) {
      return 0.0;
    }

    double totalDistanceToStores = 0.0;

    if (widget.order.deliveryRoute?.routeDetails != null) {
      final routeDetails = widget.order.deliveryRoute!.routeDetails!;

      // Exclude the last index (shipping address) - only include stores
      for (int i = 0; i < routeDetails.length - 1; i++) {
        final store = routeDetails[i];

        if (store.latitude != null && store.longitude != null) {
          final storePoint = LatLng(store.latitude!, store.longitude!);
          final currentPoint = _getCurrentLocationLatLng();

          if (_isValidLatLng(currentPoint) && _isValidLatLng(storePoint)) {
            const double earthRadius = 6371; // kilometers
            final lat1 = currentPoint.latitude * pi / 180;
            final lat2 = storePoint.latitude * pi / 180;
            final deltaLat =
                (storePoint.latitude - currentPoint.latitude) * pi / 180;
            final deltaLng =
                (storePoint.longitude - currentPoint.longitude) * pi / 180;

            final a =
                math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
                math.cos(lat1) *
                    math.cos(lat2) *
                    math.sin(deltaLng / 2) *
                    math.sin(deltaLng / 2);
            if (a > 1.0 || a < 0.0) continue; // Prevent NaN from sqrt/acos
            final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

            final distanceToStore = earthRadius * c;
            totalDistanceToStores += distanceToStore;
          }
        }
      }
    }

    return totalDistanceToStores;
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
                  message: 'Arrival confirmed! You can now view order details.',
                  type: ToastType.success,
                );

                // Automatically navigate to order details page after 3 seconds
                Future.delayed(const Duration(seconds: 3), () {
                  if (!context.mounted) return;
                  if (mounted) {
                    context.pushNamed(
                      'orderDetails',
                      extra: {
                        'orderId': widget.order.id,
                        'from':
                            false, // Using false instead of string as expected by the route
                      },
                    );
                  }
                });
              },
              backgroundColor: AppColors.primaryColor,
              textColor: Colors.white,
            ),
          ],
        );
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

    return MapService.buildDeliveryMarkers(
      animatedLocation ?? _currentLocation,
      widget.order.deliveryRoute?.routeDetails,
      rotation: _riderRotation,
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
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_currentLocation != null) _fitMapToAllPoints();
                  });
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                polylines:
                    _currentLocation != null
                        ? {
                          gm.Polyline(
                            polylineId: const gm.PolylineId('route'),
                            points: GoogleMapHelpers.toGmList(_generateRoute()),
                            width: 3.sp.round(),
                            color: AppColors.primaryColor,
                          ),
                        }
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
                        Icons.straighten,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      CustomText(
                        text:
                            '${_calculateDistanceToStores().toStringAsFixed(1)} km',
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

                            if (!_hasReachedDestination ||
                                !_hasConfirmedArrival)
                              CustomText(
                                text:
                                    '${_calculateDistanceToStores().toStringAsFixed(1)} km',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            if (_hasReachedDestination ||
                                _hasConfirmedArrival) ...[
                              SizedBox(
                                width: 100.w,
                                height: 24.h,
                                child: CustomButton(
                                  text:
                                      AppLocalizations.of(context)!.viewDetails,
                                  // width: 80.w,
                                  textSize: 10.sp,
                                  height: 24.h,

                                  borderRadius: 12.r,
                                  backgroundColor: AppColors.primaryColor,
                                  textColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onPressed: () {
                                    context.push(
                                      AppRoutes.orderDetails,
                                      extra: {
                                        'orderId': widget.order.id!,
                                        'from': true,
                                        'sourceTab':
                                            1, // 1 = My Orders tab (since this is from accepted orders)
                                        'arrivalConfirmed':
                                            _hasReachedDestination ||
                                            _hasConfirmedArrival, // Pass arrival status
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Shipping Address Section
                      SizedBox(height: 12.h),
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

                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          textSize: 15.sp,
                          text:
                              _hasReachedDestination
                                  ? AppLocalizations.of(
                                    context,
                                  )!.arrivalConfirmed
                                  : AppLocalizations.of(
                                    context,
                                  )!.confirmArrival,
                          onPressed:
                              _hasReachedDestination
                                  ? null
                                  : _showArrivalConfirmationDialog,
                          icon: Icon(
                            _hasReachedDestination
                                ? Icons.check_circle
                                : Icons.location_on,
                            color:
                                _hasReachedDestination
                                    ? Colors.green
                                    : Colors.white,
                          ),
                          backgroundColor:
                              _hasReachedDestination
                                  ? Colors.grey.shade200
                                  : AppColors.primaryColor,
                          textColor:
                              _hasReachedDestination
                                  ? Colors.green
                                  : Colors.white,
                          borderRadius: 8.r,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          textStyle: TextStyle(
                            color:
                                _hasReachedDestination
                                    ? Colors.green
                                    : Colors.white,
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
