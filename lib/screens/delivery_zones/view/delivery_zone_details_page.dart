import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:nagpur_rider/config/colors.dart';
import 'package:nagpur_rider/utils/map/google_map_helpers.dart';
import 'package:nagpur_rider/utils/widgets/custom_text.dart';
import '../bloc/delivery_zone_bloc.dart';
import '../bloc/delivery_zone_event.dart';
import '../bloc/delivery_zone_state.dart';
import '../model/delivery_zone_model.dart';

class DeliveryZoneDetailsPage extends StatefulWidget {
  final int zoneId;
  final DeliveryZoneModel? zone;

  const DeliveryZoneDetailsPage({super.key, required this.zoneId, this.zone});

  @override
  State<DeliveryZoneDetailsPage> createState() =>
      _DeliveryZoneDetailsPageState();
}

class _DeliveryZoneDetailsPageState extends State<DeliveryZoneDetailsPage> {
  @override
  void initState() {
    super.initState();
    MapMarkerIcons.load(
      icon: Icons.location_pin,
      iconColor: AppColors.primaryColor,
      size: 40,
    ).then((_) {
      if (mounted) setState(() {});
    });
    // If zone is not provided, fetch it
    if (widget.zone == null) {
      context.read<DeliveryZoneBloc>().add(
        SelectDeliveryZoneEvent(widget.zoneId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(
          text: 'Zone Details',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: true,
      ),
      body:
          widget.zone != null
              ? _buildContent(widget.zone!)
              : BlocBuilder<DeliveryZoneBloc, DeliveryZoneState>(
                builder: (context, state) {
                  if (state is DeliveryZoneDetailsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is DeliveryZoneDetailsLoaded) {
                    return _buildContent(state.zone);
                  } else if (state is DeliveryZoneError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64.sp,
                            color: Colors.red,
                          ),
                          SizedBox(height: 16.h),
                          CustomText(
                            text: state.message,
                            fontSize: 16.sp,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
    );
  }

  Widget _buildContent(DeliveryZoneModel zone) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone Name
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.primaryColor,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                CustomText(
                  text: zone.name,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),

          // Map Section
          Container(
            height: 300.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: _buildMap(zone),
            ),
          ),

          SizedBox(height: 24.h),

          // Zone Information Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryColor,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    CustomText(
                      text: 'Zone Information',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Regular Time Per KM
                _buildInfoTile(
                  label: 'Regular Time Per KM',
                  value: '${zone.deliveryTimePerKm} Min',
                ),
                SizedBox(height: 12.h),

                // Buffer Time
                _buildInfoTile(
                  label: 'Buffer Time',
                  value: '${zone.bufferTime} Min',
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Coverage Details Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primaryColor,
                      size: 22.sp,
                    ),
                    SizedBox(width: 8.w),
                    CustomText(
                      text: 'Coverage Details',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Delivery Charges
                _buildDetailCard(
                  title: 'Delivery Charges',
                  items: [
                    _DetailItem(
                      label: 'Regular Delivery',
                      value: '₹${zone.regularDeliveryCharges}',
                    ),
                    if (zone.rushDeliveryEnabled &&
                        zone.rushDeliveryCharges != null)
                      _DetailItem(
                        label: 'Rush Delivery',
                        value: '₹${zone.rushDeliveryCharges}',
                      ),
                    if (zone.distanceBasedDeliveryCharges != null)
                      _DetailItem(
                        label: 'Distance Based',
                        value: '₹${zone.distanceBasedDeliveryCharges}',
                      ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Zone Radius
                _buildDetailCard(
                  title: 'Zone Coverage',
                  items: [
                    _DetailItem(
                      label: 'Radius',
                      value: '${zone.radiusKm.toStringAsFixed(3)} km',
                    ),
                    if (zone.freeDeliveryAmount != null)
                      _DetailItem(
                        label: 'Free Delivery Above',
                        value: '₹${zone.freeDeliveryAmount}',
                      ),
                  ],
                ),

                if (zone.perStoreDropOffFee != null ||
                    zone.handlingCharges != null) ...[
                  SizedBox(height: 12.h),
                  _buildDetailCard(
                    title: 'Additional Fees',
                    items: [
                      if (zone.perStoreDropOffFee != null)
                        _DetailItem(
                          label: 'Per Store Drop-off',
                          value: '₹${zone.perStoreDropOffFee}',
                        ),
                      if (zone.handlingCharges != null)
                        _DetailItem(
                          label: 'Handling Charges',
                          value: '₹${zone.handlingCharges}',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildMap(DeliveryZoneModel zone) {
    // Parse center coordinates
    double centerLat = double.tryParse(zone.centerLatitude) ?? 21.1458;
    double centerLng = double.tryParse(zone.centerLongitude) ?? 79.0882;

    // Check for NaN or Infinity
    if (centerLat.isNaN || centerLat.isInfinite) centerLat = 21.1458;
    if (centerLng.isNaN || centerLng.isInfinite) centerLng = 79.0882;

    final center = LatLng(centerLat, centerLng);

    // Convert boundary points to LatLng with validation
    final List<LatLng> boundaryPoints =
        zone.boundaryJson
            .map((point) => LatLng(point.lat, point.lng))
            .where(
              (point) =>
                  !point.latitude.isNaN &&
                  !point.latitude.isInfinite &&
                  !point.longitude.isNaN &&
                  !point.longitude.isInfinite,
            )
            .toList();

    // Close the polygon by adding the first point at the end
    if (boundaryPoints.isNotEmpty) {
      boundaryPoints.add(boundaryPoints.first);
    }

    final gmBoundary = GoogleMapHelpers.toGmList(boundaryPoints);

    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: GoogleMapHelpers.toGm(center),
        zoom: 12.0,
      ),
      minMaxZoomPreference: const gm.MinMaxZoomPreference(5.0, 18.0),
      onMapCreated: (controller) {
        if (boundaryPoints.length >= 3) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => GoogleMapHelpers.fitPoints(
              controller,
              boundaryPoints,
              padding: 40,
            ),
          );
        }
      },
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      // Zone fill; border is drawn as a dashed polyline below
      polygons: {
        if (gmBoundary.isNotEmpty)
          gm.Polygon(
            polygonId: const gm.PolygonId('zone'),
            points: gmBoundary,
            fillColor: AppColors.primaryColor.withValues(alpha: 0.2),
            strokeWidth: 0,
            strokeColor: Colors.transparent,
          ),
      },
      polylines: {
        if (gmBoundary.isNotEmpty)
          gm.Polyline(
            polylineId: const gm.PolylineId('zone_border'),
            points: gmBoundary,
            width: 2,
            color: AppColors.primaryColor,
            patterns: [gm.PatternItem.dot, gm.PatternItem.gap(8)],
          ),
      },
      // Center marker
      markers: {
        gm.Marker(
          markerId: const gm.MarkerId('center'),
          position: GoogleMapHelpers.toGm(center),
          icon: MapMarkerIcons.get(
            icon: Icons.location_pin,
            iconColor: AppColors.primaryColor,
            size: 40,
          ),
        ),
      },
    );
  }

  Widget _buildInfoTile({required String label, required String value}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(text: label, fontSize: 14.sp, color: Colors.grey.shade700),
          CustomText(text: value, fontSize: 16.sp, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<_DetailItem> items,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(text: title, fontSize: 15.sp, fontWeight: FontWeight.w600),
          SizedBox(height: 12.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: item.label,
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                  ),
                  CustomText(
                    text: item.value,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;

  _DetailItem({required this.label, required this.value});
}
