import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nagpur_rider/config/theme_bloc.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import 'package:nagpur_rider/screens/feed_page/model/return_orders_list_model.dart';
import 'package:nagpur_rider/screens/feed_page/view/map/return_pickup/return_pickup_flow.dart';
import 'package:nagpur_rider/screens/feed_page/view/map/return_pickup/return_pickup_sheet.dart';
import 'package:nagpur_rider/screens/feed_page/view/map/store_pickup_route/services/map_service.dart';

final _pickup = Pickups.fromJson({
  'id': 1042,
  'pickup_status': 'pending',
  'reason': 'Damaged product',
  'order': {
    'shipping_name': 'Rahul Verma',
    'shipping_address_1': 'Plot 12',
    'shipping_city': 'Nagpur',
  },
  'store': {'name': 'Sharma Kirana', 'address': 'Dharampeth'},
  'order_item': {
    'product': {'name': 'Dettol Handwash'},
  },
});

const _route = RouteOption(
  points: [LatLng(21.10, 79.08), LatLng(21.12, 79.08)],
  distanceMeters: 3400,
  durationSeconds: 720,
);

// A 400x866 phone, so ScreenUtil scales like on a real device
void _usePhoneScreen(
  WidgetTester tester, {
  Size physicalSize = const Size(1080, 2340),
  double devicePixelRatio = 2.7,
}) {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);
}

class _Taps {
  final List<String> log = [];
  VoidCallback call(String name) => () => log.add(name);
}

Future<_Taps> _pumpSheet(
  WidgetTester tester, {
  required ReturnPickupLeg leg,
  bool hasArrived = false,
  CustomerNotifyStatus notifyStatus = CustomerNotifyStatus.none,
  RouteOption? route = _route,
  bool smallPhone = false,
  bool isSubmitting = false,
}) async {
  final taps = _Taps();
  if (smallPhone) {
    // 360x640, the smallest common Android screen
    _usePhoneScreen(
      tester,
      physicalSize: const Size(720, 1280),
      devicePixelRatio: 2,
    );
  } else {
    _usePhoneScreen(tester);
  }
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => ThemeBloc(),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder:
            (_, __) => MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: ReturnPickupSheet(
                    pickup: _pickup,
                    leg: leg,
                    hasArrived: hasArrived,
                    notifyStatus: notifyStatus,
                    isSubmitting: isSubmitting,
                    isDarkTheme: false,
                    route: route,
                    onStart: taps.call('start'),
                    onShowSteps: taps.call('steps'),
                    onCall: taps.call('call'),
                    onReached: taps.call('reached'),
                    onRetryNotify: taps.call('retry'),
                    onCollected: taps.call('collected'),
                    onDelivered: taps.call('delivered'),
                  ),
                ),
              ),
            ),
      ),
    ),
  );
  // Sending/submitting has a continuously animating progress indicator.
  await tester.pump();
  return taps;
}

void main() {
  testWidgets('heading to customer: route, items and Start', (tester) async {
    final taps = await _pumpSheet(tester, leg: ReturnPickupLeg.toCustomer);

    expect(find.text('STEP 1 · PICKUP FROM CUSTOMER'), findsOneWidget);
    expect(find.textContaining('(3.4 km)'), findsOneWidget);
    expect(find.text('Rahul Verma'), findsOneWidget);
    expect(find.text('Return items (1)'), findsOneWidget);
    expect(find.text('Dettol Handwash'), findsOneWidget);
    expect(find.text('Reason: Damaged product'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('return_start')));
    await tester.tap(find.byKey(const ValueKey('return_reached')));
    expect(taps.log, ['start', 'reached']);
    expect(find.text("I've reached customer"), findsOneWidget);
  });

  testWidgets('Steps is disabled until the route loads', (tester) async {
    await _pumpSheet(tester, leg: ReturnPickupLeg.toCustomer, route: null);
    final steps = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Steps'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    expect(steps.onPressed, isNull);
    // Start stays enabled so the rider can retry loading the route
    expect(find.byKey(const ValueKey('return_start')), findsOneWidget);
  });

  testWidgets('arrived at customer: notified banner and collect swipe', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      leg: ReturnPickupLeg.toCustomer,
      hasArrived: true,
      notifyStatus: CustomerNotifyStatus.sent,
    );

    expect(find.text('ARRIVED AT CUSTOMER'), findsOneWidget);
    expect(
      find.text('Customer notified: your rider is here for the return pickup'),
      findsOneWidget,
    );
    expect(find.text('Collect these items'), findsOneWidget);
    expect(find.text('Call customer'), findsOneWidget);
    expect(find.text('Swipe: Package collected'), findsOneWidget);
    expect(find.byKey(const ValueKey('return_start')), findsNothing);
  });

  testWidgets('failed notification offers a retry', (tester) async {
    final taps = await _pumpSheet(
      tester,
      leg: ReturnPickupLeg.toCustomer,
      hasArrived: true,
      notifyStatus: CustomerNotifyStatus.failed,
    );

    expect(
      find.text("Couldn't notify the customer. Please call them."),
      findsOneWidget,
    );
    await tester.tap(find.text('Notify again'));
    expect(taps.log, ['retry']);
  });

  testWidgets('sending a notification leaves collection available', (
    tester,
  ) async {
    final taps = await _pumpSheet(
      tester,
      leg: ReturnPickupLeg.toCustomer,
      hasArrived: true,
      notifyStatus: CustomerNotifyStatus.sending,
    );
    expect(find.text('Notifying customer…'), findsOneWidget);
    expect(find.text('Notify again'), findsNothing);
    final swipe = find.byKey(const ValueKey('return_swipe_toCustomer'));
    await tester.ensureVisible(swipe);
    await tester.dragFrom(
      tester.getTopLeft(swipe) + Offset(20, tester.getSize(swipe).height / 2),
      const Offset(500, 0),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(taps.log, ['collected']);
  });

  testWidgets('submitting prevents another hand-over request', (tester) async {
    final taps = await _pumpSheet(
      tester,
      leg: ReturnPickupLeg.toSeller,
      hasArrived: true,
      isSubmitting: true,
    );
    final swipe = find.byKey(const ValueKey('return_swipe_toSeller'));
    await tester.ensureVisible(swipe);
    await tester.dragFrom(
      tester.getTopLeft(swipe) + Offset(20, tester.getSize(swipe).height / 2),
      const Offset(500, 0),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(taps.log, isEmpty);
  });

  testWidgets('heading to seller: items carried with a tick', (tester) async {
    await _pumpSheet(tester, leg: ReturnPickupLeg.toSeller);

    expect(find.text('STEP 2 · RETURN TO SELLER'), findsOneWidget);
    expect(find.text('Sharma Kirana'), findsOneWidget);
    expect(find.text('Carrying (1)'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text("I've reached seller"), findsOneWidget);
  });

  testWidgets('arrived at seller: hand-over swipe, no customer banner', (
    tester,
  ) async {
    await _pumpSheet(tester, leg: ReturnPickupLeg.toSeller, hasArrived: true);

    expect(find.text('ARRIVED AT SELLER'), findsOneWidget);
    expect(find.text('Hand over to Sharma Kirana'), findsOneWidget);
    expect(find.text('Call seller'), findsOneWidget);
    expect(find.text('Swipe: Delivered to seller'), findsOneWidget);
    expect(find.textContaining('Customer notified'), findsNothing);
  });

  testWidgets('every step fits a small phone without overflow', (tester) async {
    for (final leg in [ReturnPickupLeg.toCustomer, ReturnPickupLeg.toSeller]) {
      for (final arrived in [false, true]) {
        await _pumpSheet(
          tester,
          leg: leg,
          hasArrived: arrived,
          notifyStatus: CustomerNotifyStatus.failed,
          smallPhone: true,
        );
        expect(tester.takeException(), isNull, reason: '$leg arrived=$arrived');
      }
    }
  });

  testWidgets('completed card goes back to orders', (tester) async {
    var backed = false;
    _usePhoneScreen(tester);
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ThemeBloc(),
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder:
              (_, __) => MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: ReturnCompletedCard(
                    pickup: _pickup,
                    isDarkTheme: false,
                    onBack: () => backed = true,
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Return completed'), findsOneWidget);
    expect(find.text('Return #1042 delivered to seller'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('return_back_to_orders')));
    expect(backed, isTrue);
  });
}
