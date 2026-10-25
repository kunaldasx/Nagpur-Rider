import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/cubit/rider_popup_cubit.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/view/rider_order_overlay.dart';
import 'package:nagpur_rider/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:nagpur_rider/screens/system_settings/repo/system_settings_repo.dart';
import 'support/fake_rider_popup_repo.dart';

class _OfferedCubit extends RiderPopupCubit {
  _OfferedCubit() {
    emit(RiderPopupState(available: [popupOrder(status: 'pending')]));
  }
}

void main() {
  testWidgets('reserved offer shows details bag and Accept order only', (
    tester,
  ) async {
    final cubit = _OfferedCubit();
    addTearDown(cubit.close);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.7;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<RiderPopupCubit>.value(value: cubit),
          BlocProvider(create: (_) => SystemSettingsBloc(SystemSettingsRepo())),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder:
              (_, __) => const MaterialApp(
                home: RiderOrderOverlay(child: Scaffold(body: Text('Home'))),
              ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Order #NM-20260930-AB3XK9ZM'), findsOneWidget);
    expect(find.text('Customer Name'), findsOneWidget);
    expect(find.text('BAG-000033'), findsOneWidget);
    expect(find.text('Accept order'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });
}
