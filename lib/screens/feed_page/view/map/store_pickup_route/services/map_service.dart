import 'dart:math' show sin, cos, atan2, sqrt, pow;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:dio/dio.dart';
import '../../../../../../utils/map/google_map_helpers.dart';
import '../../../../model/available_orders.dart';

class MapService {
  static const double _earthRadius = 6371; // Earth's radius in kilometers

  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * pi / 180;

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = _earthRadius * c;

    return distance;
  }

  /// Generate pickup route from current location to stores (excluding customer location)
  static List<LatLng> generatePickupRoutePoints(
    LocationData? currentLocation,
    List<RouteDetails>? routeDetails,
  ) {
    final List<LatLng> routePoints = [];

    final startingPoint = _locationDataToLatLng(currentLocation);
    if (startingPoint != null) {
      routePoints.add(startingPoint);
    }

    if (routeDetails != null && routeDetails.isNotEmpty) {
      // Get all route details except the last one (which is usually the customer)
      // or filter based on storeId
      final stores = getFilteredStores(routeDetails);
      for (final store in stores) {
        final storePoint = _routeDetailToLatLng(store);
        if (storePoint != null) {
          _addPointIfNew(routePoints, storePoint);
        }
      }
    }

    return routePoints;
  }

  /// Generate delivery route from current location/store to customer location
  static List<LatLng> generateDeliveryRoutePoints(
    LocationData? currentLocation,
    List<RouteDetails>? routeDetails, {
    LatLng? storePoint,
  }) {
    final List<LatLng> routePoints = [];

    // If we have a specific starting store point, use it, otherwise use current location
    final startPoint = storePoint ?? _locationDataToLatLng(currentLocation);
    if (startPoint != null) {
      routePoints.add(startPoint);
    }

    if (routeDetails != null && routeDetails.isNotEmpty) {
      // The last item is the customer location
      final customer = routeDetails.last;
      final customerPoint = _routeDetailToLatLng(customer);
      if (customerPoint != null) {
        _addPointIfNew(routePoints, customerPoint);
      }
    }

    return routePoints;
  }

  static LatLng? _locationDataToLatLng(LocationData? locationData) {
    if (locationData == null) return null;
    final lat = locationData.latitude;
    final lng = locationData.longitude;
    if (lat == null ||
        lng == null ||
        lat.isNaN ||
        lng.isNaN ||
        lat.isInfinite ||
        lng.isInfinite) {
      return null;
    }
    return LatLng(lat, lng);
  }

  static LatLng? _routeDetailToLatLng(RouteDetails detail) {
    final lat = detail.latitude;
    final lng = detail.longitude;
    if (lat == null ||
        lng == null ||
        lat.isNaN ||
        lng.isNaN ||
        lat.isInfinite ||
        lng.isInfinite) {
      return null;
    }
    return LatLng(lat, lng);
  }

  static void _addPointIfNew(List<LatLng> points, LatLng point) {
    if (points.isEmpty) {
      points.add(point);
      return;
    }

    final last = points.last;
    if (!_arePointsEqual(last, point)) {
      points.add(point);
    }
  }

  static bool _arePointsEqual(
    LatLng a,
    LatLng b, {
    double tolerance = 0.000001,
  }) {
    return (a.latitude - b.latitude).abs() < tolerance &&
        (a.longitude - b.longitude).abs() < tolerance;
  }

  /// Generate curved path between points
  static List<LatLng> generateCurvedPath(
    List<LatLng> routePoints, {
    double curveIntensity = 0.12,
  }) {
    if (routePoints.length < 2) return routePoints;

    final List<LatLng> curvedPoints = [];

    for (int i = 0; i < routePoints.length - 1; i++) {
      final start = routePoints[i];
      final end = routePoints[i + 1];

      // Add start point
      curvedPoints.add(start);

      // Calculate midpoint
      final midLat = (start.latitude + end.latitude) / 2;
      final midLng = (start.longitude + end.longitude) / 2;

      // Calculate perpendicular offset for curve
      final latDiff = end.latitude - start.latitude;
      final lngDiff = end.longitude - start.longitude;

      // Perpendicular vector (swap and negate)
      final perpLat = -lngDiff;
      final perpLng = latDiff;

      // Normalize perpendicular vector
      final perpMagnitude = sqrt(perpLat * perpLat + perpLng * perpLng);
      if (perpMagnitude > 0) {
        final normalizedPerpLat = perpLat / perpMagnitude;
        final normalizedPerpLng = perpLng / perpMagnitude;

        // Apply curve with intensity
        final curveLat = midLat + normalizedPerpLat * curveIntensity;
        final curveLng = midLng + normalizedPerpLng * curveIntensity;

        // Add curved midpoint
        curvedPoints.add(LatLng(curveLat, curveLng));
      }

      // Add end point (will be start of next segment)
      if (i == routePoints.length - 2) {
        curvedPoints.add(end);
      }
    }

    return curvedPoints;
  }

  static const Color _routeStoreColor = Colors.orange;
  static final Color _deliveryStoreColor = Colors.orange.withValues(alpha: 0.8);

  /// Generates every marker icon used by [buildPickupMarkers] and
  /// [buildDeliveryMarkers]. Await before building markers.
  static Future<void> preloadMarkerIcons() async {
    await Future.wait([
      MapMarkerIcons.load(background: Colors.blue, icon: Icons.directions_bike),
      MapMarkerIcons.load(
        background: _routeStoreColor,
        icon: Icons.store,
        size: 40,
      ),
      MapMarkerIcons.load(
        background: _deliveryStoreColor,
        icon: Icons.store,
        size: 35,
        borderWidth: 2,
      ),
      MapMarkerIcons.load(background: Colors.red, icon: Icons.location_on),
    ]);
  }

  static bool _isValidLocation(LocationData? location) =>
      location != null &&
      location.latitude != null &&
      location.longitude != null &&
      !location.latitude!.isNaN &&
      !location.latitude!.isInfinite &&
      !location.longitude!.isNaN &&
      !location.longitude!.isInfinite;

  static gm.Marker _riderMarker(LocationData location, double rotation) {
    return gm.Marker(
      markerId: const gm.MarkerId('rider'),
      position: gm.LatLng(location.latitude!, location.longitude!),
      icon: MapMarkerIcons.get(
        background: Colors.blue,
        icon: Icons.directions_bike,
      ),
      anchor: const Offset(0.5, 0.5),
      rotation: rotation,
      flat: true,
      zIndexInt: 2,
    );
  }

  /// Build all markers for the map
  static Set<gm.Marker> buildPickupMarkers(
    LocationData? currentLocation,
    List<RouteDetails>? routeDetails, {
    double rotation = 0,
  }) {
    final Set<gm.Marker> markers = {};

    // Current location marker (Rider - Blue vehicle)
    if (_isValidLocation(currentLocation)) {
      markers.add(_riderMarker(currentLocation!, rotation));
    }

    // Store markers (Yellow/Orange circles)
    final stores = getFilteredStores(routeDetails);
    for (int i = 0; i < stores.length; i++) {
      final store = stores[i];
      if (store.latitude != null && store.longitude != null) {
        markers.add(
          gm.Marker(
            markerId: gm.MarkerId('store_$i'),
            position: gm.LatLng(store.latitude!, store.longitude!),
            icon: MapMarkerIcons.get(
              background: _routeStoreColor,
              icon: Icons.store,
              size: 40,
            ),
            anchor: const Offset(0.5, 0.5),
            infoWindow: gm.InfoWindow(title: store.storeName),
          ),
        );
      }
    }

    return markers;
  }

  /// Build delivery markers
  static Set<gm.Marker> buildDeliveryMarkers(
    LocationData? currentLocation,
    List<RouteDetails>? routeDetails, {
    double rotation = 0,
  }) {
    final Set<gm.Marker> markers = {};

    // Current location marker (Rider - Blue vehicle)
    if (_isValidLocation(currentLocation)) {
      markers.add(_riderMarker(currentLocation!, rotation));
    }

    // Store markers (Yellow/Orange) - showing where the items were picked up from
    final stores = getFilteredStores(routeDetails);
    for (int i = 0; i < stores.length; i++) {
      final store = stores[i];
      if (store.latitude != null && store.longitude != null) {
        markers.add(
          gm.Marker(
            markerId: gm.MarkerId('store_$i'),
            position: gm.LatLng(store.latitude!, store.longitude!),
            icon: MapMarkerIcons.get(
              background: _deliveryStoreColor,
              icon: Icons.store,
              size: 35,
              borderWidth: 2,
            ),
            anchor: const Offset(0.5, 0.5),
            infoWindow: gm.InfoWindow(title: store.storeName),
          ),
        );
      }
    }

    // Delivery location marker (Red)
    if (routeDetails != null && routeDetails.isNotEmpty) {
      final customer = routeDetails.last;
      if (customer.latitude != null && customer.longitude != null) {
        markers.add(
          gm.Marker(
            markerId: const gm.MarkerId('customer'),
            position: gm.LatLng(customer.latitude!, customer.longitude!),
            icon: MapMarkerIcons.get(
              background: Colors.red,
              icon: Icons.location_on,
            ),
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 1,
          ),
        );
      }
    }

    return markers;
  }

  /// Calculate total route distance (current location → store 1 → store 2 → delivery address)
  static double calculateDistanceToStores(
    LocationData? currentLocation,
    List<RouteDetails>? routeDetails,
  ) {
    if (currentLocation == null || routeDetails == null) {
      return 0.0;
    }

    if (routeDetails.isEmpty) {
      return 0.0;
    }

    double totalDistance = 0.0;
    LatLng? previousPoint = LatLng(
      currentLocation.latitude!,
      currentLocation.longitude!,
    );

    // Calculate distance following the actual route path
    for (int i = 0; i < routeDetails.length; i++) {
      final routePoint = routeDetails[i];

      // Skip if it's "Customer Location" or doesn't have coordinates
      if (routePoint.storeName != null &&
          routePoint.storeName!.toLowerCase() != 'customer location' &&
          routePoint.latitude != null &&
          routePoint.longitude != null) {
        final currentPoint = LatLng(
          routePoint.latitude!,
          routePoint.longitude!,
        );

        // Calculate distance from previous point to current point
        final segmentDistance = calculateDistance(previousPoint!, currentPoint);
        totalDistance += segmentDistance;

        // Update previous point for next iteration
        previousPoint = currentPoint;
      } else {
        //
      }
    }

    // Add distance to delivery address (last item in route details)
    if (routeDetails.isNotEmpty) {
      final deliveryAddress = routeDetails.last;

      if (deliveryAddress.latitude != null &&
          deliveryAddress.longitude != null) {
        final deliveryLatLng = LatLng(
          deliveryAddress.latitude!,
          deliveryAddress.longitude!,
        );
        final deliveryDistance = calculateDistance(
          previousPoint!,
          deliveryLatLng,
        );
        totalDistance += deliveryDistance;
      } else {}
    }

    return totalDistance;
  }

  /// Get filtered stores (excluding Customer Location)
  static List<RouteDetails> getFilteredStores(
    List<RouteDetails>? routeDetails,
  ) {
    if (routeDetails == null) return [];

    return routeDetails
        .where(
          (store) =>
              store.storeName?.toLowerCase() != 'customer location' &&
              store.storeId != null,
        )
        .toList();
  }

  /// Fetch accurate route from OSRM
  static Future<List<LatLng>> fetchAccurateRoute(List<LatLng> points) async {
    if (points.length < 2) return points;

    try {
      final String coordinates = points
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');
      final String url =
          'https://router.project-osrm.org/route/v1/driving/$coordinates?overview=full&geometries=polyline';

      final response = await Dio().get(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['routes'] != null &&
            (data['routes'] as List).isNotEmpty &&
            data['routes'][0]['geometry'] != null) {
          final geometry = data['routes'][0]['geometry'];
          final decodedRoute = _decodeGeometry(geometry);
          if (decodedRoute.isNotEmpty) {
            return decodedRoute;
          }
        }
      }
    } catch (e) {
      // Fall back to the simple path if OSRM fails
    }

    return points;
  }

  static List<LatLng> _decodeGeometry(dynamic geometry) {
    if (geometry is String) {
      return _decodePolyline(geometry);
    }

    if (geometry is Map<String, dynamic>) {
      final coords = geometry['coordinates'];
      if (coords is List && coords.isNotEmpty) {
        return coords
            .where((c) => c is List && c.length >= 2)
            .map((c) {
              final lat = (c[1] as num).toDouble();
              final lng = (c[0] as num).toDouble();
              if (lat.isNaN || lat.isInfinite || lng.isNaN || lng.isInfinite) {
                return null;
              }
              return LatLng(lat, lng);
            })
            .whereType<LatLng>()
            .toList();
      }
    }

    if (geometry is List && geometry.isNotEmpty) {
      return geometry
          .where((c) => c is List && c.length >= 2)
          .map((c) {
            final lat = (c[1] as num).toDouble();
            final lng = (c[0] as num).toDouble();
            if (lat.isNaN || lat.isInfinite || lng.isNaN || lng.isInfinite) {
              return null;
            }
            return LatLng(lat, lng);
          })
          .whereType<LatLng>()
          .toList();
    }

    return [];
  }

  static List<LatLng> _decodePolyline(String encoded, {int precision = 5}) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;
    final int factor = pow(10, precision).toInt();

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);

      final int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      result = 0;
      shift = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);

      final int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      final finalLat = lat / factor;
      final finalLng = lng / factor;

      if (!finalLat.isNaN &&
          !finalLat.isInfinite &&
          !finalLng.isNaN &&
          !finalLng.isInfinite) {
        points.add(LatLng(finalLat, finalLng));
      }
    }

    return points;
  }

  /// Calculate the shortest distance from a point to a polyline (set of segments)
  /// Returns distance in meters
  static double minDistanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) return double.infinity;
    if (polyline.length == 1) return _distanceInMeters(point, polyline.first);

    double minDistance = double.infinity;

    for (int i = 0; i < polyline.length - 1; i++) {
      final double distance = _distanceToSegment(
        point,
        polyline[i],
        polyline[i + 1],
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// Distance from point P to segment AB in meters
  static double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final double l2 = _sqrDistance(a, b);
    if (l2 == 0.0) return _distanceInMeters(p, a);

    final double t =
        ((p.latitude - a.latitude) * (b.latitude - a.latitude) +
            (p.longitude - a.longitude) * (b.longitude - a.longitude)) /
        l2;

    if (t < 0.0) return _distanceInMeters(p, a);
    if (t > 1.0) return _distanceInMeters(p, b);

    final LatLng projection = LatLng(
      a.latitude + t * (b.latitude - a.latitude),
      a.longitude + t * (b.longitude - a.longitude),
    );

    return _distanceInMeters(p, projection);
  }

  static double _sqrDistance(LatLng a, LatLng b) {
    return (a.latitude - b.latitude) * (a.latitude - b.latitude) +
        (a.longitude - b.longitude) * (a.longitude - b.longitude);
  }

  static double _distanceInMeters(LatLng p1, LatLng p2) {
    return calculateDistance(p1, p2) * 1000; // Convert km to meters
  }

  /// Check if the user is off-route (e.g., > 40 meters away)
  static bool isPointOffRoute(
    LatLng point,
    List<LatLng> route, {
    double thresholdMeters = 40.0,
  }) {
    if (route.isEmpty) return false;
    final double distance = minDistanceToPolyline(point, route);
    return distance > thresholdMeters;
  }
}
