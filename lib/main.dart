// ignore_for_file: empty_catches, depend_on_referenced_packages

import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nagpur_rider/router/app_routes.dart';
import 'package:nagpur_rider/screens/auth/bloc/auth_bloc/auth_bloc.dart';
import 'package:nagpur_rider/screens/auth/bloc/phone_auth_bloc/phone_auth_bloc.dart';
import 'package:nagpur_rider/screens/auth/bloc/delivery_zone_bloc/delivery_zone_bloc.dart';
import 'package:nagpur_rider/screens/delivery_zones/bloc/delivery_zone_bloc.dart'
    as zones;
import 'package:nagpur_rider/screens/dashboard/bloc/ratings/ratings_bloc.dart';
import 'package:nagpur_rider/screens/dashboard/repo/ratings_repo.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/available_orders_bloc/available_orders_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/items_collected_bloc/items_collected_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/my_orders_bloc/my_orders_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/return_order/pickup_order_details_bloc/pickup_order_details_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/return_order/pickup_orders_list_bloc/pickup_order_list_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/return_order/return_orders_list_bloc/return_order_list_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/return_order/update_return_order_status_bloc/update_return_order_status_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/cubit/rider_popup_cubit.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/view/rider_order_overlay.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/view/rider_popup_controller.dart';
import 'package:nagpur_rider/screens/pockets/cash_collection/bloc/cash_collection_bloc.dart';
import 'package:nagpur_rider/screens/pockets/cash_collection/bloc/cash_collection_event.dart';
import 'package:nagpur_rider/screens/pockets/cash_collection/repo/cash_collection_repo.dart';
import 'package:nagpur_rider/screens/pockets/earnings/bloc/earnings_bloc.dart';
import 'package:nagpur_rider/screens/pockets/earnings/repo/earnings_repo.dart';
import 'package:nagpur_rider/screens/pockets/withdrawal/bloc/withdrawal_bloc.dart';
import 'package:nagpur_rider/screens/pockets/withdrawal/repo/withdrawal_repo.dart';
import 'package:nagpur_rider/screens/settings/bloc/profile_bloc/profile_bloc.dart';
import 'package:nagpur_rider/screens/settings/bloc/profile_bloc/profile_event.dart';
import 'package:nagpur_rider/screens/settings/repo/profile_repo.dart';
import 'package:nagpur_rider/screens/system_settings/bloc/system_settings_bloc.dart';
import 'package:nagpur_rider/screens/system_settings/bloc/system_settings_event.dart';
import 'package:nagpur_rider/screens/system_settings/repo/system_settings_repo.dart';
import 'config/global.dart';
import 'config/theme.dart';
import 'config/theme_bloc.dart';
import 'config/localization_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'utils/notification_manager.dart';
import 'utils/location_tracker.dart';
import 'screens/dashboard/bloc/notification/notification_bloc.dart';
import 'package:nagpur_rider/utils/services/order_alert_bridge.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/cubit/alert_accept_cubit.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/view/alert_accept_layer.dart';
import 'package:nagpur_rider/utils/location_monitor_widget.dart';
import 'screens/dashboard/repo/notification_list_repo.dart';

// Add these imports for Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must be registered BEFORE Firebase.initializeApp() for iOS reliability
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Firebase FIRST
  try {
    log('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('✅ Firebase initialized successfully');
  } catch (e) {
    log('❌ Firebase initialization error: $e');
    // Continue anyway - app might work without notifications
  }

  // Initialize Notification Manager AFTER Firebase
  try {
    log('🔔 Initializing NotificationManager...');
    await NotificationManager().initialize();
    log('✅ NotificationManager initialized');
  } catch (e) {
    log('❌ NotificationManager initialization error: $e');
  }

  await Hive.initFlutter();
  await Hive.openBox('theme_box');
  await Global.initializeToken();

  // Native order alerts ring only while logged in. Synced on every start so
  // riders already logged in before this update get alerts too.
  OrderAlertBridge.init();
  await OrderAlertBridge.setLoggedIn(
    (Global.userToken ?? '').trim().isNotEmpty,
  );

  final localizationService = LocalizationService();
  await localizationService.initialize();

  await initializeService();
  await _restartServicesIfNeeded();

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => const MyApp(),
    ),
  );
}

Future<void> initializeService() async {
  await _ensureLocationTrackingNotificationChannel();

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'location_tracker_channel',
      initialNotificationTitle: 'Location Tracking',
      initialNotificationContent: 'Tracking your location for deliveries',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

Future<void> _ensureLocationTrackingNotificationChannel() async {
  const channel = AndroidNotificationChannel(
    'location_tracker_channel',
    'Location Tracker Service',
    description: 'Foreground service for delivery location updates',
    importance: Importance.low,
  );

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

Future<void> _restartServicesIfNeeded() async {
  try {
    final wasOnline = await Global.getDeliveryBoyStatus();
    if (wasOnline == true) {
      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await service.startService();
      }
      service.invoke('setUpdateInterval', {'seconds': 5});
      service.invoke('triggerNow');
    }
  } catch (e) {
    log('Error checking delivery status: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final profileRepo = ProfileRepo();
    final withdrawRepo = WithdrawalRepo();
    final earningsRepo = EarningsRepo();
    final cashCollectionRepo = CashCollectionRepo();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeBloc()..add(LoadTheme())),
        BlocProvider(
          create:
              (context) =>
                  SystemSettingsBloc(SystemSettingsRepo())
                    ..add(FetchSystemSettings()),
        ),
        BlocProvider(create: (context) => AuthBloc()),
        BlocProvider(
          create:
              (context) => PhoneAuthBloc(context.read<SystemSettingsBloc>()),
        ),
        BlocProvider(create: (context) => DeliveryZoneBloc()),
        BlocProvider(create: (context) => zones.DeliveryZoneBloc()),
        BlocProvider(create: (context) => DeliveryBoyStatusBloc()),
        BlocProvider(create: (context) => AvailableOrdersBloc()),
        BlocProvider(create: (context) => MyOrdersBloc()),
        BlocProvider(create: (context) => RiderPopupCubit()),
        BlocProvider(create: (context) => AlertAcceptCubit()),
        BlocProvider(
          create: (context) => ProfileBloc(profileRepo)..add(LoadProfile()),
        ),
        BlocProvider(create: (context) => ItemsCollectedBloc()),
        BlocProvider(create: (context) => WithdrawalBloc(withdrawRepo)),
        BlocProvider(create: (context) => ReturnOrderListBloc()),
        BlocProvider(create: (context) => PickupOrderListBloc()),
        BlocProvider(create: (context) => RatingsBloc(RatingsRepo())),
        BlocProvider(create: (context) => PickupOrderDetailsBloc()),
        BlocProvider(create: (context) => UpdateReturnOrderStatusBloc()),
        ChangeNotifierProvider(create: (context) => LocalizationService()),
        BlocProvider(create: (context) => EarningsBloc(earningsRepo)),
        BlocProvider(
          create:
              (context) =>
                  CashCollectionBloc(cashCollectionRepo)
                    ..add(FetchCashCollection()),
        ),
        BlocProvider(
          create:
              (context) =>
                  NotificationBloc(NotificationListRepo())
                    ..add(FetchNotifications()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          final isDark = state.currentTheme == 'dark';

          if (state is ThemeInitial) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return Consumer<LocalizationService>(
            builder: (context, localizationService, child) {
              return SafeArea(
                top: false,
                bottom: Platform.isIOS ? false : true,
                left: false,
                right: false,
                child: RiderPopupController(
                  child: MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    theme: AppColor.getLightTheme(),
                    darkTheme: AppColor.getDarkTheme(),
                    themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                    locale: localizationService.currentLocale,
                    localizationsDelegates: [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: LocalizationService.supportedLocales,
                    builder: (context, child) {
                      return FToastBuilder()(
                        context,
                        AlertAcceptLayer(
                          child: RiderOrderOverlay(
                            child: LocationMonitor(child: child!),
                          ),
                        ),
                      );
                    },
                    routerConfig: MyAppRoute.router,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
