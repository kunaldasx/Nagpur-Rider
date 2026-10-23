import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nagpur_rider/screens/feed_page/view/map/navigation/turn_by_turn_navigator.dart';
import 'package:nagpur_rider/screens/feed_page/view/map/store_pickup_route/services/map_service.dart';

// An L-shaped route: ~1 km north, then ~500 m east.
const _start = LatLng(21.1000, 79.0800);
const _corner = LatLng(21.1090, 79.0800);
const _end = LatLng(21.1090, 79.0848);

RouteOption _route() => const RouteOption(
  points: [_start, _corner, _end],
  distanceMeters: 1500,
  durationSeconds: 300,
  steps: [
    NavStep(
      instruction: 'Head north on Ring Rd',
      maneuver: 'DEPART',
      distanceMeters: 1000,
      durationSeconds: 200,
      points: [_start, _corner],
    ),
    NavStep(
      instruction: 'Turn right onto Wardha Rd\nDestination will be on the left',
      maneuver: 'TURN_RIGHT',
      distanceMeters: 500,
      durationSeconds: 100,
      points: [_corner, _end],
    ),
  ],
);

void main() {
  test('tracks distance to the next turn and the remaining trip', () {
    final nav = TurnByTurnNavigator(_route());
    final p = nav.update(const LatLng(21.1045, 79.0800)); // halfway north
    expect(p.stepIndex, 0);
    expect(p.upcoming?.maneuver, 'TURN_RIGHT');
    expect(p.distanceToManeuverMeters, closeTo(500, 10));
    expect(p.remainingMeters, closeTo(1000, 15));
    expect(p.arrived, isFalse);
  });

  test('moves to the next step after the turn and detects arrival', () {
    final nav = TurnByTurnNavigator(_route());
    nav.update(const LatLng(21.1045, 79.0800));
    final after = nav.update(const LatLng(21.1090, 79.0820));
    expect(after.stepIndex, 1);
    expect(after.upcoming, isNull);
    expect(after.distanceToManeuverMeters, closeTo(290, 15));
    expect(nav.update(const LatLng(21.1090, 79.0847)).arrived, isTrue);
  });

  test('announces each turn once ahead and once when close', () {
    final nav = TurnByTurnNavigator(_route());
    final start = nav.update(_start);
    expect(
      nav.announcement(start, isFirst: true),
      'Starting route. In 1 kilometre, Turn right onto Wardha Rd',
    );

    final ahead = nav.update(const LatLng(21.1060, 79.0800)); // ~330 m out
    expect(
      nav.announcement(ahead, isFirst: false),
      'In 350 metres, Turn right onto Wardha Rd',
    );
    expect(
      nav.announcement(
        nav.update(const LatLng(21.1062, 79.0800)),
        isFirst: false,
      ),
      isNull,
    );

    final near = nav.update(const LatLng(21.1086, 79.0800)); // ~45 m out
    expect(nav.announcement(near, isFirst: false), 'Turn right onto Wardha Rd');

    // A refreshed route must not repeat the prompt
    nav.setRoute(_route());
    expect(
      nav.announcement(
        nav.update(const LatLng(21.1087, 79.0800)),
        isFirst: false,
      ),
      isNull,
    );
  });

  test('formats distances like a navigation app', () {
    expect(TurnByTurnNavigator.displayDistance(187), '200 m');
    expect(TurnByTurnNavigator.displayDistance(43), '40 m');
    expect(TurnByTurnNavigator.displayDistance(1420), '1.4 km');
    expect(
      TurnByTurnNavigator.secondaryInstruction(_route().steps[1]),
      'Destination will be on the left',
    );
  });
}
