import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;

/// Shared helpers for rendering app data on Google Maps.
/// Business logic keeps using latlong2's [ll.LatLng]; convert at the map edge.
class GoogleMapHelpers {
  static gm.LatLng toGm(ll.LatLng p) => gm.LatLng(p.latitude, p.longitude);

  static List<gm.LatLng> toGmList(List<ll.LatLng> points) =>
      points.map(toGm).toList();

  static bool isValid(ll.LatLng p) =>
      !p.latitude.isNaN &&
      !p.latitude.isInfinite &&
      !p.longitude.isNaN &&
      !p.longitude.isInfinite;

  static gm.LatLngBounds boundsFromPoints(List<ll.LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return gm.LatLngBounds(
      southwest: gm.LatLng(minLat, minLng),
      northeast: gm.LatLng(maxLat, maxLng),
    );
  }

  /// Fits the camera to [points]; falls back to centering on a single point.
  static Future<void> fitPoints(
    gm.GoogleMapController? controller,
    List<ll.LatLng> points, {
    double padding = 50,
    double singlePointZoom = 15,
  }) async {
    if (controller == null) return;
    final valid = points.where(isValid).toList();
    if (valid.isEmpty) return;

    final distinct = <ll.LatLng>[];
    for (final p in valid) {
      final isNew = distinct.every(
        (e) =>
            (e.latitude - p.latitude).abs() > 0.000001 ||
            (e.longitude - p.longitude).abs() > 0.000001,
      );
      if (isNew) distinct.add(p);
    }

    try {
      if (distinct.length >= 2) {
        await controller.animateCamera(
          gm.CameraUpdate.newLatLngBounds(
            boundsFromPoints(distinct),
            padding,
          ),
        );
      } else {
        await controller.animateCamera(
          gm.CameraUpdate.newLatLngZoom(toGm(distinct.first), singlePointZoom),
        );
      }
    } catch (_) {
      // Map may not be laid out yet; ignore.
    }
  }
}

/// Renders the app's circular icon markers into [gm.BitmapDescriptor]s.
///
/// Icons are generated asynchronously and cached. Call [preload] (or [load])
/// before building markers; [get] returns a default marker until ready.
class MapMarkerIcons {
  static final Map<String, gm.BitmapDescriptor> _cache = {};

  static String _key(
    Color? background,
    IconData icon,
    Color iconColor,
    double size,
    double borderWidth,
  ) =>
      '${background?.toARGB32()}_${icon.codePoint}_${iconColor.toARGB32()}_${size}_$borderWidth';

  /// Returns the cached icon, or a default pin while it is not generated yet.
  static gm.BitmapDescriptor get({
    Color? background,
    required IconData icon,
    Color iconColor = Colors.white,
    double size = 45,
    double borderWidth = 3,
  }) {
    return _cache[_key(background, icon, iconColor, size, borderWidth)] ??
        gm.BitmapDescriptor.defaultMarker;
  }

  static Future<gm.BitmapDescriptor> load({
    Color? background,
    required IconData icon,
    Color iconColor = Colors.white,
    double size = 45,
    double borderWidth = 3,
  }) async {
    final key = _key(background, icon, iconColor, size, borderWidth);
    final cached = _cache[key];
    if (cached != null) return cached;

    final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final descriptor = await _render(
      background: background,
      icon: icon,
      iconColor: iconColor,
      size: size,
      borderWidth: borderWidth,
      dpr: dpr,
    );
    _cache[key] = descriptor;
    return descriptor;
  }

  static Future<gm.BitmapDescriptor> _render({
    required Color? background,
    required IconData icon,
    required Color iconColor,
    required double size,
    required double borderWidth,
    required double dpr,
  }) async {
    // Extra room around the circle for the drop shadow.
    final shadowPad = background == null ? 0.0 : 6.0;
    final logical = size + shadowPad * 2;
    final px = (logical * dpr).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr);

    final center = Offset(logical / 2, logical / 2);
    final radius = size / 2;

    if (background != null) {
      canvas.drawCircle(
        center.translate(0, 2),
        radius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(center, radius, Paint()..color = Colors.white);
      canvas.drawCircle(
        center,
        radius - borderWidth,
        Paint()..color = background,
      );
    }

    final glyphSize = background == null ? size : size * 0.5;
    final painter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: glyphSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: iconColor,
        ),
      )
      ..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );

    final image = await recorder.endRecording().toImage(px, px);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return gm.BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }
}
