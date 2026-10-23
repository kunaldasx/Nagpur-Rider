import 'dart:math' show sin, cos, atan2, sqrt, pow;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:dio/dio.dart';
import '../../../../../../config/constant.dart';
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

  /// Fetch the driving route plus up to two alternatives from OSRM.
  /// The first option is the fastest. Returns an empty list on failure.
  static Future<List<RouteOption>> fetchRouteOptions(
    LatLng from,
    LatLng to,
  ) async {
    final googleOptions = await _fetchGoogleRouteOptions(from, to);
    if (googleOptions.isNotEmpty) return googleOptions;
    return _fetchOsrmRouteOptions(from, to);
  }

  /// Google Routes API: traffic-aware times and alternative routes.
  /// Returns an empty list on any failure (e.g. API not enabled on the key).
  static Future<List<RouteOption>> _fetchGoogleRouteOptions(
    LatLng from,
    LatLng to,
  ) async {
    try {
      final isIos = defaultTargetPlatform == TargetPlatform.iOS;
      final response = await Dio().post(
        'https://routes.googleapis.com/directions/v2:computeRoutes',
        data: {
          'origin': {
            'location': {
              'latLng': {
                'latitude': from.latitude,
                'longitude': from.longitude,
              },
            },
          },
          'destination': {
            'location': {
              'latLng': {'latitude': to.latitude, 'longitude': to.longitude},
            },
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
          'computeAlternativeRoutes': true,
          'languageCode': 'en-IN',
          'units': 'METRIC',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          headers: {
            'X-Goog-Api-Key': isIos ? MapKeys.iosMapKey : MapKeys.androidMapKey,
            'X-Goog-FieldMask':
                'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,'
                'routes.legs.steps.distanceMeters,routes.legs.steps.staticDuration,'
                'routes.legs.steps.polyline.encodedPolyline,'
                'routes.legs.steps.navigationInstruction',
            if (isIos) 'X-Ios-Bundle-Identifier': 'com.nagpurmart.rider',
            if (!isIos) 'X-Android-Package': 'com.nagpurmart.rider',
            if (!isIos)
              'X-Android-Cert':
                  kReleaseMode
                      ? MapKeys.androidCertSha1Release
                      : MapKeys.androidCertSha1Debug,
          },
        ),
      );

      final routes = response.data is Map ? response.data['routes'] : null;
      if (response.statusCode != 200 || routes is! List) return [];

      final options = <RouteOption>[];
      for (final route in routes) {
        final encoded = route['polyline']?['encodedPolyline'];
        if (encoded is! String) continue;
        final points = _decodePolyline(encoded);
        if (points.length < 2) continue;
        // Duration comes as a string like "165s"
        final durationText = (route['duration'] as String? ?? '0s').replaceAll(
          's',
          '',
        );
        options.add(
          RouteOption(
            points: points,
            distanceMeters: (route['distanceMeters'] as num?)?.toDouble() ?? 0,
            durationSeconds: double.tryParse(durationText) ?? 0,
            steps: _parseGoogleSteps(route['legs']),
          ),
        );
      }
      options.sort((a, b) => a.durationSeconds.compareTo(b.durationSeconds));
      return options;
    } catch (e) {
      return [];
    }
  }

  /// Free OSRM demo server: no traffic, and in practice no alternatives.
  static Future<List<RouteOption>> _fetchOsrmRouteOptions(
    LatLng from,
    LatLng to,
  ) async {
    try {
      final String url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
          '?overview=full&geometries=polyline&alternatives=2&steps=true';

      final response = await Dio().get(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode != 200 || response.data['routes'] == null) {
        return [];
      }

      final options = <RouteOption>[];
      for (final route in response.data['routes'] as List) {
        final points = _decodeGeometry(route['geometry']);
        if (points.length < 2) continue;
        options.add(
          RouteOption(
            points: points,
            distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
            durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
            steps: _parseOsrmSteps(route['legs']),
          ),
        );
      }
      options.sort((a, b) => a.durationSeconds.compareTo(b.durationSeconds));
      return options;
    } catch (e) {
      return [];
    }
  }

  // Turn-by-turn steps from a Google Routes API route. Each step's
  // instruction describes the maneuver at the start of that step.
  static List<NavStep> _parseGoogleSteps(dynamic legs) {
    if (legs is! List) return const [];
    final steps = <NavStep>[];
    for (final leg in legs) {
      final legSteps = leg is Map ? leg['steps'] : null;
      if (legSteps is! List) continue;
      for (final step in legSteps) {
        if (step is! Map) continue;
        final encoded = step['polyline']?['encodedPolyline'];
        final points =
            encoded is String ? _decodePolyline(encoded) : <LatLng>[];
        if (points.length < 2) continue;
        final instruction = step['navigationInstruction'];
        final durationText = (step['staticDuration'] as String? ?? '0s')
            .replaceAll('s', '');
        steps.add(
          NavStep(
            instruction:
                (instruction is Map ? instruction['instructions'] : null)
                    as String? ??
                '',
            maneuver:
                (instruction is Map ? instruction['maneuver'] : null)
                    as String? ??
                'STRAIGHT',
            distanceMeters: (step['distanceMeters'] as num?)?.toDouble() ?? 0,
            durationSeconds: double.tryParse(durationText) ?? 0,
            points: points,
          ),
        );
      }
    }
    return steps;
  }

  // Turn-by-turn steps from an OSRM route, mapped onto Google's maneuver
  // names so the UI only deals with one set. The final "arrive" step is
  // dropped: the navigator adds its own arrival step.
  static List<NavStep> _parseOsrmSteps(dynamic legs) {
    if (legs is! List) return const [];
    final steps = <NavStep>[];
    for (final leg in legs) {
      final legSteps = leg is Map ? leg['steps'] : null;
      if (legSteps is! List) continue;
      for (final step in legSteps) {
        if (step is! Map) continue;
        final maneuver = step['maneuver'];
        final type = (maneuver is Map ? maneuver['type'] : null) as String?;
        if (type == 'arrive') continue;
        final points = _decodeGeometry(step['geometry']);
        if (points.length < 2) continue;
        final modifier =
            (maneuver is Map ? maneuver['modifier'] : null) as String?;
        final name = (step['name'] as String?)?.trim() ?? '';
        steps.add(
          NavStep(
            instruction: _osrmInstruction(type, modifier, name),
            maneuver: _osrmManeuver(type, modifier),
            distanceMeters: (step['distance'] as num?)?.toDouble() ?? 0,
            durationSeconds: (step['duration'] as num?)?.toDouble() ?? 0,
            points: points,
          ),
        );
      }
    }
    return steps;
  }

  static String _osrmManeuver(String? type, String? modifier) {
    final side = modifier?.contains('left') == true ? 'LEFT' : 'RIGHT';
    if (type == 'depart') return 'DEPART';
    if (type == 'roundabout' || type == 'rotary') return 'ROUNDABOUT_$side';
    if (type == 'merge') return 'MERGE';
    if (type == 'fork') return 'FORK_$side';
    if (type == 'on ramp' || type == 'off ramp') return 'RAMP_$side';
    switch (modifier) {
      case 'uturn':
        return 'UTURN_LEFT';
      case 'sharp left':
        return 'TURN_SHARP_LEFT';
      case 'left':
        return 'TURN_LEFT';
      case 'slight left':
        return 'TURN_SLIGHT_LEFT';
      case 'sharp right':
        return 'TURN_SHARP_RIGHT';
      case 'right':
        return 'TURN_RIGHT';
      case 'slight right':
        return 'TURN_SLIGHT_RIGHT';
      default:
        return 'STRAIGHT';
    }
  }

  static String _osrmInstruction(String? type, String? modifier, String name) {
    final onto = name.isEmpty ? '' : ' onto $name';
    final direction = modifier ?? 'straight';
    switch (type) {
      case 'depart':
        return name.isEmpty ? 'Head out' : 'Head out on $name';
      case 'roundabout':
      case 'rotary':
        return 'At the roundabout, take the exit$onto';
      case 'merge':
        return 'Merge$onto';
      case 'fork':
        return 'Keep $direction at the fork$onto';
      case 'on ramp':
        return 'Take the ramp$onto';
      case 'off ramp':
        return 'Take the exit$onto';
      case 'end of road':
        return 'At the end of the road, turn $direction$onto';
      case 'new name':
      case 'continue':
        return 'Continue$onto';
      default:
        if (direction == 'straight') return 'Continue straight$onto';
        if (direction == 'uturn') return 'Make a U-turn$onto';
        return 'Turn $direction$onto';
    }
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

/// One drivable route between two points, as returned by Google or OSRM.
class RouteOption {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<NavStep> steps;

  const RouteOption({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.steps = const [],
  });

  int get durationMinutes => (durationSeconds / 60).ceil().clamp(1, 100000);

  double get distanceKm => distanceMeters / 1000;
}

/// One turn-by-turn step of a route. [instruction] and [maneuver] describe
/// what to do at the start of the step; [points] is the road driven after it.
class NavStep {
  final String instruction;

  /// Google Routes maneuver name, e.g. TURN_RIGHT or ROUNDABOUT_LEFT.
  final String maneuver;
  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> points;

  const NavStep({
    required this.instruction,
    required this.maneuver,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.points,
  });
}
