import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../store_pickup_route/services/map_service.dart';

/// Where the rider is along a route, recomputed on every location update.
class NavProgress {
  /// Index of the step the rider is currently driving.
  final int stepIndex;

  /// The next maneuver to perform; null on the final stretch.
  final NavStep? upcoming;

  /// The maneuver after [upcoming], for the "Then" hint.
  final NavStep? then;

  /// Metres until [upcoming], or until the destination when it is null.
  final double distanceToManeuverMeters;
  final double remainingMeters;
  final double remainingSeconds;
  final bool arrived;

  const NavProgress({
    required this.stepIndex,
    required this.upcoming,
    required this.then,
    required this.distanceToManeuverMeters,
    required this.remainingMeters,
    required this.remainingSeconds,
    required this.arrived,
  });
}

/// Tracks the rider along a [RouteOption]'s steps and decides what the
/// voice guidance should say. Holds no Flutter state, so it can back any
/// map page.
class TurnByTurnNavigator {
  static const double arrivalRadiusMeters = 30;

  RouteOption _route;
  int _stepIndex = 0;
  bool _needsFullSearch = true;
  final Set<String> _announced = {};
  late List<double> _stepLengths;

  TurnByTurnNavigator(this._route) {
    _stepLengths = _route.steps.map((s) => _polylineLength(s.points)).toList();
  }

  RouteOption get route => _route;
  List<NavStep> get steps => _route.steps;
  int get stepIndex => _stepIndex;

  /// Swap in a refreshed or rerouted route. The rider's step is found again
  /// from scratch on the next [update]; prompts already spoken stay spoken.
  void setRoute(RouteOption route) {
    _route = route;
    _stepLengths = route.steps.map((s) => _polylineLength(s.points)).toList();
    _stepIndex = 0;
    _needsFullSearch = true;
  }

  NavProgress update(LatLng rider) {
    final steps = _route.steps;
    final destination = _route.points.last;
    final toDestination = _distance(rider, destination);

    if (steps.isEmpty) {
      return NavProgress(
        stepIndex: 0,
        upcoming: null,
        then: null,
        distanceToManeuverMeters: toDestination,
        remainingMeters: toDestination,
        remainingSeconds: _scaledSeconds(toDestination),
        arrived: toDestination <= arrivalRadiusMeters,
      );
    }

    // Only look a few steps ahead so a road that passes near itself later
    // doesn't make the rider jump forward. Never step backwards.
    final from = _needsFullSearch ? 0 : _stepIndex;
    final to =
        _needsFullSearch
            ? steps.length - 1
            : math.min(steps.length - 1, _stepIndex + 3);
    _needsFullSearch = false;

    int best = _stepIndex;
    double bestDistance = double.infinity;
    for (int i = from; i <= to; i++) {
      final d = _closestOnPolyline(rider, steps[i].points).distance;
      // Prefer the later step at a junction where both are equally close
      if (d < bestDistance - 2 || (d <= bestDistance + 2 && i > best)) {
        best = i;
        bestDistance = math.min(d, bestDistance);
      }
    }
    _stepIndex = best;

    final onStep = _closestOnPolyline(rider, steps[_stepIndex].points);
    final leftOnStep = math.max(0.0, _stepLengths[_stepIndex] - onStep.along);
    double remaining = leftOnStep;
    for (int i = _stepIndex + 1; i < steps.length; i++) {
      remaining += _stepLengths[i];
    }

    final upcoming =
        _stepIndex + 1 < steps.length ? steps[_stepIndex + 1] : null;
    final then = _stepIndex + 2 < steps.length ? steps[_stepIndex + 2] : null;

    return NavProgress(
      stepIndex: _stepIndex,
      upcoming: upcoming,
      then: then,
      distanceToManeuverMeters: upcoming != null ? leftOnStep : remaining,
      remainingMeters: remaining,
      remainingSeconds: _scaledSeconds(remaining),
      arrived:
          toDestination <= arrivalRadiusMeters ||
          (upcoming == null && remaining <= arrivalRadiusMeters),
    );
  }

  /// The sentence to speak for this progress, or null if nothing new.
  /// Each maneuver is announced once ahead of time and once when close.
  String? announcement(NavProgress progress, {required bool isFirst}) {
    if (progress.arrived) {
      return _announced.add('arrived')
          ? 'You have arrived at your destination'
          : null;
    }

    final upcoming = progress.upcoming;
    final instruction =
        upcoming != null
            ? primaryInstruction(upcoming)
            : 'Arrive at your destination';
    // Keyed by where the maneuver is, so a refreshed route doesn't repeat
    // a prompt the rider already heard
    final key = upcoming != null ? _locationKey(upcoming.points.first) : 'end';
    final distance = progress.distanceToManeuverMeters;

    if (isFirst) {
      // A far-off turn still gets its usual reminder at 400 m
      if (distance <= 400) _announced.add('${key}_far');
      if (distance <= 60) _announced.add('${key}_near');
      return 'Starting route. In ${spokenDistance(distance)}, $instruction';
    }
    if (distance <= 60) {
      _announced.add('${key}_far');
      return _announced.add('${key}_near') ? instruction : null;
    }
    if (distance <= 400 && distance > 100) {
      return _announced.add('${key}_far')
          ? 'In ${spokenDistance(distance)}, $instruction'
          : null;
    }
    return null;
  }

  static String _locationKey(LatLng p) =>
      '${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}';

  double _scaledSeconds(double remainingMeters) {
    if (_route.distanceMeters <= 0) return 0;
    final fraction = (remainingMeters / _route.distanceMeters).clamp(0.0, 1.0);
    return _route.durationSeconds * fraction;
  }

  /// First line of a step's instruction ("Turn right onto Wardha Rd").
  static String primaryInstruction(NavStep step) {
    final line = step.instruction.split('\n').first.trim();
    return line.isEmpty ? _fallbackInstruction(step.maneuver) : line;
  }

  /// Any further lines ("Destination will be on the left").
  static String? secondaryInstruction(NavStep step) {
    final lines = step.instruction.split('\n').skip(1).map((l) => l.trim());
    final rest = lines.where((l) => l.isNotEmpty).join(' · ');
    return rest.isEmpty ? null : rest;
  }

  static String _fallbackInstruction(String maneuver) {
    if (maneuver.contains('UTURN')) return 'Make a U-turn';
    if (maneuver.startsWith('ROUNDABOUT')) return 'Enter the roundabout';
    if (maneuver.contains('LEFT')) return 'Turn left';
    if (maneuver.contains('RIGHT')) return 'Turn right';
    return 'Continue straight';
  }

  static String spokenDistance(double meters) {
    if (meters >= 1000) {
      final km = (meters / 100).round() / 10;
      final text = km == km.roundToDouble() ? '${km.toInt()}' : '$km';
      return km == 1 ? '1 kilometre' : '$text kilometres';
    }
    return '${_roundMeters(meters)} metres';
  }

  /// "200 m" / "1.4 km", rounded the way navigation apps show it.
  static String displayDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${_roundMeters(meters)} m';
  }

  static int _roundMeters(double meters) {
    if (meters >= 100) return (meters / 50).round() * 50;
    return math.max(10, (meters / 10).round() * 10);
  }

  static double _polylineLength(List<LatLng> points) {
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += _distance(points[i - 1], points[i]);
    }
    return total;
  }

  static double _distance(LatLng a, LatLng b) =>
      MapService.calculateDistance(a, b) * 1000;

  // Closest point on a polyline to [p]: how far away it is and how far along
  // the polyline it sits. Uses a local flat projection, which is accurate to
  // well under a metre at street scale.
  static ({double distance, double along}) _closestOnPolyline(
    LatLng p,
    List<LatLng> line,
  ) {
    if (line.length < 2) {
      return (
        distance: line.isEmpty ? double.infinity : _distance(p, line.first),
        along: 0,
      );
    }
    final metersPerDegLat = 111320.0;
    final metersPerDegLng = 111320.0 * math.cos(p.latitude * math.pi / 180);

    double bestDistance = double.infinity;
    double bestAlong = 0;
    double walked = 0;
    for (int i = 0; i < line.length - 1; i++) {
      final a = line[i];
      final b = line[i + 1];
      final ax = (a.longitude - p.longitude) * metersPerDegLng;
      final ay = (a.latitude - p.latitude) * metersPerDegLat;
      final bx = (b.longitude - p.longitude) * metersPerDegLng;
      final by = (b.latitude - p.latitude) * metersPerDegLat;
      final dx = bx - ax;
      final dy = by - ay;
      final segLength2 = dx * dx + dy * dy;
      final t =
          segLength2 == 0
              ? 0.0
              : (-(ax * dx + ay * dy) / segLength2).clamp(0.0, 1.0);
      final cx = ax + t * dx;
      final cy = ay + t * dy;
      final d = math.sqrt(cx * cx + cy * cy);
      final segLength = math.sqrt(segLength2);
      if (d < bestDistance) {
        bestDistance = d;
        bestAlong = walked + t * segLength;
      }
      walked += segLength;
    }
    return (distance: bestDistance, along: bestAlong);
  }
}
