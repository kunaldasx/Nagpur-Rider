import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nagpur_rider/config/theme_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import 'package:nagpur_rider/utils/location_tracker.dart';
import 'package:nagpur_rider/utils/widgets/location_status_banner.dart';

void main() {
  // Replaces Flutter's unused counter-template smoke test with the rider UI.
  for (final entry
      in <LocationHealthStatus, (String, String?)>{
        LocationHealthStatus.serviceOff: (
          "GPS is off. You won't get orders.",
          'Turn on location',
        ),
        LocationHealthStatus.permissionDenied: (
          "Location access is off. You won't get orders.",
          'Open settings',
        ),
        LocationHealthStatus.backgroundDenied: (
          'Background location is off. You may miss nearby orders while the app is closed.',
          'Allow all the time',
        ),
        LocationHealthStatus.weakSignal: (
          'Weak GPS signal. Move to an open area.',
          null,
        ),
        LocationHealthStatus.mockLocation: (
          'Turn off fake GPS apps to get orders.',
          null,
        ),
        LocationHealthStatus.stale: (
          "Can't send your location. Check your internet.",
          null,
        ),
      }.entries) {
    testWidgets('home location banner for ${entry.key}', (tester) async {
      await tester.pumpWidget(
        BlocProvider(
          create: (_) => ThemeBloc(),
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder:
                (_, __) => MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(body: LocationIssueBanner(status: entry.key)),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.value.$1), findsOneWidget);
      if (entry.value.$2 != null) {
        expect(find.text(entry.value.$2!), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
