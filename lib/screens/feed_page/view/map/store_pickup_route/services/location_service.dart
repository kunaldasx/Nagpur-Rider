import 'dart:async';
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static final Location _location = Location();

  /// Get current location with timeout
  static Future<LocationData?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      // Check permissions
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return null;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return null;
        }
      }

      // Get current location with timeout

      final locationData = await _location.getLocation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );

      return locationData;
    } catch (e) {
      return null;
    }
  }

  /// Set fallback location using shipping address coordinates
  static LocationData? setFallbackLocation(
    double fallbackLat,
    double fallbackLng,
  ) {
    return LocationData.fromMap({
      'latitude': fallbackLat,
      'longitude': fallbackLng,
    });
  }

  /// Convert LocationData to LatLng
  static LatLng? locationDataToLatLng(LocationData? locationData) {
    if (locationData?.latitude != null &&
        locationData?.longitude != null &&
        !locationData!.latitude!.isNaN &&
        !locationData.latitude!.isInfinite &&
        !locationData.longitude!.isNaN &&
        !locationData.longitude!.isInfinite) {
      return LatLng(locationData.latitude!, locationData.longitude!);
    }
    return null;
  }

  /// Get destination location from route details
  static LatLng getDestinationLocation(List<dynamic>? routeDetails) {
    double fallbackLat = 21.1458;
    double fallbackLng = 79.0882;

    if (routeDetails != null && routeDetails.isNotEmpty) {
      final lastIndex = routeDetails.length - 1;
      final shippingAddress = routeDetails[lastIndex];

      if (shippingAddress.latitude != null &&
          shippingAddress.longitude != null) {
        fallbackLat = shippingAddress.latitude!;
        fallbackLng = shippingAddress.longitude!;
      } else {}
    }

    return LatLng(fallbackLat, fallbackLng);
  }

  /// Get location stream
  static Stream<LocationData> getLocationStream() {
    // Basic configuration for the stream
    _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000, // 1 second
      distanceFilter: 5, // 5 meters
    );
    return _location.onLocationChanged;
  }
}
