// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:nagpur_rider/utils/widgets/custom_scaffold.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../config/colors.dart';
import '../../../../../utils/map/google_map_helpers.dart';
import '../../../../../config/theme_bloc.dart';
import '../../../model/return_orders_list_model.dart';
import '../../../../../utils/widgets/custom_button.dart';
import '../../../../../utils/widgets/custom_text.dart';
import '../../../../../utils/widgets/custom_appbar_without_navbar.dart';
import 'package:go_router/go_router.dart';
import '../../../../../utils/widgets/toast_message.dart';

class PickupOrderMapPage extends StatefulWidget {
  final Pickups pickup;
  final String locationType; // 'customer' or 'seller'

  const PickupOrderMapPage({
    super.key,
    required this.pickup,
    this.locationType = 'customer',
  });

  @override
  State<PickupOrderMapPage> createState() => _PickupOrderMapPageState();
}

class _PickupOrderMapPageState extends State<PickupOrderMapPage> {
  gm.GoogleMapController? _mapController;
  LocationData? _currentLocation;
  bool _isLoadingLocation = true;

  // Current stage of pickup process
  // 0 = heading to customer, 1 = at customer (confirm pickup), 2 = heading to store
  int _currentStage = 0;

  @override
  void initState() {
    super.initState();

    _preloadMarkerIcons();

    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;
      if (_isLoadingLocation) {
        _setFallbackLocation();
      }
    });

    _getCurrentLocation();
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

      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToAllPoints());
    } catch (e) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    setState(() {
      // Use customer location from delivery route as fallback
      double fallbackLat = 21.1458; // Default Nagpur coordinates
      double fallbackLng = 79.0882;

      if (widget.pickup.deliveryRoute?.routeDetails != null &&
          widget.pickup.deliveryRoute!.routeDetails!.isNotEmpty) {
        // First item should be customer location (where we pick from)
        final customerLocation = widget.pickup.deliveryRoute!.routeDetails![0];

        if (customerLocation.latitude != null &&
            customerLocation.longitude != null) {
          fallbackLat = customerLocation.latitude!;
          fallbackLng = customerLocation.longitude!;
        }
      }

      _currentLocation = LocationData.fromMap({
        'latitude': fallbackLat,
        'longitude': fallbackLng,
      });
      _isLoadingLocation = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToAllPoints());
  }

  bool _isValidLatLng(LatLng point) {
    return !point.latitude.isNaN &&
        !point.latitude.isInfinite &&
        !point.longitude.isNaN &&
        !point.longitude.isInfinite;
  }

  void _fitMapToAllPoints() {
    if (_currentLocation == null) return;

    final List<LatLng> allPoints = [];
    final currentLatLng = _getCurrentLocationLatLng();
    if (_isValidLatLng(currentLatLng)) {
      allPoints.add(currentLatLng);
    }

    // Add customer location (first item in route_details)
    if (widget.pickup.deliveryRoute?.routeDetails != null &&
        widget.pickup.deliveryRoute!.routeDetails!.isNotEmpty) {
      final customerLocation = widget.pickup.deliveryRoute!.routeDetails![0];

      if (customerLocation.latitude != null &&
          customerLocation.longitude != null) {
        final customerPoint = LatLng(
          customerLocation.latitude!,
          customerLocation.longitude!,
        );
        if (_isValidLatLng(customerPoint)) {
          allPoints.add(customerPoint);
        }
      }

      // Add store location (last item in route_details if different from customer)
      if (widget.pickup.deliveryRoute!.routeDetails!.length > 1) {
        final storeLocation = widget.pickup.deliveryRoute!.routeDetails!.last;

        if (storeLocation.latitude != null && storeLocation.longitude != null) {
          final storePoint = LatLng(
            storeLocation.latitude!,
            storeLocation.longitude!,
          );

          if (_isValidLatLng(storePoint)) {
            // Only add if different from customer location
            bool isDifferent = true;
            if (allPoints.length > 1) {
              if ((storePoint.latitude - allPoints[1].latitude).abs() <
                      0.0001 &&
                  (storePoint.longitude - allPoints[1].longitude).abs() <
                      0.0001) {
                isDifferent = false;
              }
            }

            if (isDifferent) {
              allPoints.add(storePoint);
            }
          }
        }
      }
    }

    if (allPoints.length >= 2) {
      GoogleMapHelpers.fitPoints(_mapController, allPoints, padding: 50);
    }
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
    return const LatLng(21.1458, 79.0882);
  }

  static const double _markerSize = 45;
  static const double _markerBorder = 4;

  Future<void> _preloadMarkerIcons() async {
    await Future.wait([
      for (final entry in [
        (Colors.blue, Icons.location_history),
        (Colors.orange, Icons.person_pin_circle),
        (Colors.green, Icons.person_pin_circle),
        (Colors.red, Icons.store),
        (Colors.green, Icons.store),
      ])
        MapMarkerIcons.load(
          background: entry.$1,
          icon: entry.$2,
          size: _markerSize,
          borderWidth: _markerBorder,
        ),
    ]);
    if (mounted) setState(() {});
  }

  gm.Marker _circleMarker(String id, LatLng point, Color color, IconData icon) {
    return gm.Marker(
      markerId: gm.MarkerId(id),
      position: GoogleMapHelpers.toGm(point),
      icon: MapMarkerIcons.get(
        background: color,
        icon: icon,
        size: _markerSize,
        borderWidth: _markerBorder,
      ),
      anchor: const Offset(0.5, 0.5),
    );
  }

  Set<gm.Marker> _buildMarkers() {
    final markers = <gm.Marker>{};

    // Current location marker
    if (_currentLocation != null) {
      markers.add(
        _circleMarker(
          'current',
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          Colors.blue,
          Icons.location_history,
        ),
      );
    }

    // Customer location marker (where we pick from)
    if (widget.pickup.deliveryRoute?.routeDetails != null &&
        widget.pickup.deliveryRoute!.routeDetails!.isNotEmpty) {
      final customerLocation = widget.pickup.deliveryRoute!.routeDetails![0];

      if (customerLocation.latitude != null &&
          customerLocation.longitude != null) {
        markers.add(
          _circleMarker(
            'customer',
            LatLng(customerLocation.latitude!, customerLocation.longitude!),
            _currentStage >= 1 ? Colors.green : Colors.orange,
            Icons.person_pin_circle,
          ),
        );
      }

      // Store location marker (where we return to)
      if (widget.pickup.deliveryRoute!.routeDetails!.length > 1) {
        final storeLocation = widget.pickup.deliveryRoute!.routeDetails!.last;

        if (storeLocation.latitude != null && storeLocation.longitude != null) {
          markers.add(
            _circleMarker(
              'store',
              LatLng(storeLocation.latitude!, storeLocation.longitude!),
              _currentStage >= 2 ? Colors.green : Colors.red,
              Icons.store,
            ),
          );
        }
      }
    }

    return markers;
  }

  List<LatLng> _generateRoute() {
    if (_currentLocation == null) return [];

    final List<LatLng> routePoints = [
      LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
    ];

    if (widget.pickup.deliveryRoute?.routeDetails != null &&
        widget.pickup.deliveryRoute!.routeDetails!.isNotEmpty) {
      // Add customer location
      final customerLocation = widget.pickup.deliveryRoute!.routeDetails![0];

      if (customerLocation.latitude != null &&
          customerLocation.longitude != null) {
        routePoints.add(
          LatLng(customerLocation.latitude!, customerLocation.longitude!),
        );
      }

      // Add store location if in stage 2
      if (_currentStage >= 2 &&
          widget.pickup.deliveryRoute!.routeDetails!.length > 1) {
        final storeLocation = widget.pickup.deliveryRoute!.routeDetails!.last;

        if (storeLocation.latitude != null && storeLocation.longitude != null) {
          routePoints.add(
            LatLng(storeLocation.latitude!, storeLocation.longitude!),
          );
        }
      }
    }

    return routePoints;
  }

  String _getStageTitle() {
    if (widget.locationType == 'customer') {
      switch (_currentStage) {
        case 0:
          return 'Going to Customer Location';
        case 1:
          return 'Arrived at Customer Location';
        default:
          return 'Pickup Order';
      }
    } else {
      switch (_currentStage) {
        case 0:
          return 'Going to Seller Location';
        case 1:
          return 'Arrived at Seller Location';
        default:
          return 'Pickup Order';
      }
    }
  }

  String _getStageDescription() {
    if (widget.locationType == 'customer') {
      switch (_currentStage) {
        case 0:
          return 'Navigate to customer location to pick up the order';
        case 1:
          return 'Arrived at customer location. Click "Pick Up Order" to confirm';
        default:
          return '';
      }
    } else {
      switch (_currentStage) {
        case 0:
          return 'Navigate to seller location to return the order';
        case 1:
          return 'Arrived at seller location. Click "Confirm Return" to complete';
        default:
          return '';
      }
    }
  }

  void _showArrivalConfirmationDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Arrival'),
            content: Text(
              widget.locationType == 'customer'
                  ? (_currentStage == 0
                      ? 'Have you reached the customer location?'
                      : 'Ready to pick up the order?')
                  : (_currentStage == 0
                      ? 'Have you reached the seller location?'
                      : 'Ready to return the order?'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    if (_currentStage == 0) {
                      _currentStage = 1;
                    } else if (_currentStage == 1) {
                      _currentStage = 2;
                    }
                  });

                  ToastManager.show(
                    context: context,
                    message: 'Arrival confirmed!',
                    type: ToastType.success,
                  );
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return CustomScaffold(
          appBar: CustomAppBarWithoutNavbar(
            title: _getStageTitle(),
            showRefreshButton: false,
            showThemeToggle: false,
          ),
          body: Stack(
            children: [
              gm.GoogleMap(
                initialCameraPosition: gm.CameraPosition(
                  target: GoogleMapHelpers.toGm(
                    (() {
                      final center = _getCurrentLocationLatLng();
                      return _isValidLatLng(center)
                          ? center
                          : const LatLng(21.1458, 79.0882);
                    })(),
                  ),
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _fitMapToAllPoints(),
                  );
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                polylines: {
                  gm.Polyline(
                    polylineId: const gm.PolylineId('route'),
                    points: GoogleMapHelpers.toGmList(_generateRoute()),
                    width: 3.sp.round(),
                    color: AppColors.primaryColor,
                  ),
                },
                markers: _buildMarkers(),
              ),
              // Bottom information card
              Positioned(
                bottom: 20,
                left: 16.w,
                right: 16.w,
                child: Container(
                  padding: EdgeInsets.all(16.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stage indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomText(
                              text: _getStageDescription(),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      // Action buttons
                      if (_currentStage == 0 || _currentStage == 1)
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            textSize: 15.sp,
                            text:
                                _currentStage == 0
                                    ? (widget.locationType == 'customer'
                                        ? 'Arrived at Customer'
                                        : 'Arrived at Seller')
                                    : (widget.locationType == 'customer'
                                        ? 'Pick Up Order'
                                        : 'Confirm Return'),
                            onPressed: _showArrivalConfirmationDialog,
                            icon: Icon(
                              _currentStage == 0
                                  ? Icons.location_on
                                  : (widget.locationType == 'customer'
                                      ? Icons.shopping_bag
                                      : Icons.check_circle),
                              color: Colors.white,
                            ),
                            backgroundColor: AppColors.primaryColor,
                            textColor: Colors.white,
                            borderRadius: 8.r,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (_currentStage == 2)
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            textSize: 15.sp,
                            text: 'Arrived at Store',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text(
                                        'Return Order to Store',
                                      ),
                                      content: const Text(
                                        'Have you returned the order to the store?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            context.pop();
                                            ToastManager.show(
                                              context: context,
                                              message:
                                                  'Order returned to store. You can now update the status.',
                                              type: ToastType.success,
                                            );
                                          },
                                          child: const Text('Confirm'),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                            ),
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                            borderRadius: 8.r,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Navigation button
              Positioned(
                top: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () async {
                    try {
                      final currentLocation = _getCurrentLocationLatLng();
                      final currentLat = currentLocation.latitude.toString();
                      final currentLng = currentLocation.longitude.toString();

                      String destinationAddress = 'Nagpur, Maharashtra, India';

                      // Choose destination based on current stage
                      if (widget.pickup.deliveryRoute?.routeDetails != null &&
                          widget
                              .pickup
                              .deliveryRoute!
                              .routeDetails!
                              .isNotEmpty) {
                        final targetLocation =
                            _currentStage == 0
                                ? widget.pickup.deliveryRoute!.routeDetails![0]
                                : widget
                                    .pickup
                                    .deliveryRoute!
                                    .routeDetails!
                                    .last;

                        if (targetLocation.latitude != null &&
                            targetLocation.longitude != null) {
                          // Coordinates not needed for Google Maps URL
                          // but using address instead
                        }

                        if (targetLocation.address != null &&
                            targetLocation.address!.isNotEmpty) {
                          destinationAddress = targetLocation.address!;
                        }
                      }

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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
