import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import 'package:nagpur_rider/screens/feed_page/view/map/return_pickup/return_handoff_dialog.dart';

import 'support/fake_return_order_repo.dart';

class _Harness {
  ReturnHandoffResult? result;
}

Future<_Harness> _open(
  WidgetTester tester,
  FakeReturnOrderRepo repo, {
  String status = 'picked_up',
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(720, 1280);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final harness = _Harness();
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder:
              (context) => TextButton(
                onPressed: () async {
                  harness.result = await showDialog<ReturnHandoffResult>(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (_) => ReturnHandoffDialog(
                          returnId: '731',
                          status: status,
                          repository: repo,
                        ),
                  );
                },
                child: const Text('Open handoff'),
              ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open handoff'));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  const input = ValueKey('return_otp_input');
  const verify = ValueKey('return_verify_otp');
  const cancel = ValueKey('return_cancel_otp');

  testWidgets('customer code is mandatory and leading zeros reach the server', (
    tester,
  ) async {
    final repo = FakeReturnOrderRepo();
    final harness = await _open(tester, repo);
    expect(find.text('Verify customer pickup'), findsOneWidget);
    await tester.tap(find.byKey(verify));
    await tester.pump();
    expect(find.text('Enter a valid six-digit OTP.'), findsOneWidget);
    expect(repo.updates, isEmpty);
    await tester.enterText(find.byKey(input), '012345');
    await tester.tap(find.byKey(verify));
    await tester.pumpAndSettle();
    expect(repo.updates.single.otp, '012345');
    expect(harness.result!.verified, isTrue);
    expect(harness.result!.pickup.pickupStatus, 'picked_up');
  });

  testWidgets(
    'seller handover requests a separate code and cancellation does nothing',
    (tester) async {
      final repo = FakeReturnOrderRepo();
      final harness = await _open(tester, repo, status: 'delivered_to_seller');
      expect(find.text('Verify seller handover'), findsOneWidget);
      expect(find.textContaining('separate six-digit OTP'), findsOneWidget);
      await tester.tap(find.byKey(cancel));
      await tester.pumpAndSettle();
      expect(repo.updates, isEmpty);
      expect(harness.result, isNull);
    },
  );

  testWidgets('invalid OTP stays open and can be corrected', (tester) async {
    final repo =
        FakeReturnOrderRepo()
          ..update = (_) async => returnFailure('invalid_otp', 'Invalid OTP');
    final harness = await _open(tester, repo);
    await tester.enterText(find.byKey(input), '111111');
    await tester.tap(find.byKey(verify));
    await tester.pumpAndSettle();
    expect(find.text('Invalid OTP'), findsOneWidget);
    expect(harness.result, isNull);
    repo.update = null;
    await tester.enterText(find.byKey(input), '012345');
    await tester.tap(find.byKey(verify));
    await tester.pumpAndSettle();
    expect(repo.updates.map((u) => u.otp), ['111111', '012345']);
    expect(harness.result!.pickup.pickupStatus, 'picked_up');
  });

  testWidgets('SMS delivery failure leaves the pickup dialog retryable', (
    tester,
  ) async {
    final repo =
        FakeReturnOrderRepo()
          ..update =
              (_) async => returnFailure(
                'otp_delivery_failed',
                'Seller OTP could not be sent',
              );
    final harness = await _open(tester, repo);
    await tester.enterText(find.byKey(input), '012345');
    await tester.tap(find.byKey(verify));
    await tester.pumpAndSettle();
    expect(find.text('Seller OTP could not be sent'), findsOneWidget);
    expect(harness.result, isNull);
    expect(
      tester.widget<FilledButton>(find.byKey(verify)).onPressed,
      isNotNull,
    );
  });

  testWidgets('waiting disables input, cancel, back and duplicate submission', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>>();
    final repo = FakeReturnOrderRepo()..update = (_) => pending.future;
    final harness = await _open(tester, repo);
    await tester.enterText(find.byKey(input), '012345');
    await tester.tap(find.byKey(verify));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byKey(verify)).onPressed, isNull);
    expect(tester.widget<TextButton>(find.byKey(cancel)).onPressed, isNull);
    expect(tester.widget<TextFormField>(find.byKey(input)).enabled, isFalse);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(ReturnHandoffDialog), findsOneWidget);
    expect(repo.updates, hasLength(1));
    pending.complete(pickupResponse('picked_up'));
    await tester.pumpAndSettle();
    expect(harness.result!.verified, isTrue);
  });

  testWidgets(
    'stale transition closes with server status without claiming verification',
    (tester) async {
      final repo =
          FakeReturnOrderRepo()
            ..update =
                (_) async =>
                    returnFailure('invalid_transition', 'Status changed');
      final harness = await _open(tester, repo);
      await tester.enterText(find.byKey(input), '012345');
      await tester.tap(find.byKey(verify));
      await tester.pumpAndSettle();
      expect(harness.result!.verified, isFalse);
      expect(harness.result!.pickup.pickupStatus, 'picked_up');
      expect(repo.detailCalls, 1);
    },
  );

  testWidgets('both OTP dialogs fit small phones in every supported language', (
    tester,
  ) async {
    for (final locale in AppLocalizations.supportedLocales) {
      for (final status in ['picked_up', 'delivered_to_seller']) {
        await _open(
          tester,
          FakeReturnOrderRepo(),
          status: status,
          locale: locale,
        );
        expect(tester.takeException(), isNull, reason: '$locale $status');
        await tester.tap(find.byKey(cancel));
        await tester.pumpAndSettle();
      }
    }
  });
}
