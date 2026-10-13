import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';
import 'package:nagpur_rider/utils/map/google_map_helpers.dart';

class MapViewWidget extends StatelessWidget {
  final LatLng initialCenter;
  final Set<gm.Polyline> polylines;
  final Set<gm.Marker> markers;
  final ValueChanged<gm.GoogleMapController> onMapCreated;
  final bool showMapContent;

  const MapViewWidget({
    super.key,
    required this.initialCenter,
    required this.polylines,
    required this.markers,
    required this.onMapCreated,
    required this.showMapContent,
  });

  @override
  Widget build(BuildContext context) {
    return gm.GoogleMap(
      initialCameraPosition: gm.CameraPosition(
        target: GoogleMapHelpers.toGm(initialCenter),
        zoom: 15.0, // Increased default zoom for better visibility
      ),
      onMapCreated: onMapCreated,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      // Only show polylines and markers when content is available
      polylines: showMapContent ? polylines : const {},
      markers: showMapContent ? markers : const {},
    );
  }
}
