import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nagpur_rider/config/global.dart';
import 'package:nagpur_rider/config/theme_bloc.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import 'package:nagpur_rider/router/app_routes.dart';
import 'package:nagpur_rider/screens/auth/repo/auth_repo.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/cubit/alert_accept_cubit.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/cubit/rider_popup_cubit.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/repo/rider_popup_repo.dart';
import 'package:nagpur_rider/screens/settings/bloc/profile_bloc/profile_bloc.dart';
import 'package:nagpur_rider/screens/settings/model/profile_model.dart';
import 'package:nagpur_rider/screens/settings/repo/profile_repo.dart';
import 'package:nagpur_rider/screens/settings/view/settings.dart';
import 'package:nagpur_rider/utils/location_tracker.dart';

import 'support/fake_rider_popup_repo.dart';

class _LogoutRepo extends AuthRepository {
  int calls = 0;
  Future<Map<String, dynamic>> Function()? action;
  @override
  Future<Map<String, dynamic>> logout() async {
    calls++;
    expect(Global.userToken, 'rider-token');
    return action != null ? action!() : {'success': true};
  }
}

class _ProfileRepo extends ProfileRepo {
  @override
  Future<ProfileModel> getProfile() async => ProfileModel();
}

class _Popup extends RiderPopupCubit {
  _Popup() {
    emit(RiderPopupState(available: [popupOrder()]));
  }
}

class _Alert extends AlertAcceptCubit {
  _Alert() {
    emit(const AlertAcceptState(phase: AlertAcceptPhase.retry, orderId: 8801));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late _LogoutRepo repo;
  late _Popup popup;
  late _Alert alert;
  late GoRouter router;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rider-logout-');
    Hive.init(directory.path);
    FlutterSecureStorage.setMockInitialValues({});
    await Global.setUserToken('rider-token');
    await Global.setUserTokenExpiresAt('2999-01-01T00:00:00Z');
    await Global.setIdToken('firebase-token');
    await Global.setDeliveryBoyStatus(true);
    await Hive.openBox('RiderPopupBox');
    repo = _LogoutRepo();
    popup = _Popup();
    alert = _Alert();
    router = GoRouter(
      initialLocation: AppRoutes.feed,
      routes: [
        GoRoute(
          path: AppRoutes.feed,
          builder:
              (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => context.push(AppRoutes.more),
                  child: const Text('Settings'),
                ),
              ),
        ),
        GoRoute(
          path: AppRoutes.more,
          builder: (_, __) => MorePage(authRepository: repo),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const Scaffold(body: Text('Login screen')),
        ),
      ],
    );
  });
  tearDown(() async {
    print('TEARDOWN START');
    router.dispose();
    print('CLOSE POPUP');
    await popup.close();
    print('POPUP CLOSED');
    await alert.close();
    await Global.clearSession();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> openSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.7;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeBloc()),
          BlocProvider(create: (_) => DeliveryBoyStatusBloc()),
          BlocProvider(create: (_) => ProfileBloc(_ProfileRepo())),
          BlocProvider<RiderPopupCubit>.value(value: popup),
          BlocProvider<AlertAcceptCubit>.value(value: alert),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder:
              (_, __) => MaterialApp.router(
                routerConfig: router,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Logout'));
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
  }

  Future<void> waitForLocalLogout(WidgetTester tester) async {
    // Hive performs real file IO; flush both IO and widget-zone microtasks.
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (router.routeInformationProvider.value.uri.path == AppRoutes.login) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pumpAndSettle();
        return;
      }
    }
    fail('Logout did not navigate to login');
  }

  for (final outcome in ['success', 'network failure', 'timeout']) {
    testWidgets(
      'confirmed logout clears credentials and opens login after $outcome',
      (tester) async {
        if (outcome == 'network failure')
          repo.action = () async => throw Exception('No internet');
        if (outcome == 'timeout')
          repo.action = () => Completer<Map<String, dynamic>>().future;
        print('OPEN SETTINGS');
        await openSettings(tester);
        print('SETTINGS OPEN');
        await tester.tap(find.widgetWithText(TextButton, 'Logout'));
        await tester.pumpAndSettle();
        if (outcome == 'timeout') await tester.pump(const Duration(seconds: 5));
        print('WAIT LOCAL LOGOUT');
        await waitForLocalLogout(tester);
        print('LOCAL LOGOUT DONE');
        await tester.pumpAndSettle();
        expect(repo.calls, 1);
        expect(find.text('Login screen'), findsOneWidget);
        expect(router.canPop(), isFalse);
        expect(Global.userToken, isNull);
        print('READ EXPIRY');
        expect(await Global.getUserTokenExpiresAt(), isNull);
        print('READ EXPIRY DONE');
        expect(await Global.getIdToken(), isNull);
        expect(await Global.getDeliveryBoyStatus(), isFalse);
        expect(LocationTracker().isTracking, isFalse);
        expect(popup.state.queue, isEmpty);
        expect(alert.state.isShown, isFalse);
        expect(tester.takeException(), isNull);
        print('UNMOUNT');
        await tester.pumpWidget(const SizedBox.shrink());
        print('UNMOUNT DONE');
      },
    );
  }
  testWidgets('cancel keeps the authenticated session and route', (
    tester,
  ) async {
    await openSettings(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(repo.calls, 0);
    expect(Global.userToken, 'rider-token');
    expect(await Global.getDeliveryBoyStatus(), isTrue);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.more);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test(
    'late native accept cannot reopen the popup after logout clears it',
    () async {
      final response = Completer<AlertAcceptResult>();
      final cubit = AlertAcceptCubit(repo: _PendingAcceptRepo(response.future));
      final accepting = cubit.accept(8801);
      cubit.clear();
      response.complete(const AlertAcceptResult(AlertAcceptOutcome.accepted));
      expect(await accepting, AlertAcceptOutcome.signedOut);
      expect(cubit.state.isShown, isFalse);
      expect(cubit.state.acceptedOrderId, isNull);
      await cubit.close();
    },
  );
}

class _PendingAcceptRepo extends RiderPopupRepo {
  _PendingAcceptRepo(this.response);
  final Future<AlertAcceptResult> response;
  @override
  Future<AlertAcceptResult> acceptFromAlert(int orderId) => response;
}
