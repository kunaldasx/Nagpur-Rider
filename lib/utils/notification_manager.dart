import 'dart:developer';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nagpur_rider/config/api_base_helper.dart';
import 'package:nagpur_rider/config/api_routes.dart';
import 'package:nagpur_rider/config/global.dart';
import 'package:nagpur_rider/router/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// A token belongs to one Firebase project, so the cache is keyed by the
  /// project's sender id: after the app moves to another project it fetches
  /// a fresh token instead of reusing one the new project rejects.
  static String get _cachedTokenKey =>
      'fcm_token_${Firebase.app().options.messagingSenderId}';

  Future<void> initialize() async {
    if (_initialized) {
      log('⚠️ NotificationManager already initialized');
      return;
    }

    try {
      log('🔔 Initializing NotificationManager...');

      // Request permission
      await requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup message handlers
      _setupMessageHandlers();

      // Handle terminated state (initial message)
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        log(
          '🚀 App launched from notification (terminated): ${initialMessage.messageId}',
        );
        // Small delay to ensure router is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(initialMessage);
        });
      }

      // Get and save FCM token
      await _retrieveAndSaveFCMToken();

      _initialized = true;
      log('✅ NotificationManager initialization complete');
    } catch (e) {
      log('❌ NotificationManager initialization error: $e');
      rethrow;
    }
  }

  Future<void> requestPermission() async {
    try {
      log('📱 Requesting notification permission...');

      // Match working project sequence
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      if (Platform.isIOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: true,
          );

      log('📱 Permission status: ${settings.authorizationStatus}');
    } catch (e) {
      log('❌ Error requesting permission: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android with custom sound support
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📨 Foreground message received: ${message.messageId}');
      log('Title: ${message.notification?.title}');
      log('Body: ${message.notification?.body}');
      log('Data: ${message.data}');

      // Order alerts have their own native ringing notification.
      if (message.data['type'] == 'new_order' ||
          message.data['type'] == 'order_alert_cancel')
        return;
      _showLocalNotification(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('📬 Notification tapped (background): ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Handle background messages - now called in main.dart
    // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Future<void> _retrieveAndSaveFCMToken() async {
  //   try {
  //     log('🔑 Retrieving FCM token...');
  //
  //     // For iOS, get APNS token first
  //     if (Platform.isIOS) {
  //       String? apnsToken = await _firebaseMessaging.getAPNSToken();
  //       log('🍎 APNS Token: $apnsToken');
  //
  //       if (apnsToken == null) {
  //         // Wait a bit and try again
  //         await Future.delayed(Duration(seconds: 3));
  //         apnsToken = await _firebaseMessaging.getAPNSToken();
  //         log('🍎 APNS Token (retry): $apnsToken');
  //       }
  //     }
  //
  //     // Get FCM token
  //     String? token = await _firebaseMessaging.getToken();
  //     log('🔑 FCM Token retrieved: $token');
  //
  //     if (token != null && token.isNotEmpty) {
  //       // Save to SharedPreferences
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString(_cachedTokenKey, token);
  //       log('✅ FCM Token saved to SharedPreferences');
  //     } else {
  //       log('⚠️ FCM Token is null or empty');
  //     }
  //
  //     // Listen for token refresh
  //     _firebaseMessaging.onTokenRefresh.listen((newToken) {
  //       log('🔄 FCM Token refreshed: $newToken');
  //       _saveTokenToPrefs(newToken);
  //     });
  //   } catch (e) {
  //     log('❌ Error retrieving FCM token: $e');
  //   }
  // }

  Future<void> _retrieveAndSaveFCMToken() async {
    try {
      log('🔑 Retrieving FCM & APNs tokens...');

      // === SIMULATOR FIRST TRICK ===
      // On some simulators, calling getToken() directly works even if getAPNSToken() is null.
      // We try this FIRST to avoid the 20s wait if it works.
      try {
        String? quickToken = await _firebaseMessaging.getToken();
        if (quickToken != null && quickToken.isNotEmpty) {
          log('🚀 Quick FCM Token retrieved (Simulator/Cached): $quickToken');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cachedTokenKey, quickToken);
          // We still continue to get APNs token for real devices, but we have a success already.
        }
      } catch (e) {
        log('ℹ️ Immediate getToken failed (normal for fresh iOS installs): $e');
      }

      // === APNs Token (iOS) - EXACT MATCH WITH WORKING SELLER APP ===
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        int retryCount = 0;
        const maxRetries = 10;

        while (apnsToken == null && retryCount < maxRetries) {
          log(
            '🍎 Waiting for APNs token... attempt ${retryCount + 1}/$maxRetries',
          );
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _firebaseMessaging.getAPNSToken();
          retryCount++;
        }

        if (apnsToken != null) {
          log('✅ APNs Token generated: $apnsToken');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('apns_token', apnsToken);
        } else {
          log(
            '⚠️ APNs token failed after retries (might be null on some simulators)',
          );
        }
      }

      // === Final FCM Token (Normal match with Seller app) ===
      String? fcmToken = await _firebaseMessaging.getToken();
      log('🔑 FCM Token retrieved: $fcmToken');

      if (fcmToken != null && fcmToken.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedTokenKey, fcmToken);
        log('✅ FCM Token saved to SharedPreferences');
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        log('🔄 FCM Token refreshed: $newToken');
        await _saveTokenToPrefs(newToken);
        await Global.setFCMToken(newToken);
        // Order alerts are pushed to this token: the backend must have it.
        await syncTokenWithBackend(newToken);
      });
    } catch (e) {
      log('❌ Error retrieving tokens: $e');
    }
  }

  Future<String?> getFCMToken() async {
    try {
      log('🔍 getFCMToken() called...');

      final prefs = await SharedPreferences.getInstance();
      String? cachedToken = prefs.getString(_cachedTokenKey);

      if (cachedToken != null && cachedToken.isNotEmpty) {
        log('📦 Returning CACHED FCM TOKEN');
        return cachedToken;
      }

      log('🔥 Getting token from Firebase...');
      String? token = await _firebaseMessaging.getToken();
      log('🔑 Firebase returned token: $token');

      if (token != null && token.isNotEmpty) {
        await prefs.setString(_cachedTokenKey, token);
        return token;
      }

      return null;
    } catch (e) {
      log('❌ Fatal error in getFCMToken: $e');
      return null;
    }
  }

  /// Sends this device's FCM token to the backend, which pushes order
  /// alerts to it. The login request only carries the token from login
  /// time; Firebase can change it later. Does nothing when logged out.
  Future<void> syncTokenWithBackend([String? token]) async {
    if ((Global.userToken ?? '').trim().isEmpty) return;
    try {
      token ??= await getFCMToken();
      if (token == null || token.isEmpty) return;
      final response = await ApiBaseHelper.post(
        url: updateFcmTokenApi,
        useAuthToken: true,
        body: {
          'fcm_token': token,
          // The backend reads `device_type`; `platform` is kept from the spec.
          'device_type': Platform.isAndroid ? 'android' : 'ios',
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );
      log(
        '🔑 FCM token sync: ${response['success'] == true ? 'ok' : response['message']}',
      );
    } catch (e) {
      log('❌ FCM token sync failed: $e');
    }
  }

  Future<void> _saveTokenToPrefs(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedTokenKey, token);
      log('✅ Token saved: $token');
    } catch (e) {
      log('❌ Error saving token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    // Check if custom sound is requested in data payload or use default 'notification'
    String soundName = message.data['sound'] ?? 'notification';
    // Remove extension if present (Android needs just the name)
    if (soundName.contains('.')) {
      soundName = soundName.split('.').first;
    }

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
            sound: RawResourceAndroidNotificationSound(soundName),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: '$soundName.mp3',
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    log('🔔 Local notification tapped: ${response.payload}');
    // Handle notification tap
  }

  void _handleNotificationTap(RemoteMessage message) {
    log('📬 Handling notification tap: ${message.data}');
    final type = message.data['type']?.toString();
    final metadata = message.data;

    if (type != null) {
      handleTypeRedirection(type, metadata);
    }
  }

  void handleTypeRedirection(String type, dynamic metadata) {
    log('🧭 Redirecting for type: $type');

    try {
      switch (type) {
        case 'wallet_transaction':
          // MyAppRoute.router.push(AppRoutes.allEarnings);
          break;
        case 'withdrawal_request':
        case 'withdrawal_process':
          MyAppRoute.router.push(AppRoutes.withdrawalHistory);
          break;
        case 'settlement_process':
        case 'settlement_create':
          // MyAppRoute.router.push(AppRoutes.earnings);
          break;
        case 'order_ready_for_pickup':
        case 'delivery':
          // FeedPage available orders tab
          MyAppRoute.router.go('${AppRoutes.feed}?tab=0');
          break;
        case 'return_order_available':
        case 'return_order':
          // FeedPage return orders tab
          MyAppRoute.router.go('${AppRoutes.feed}?tab=2');
          break;
        case 'order_update':
          if (metadata != null && metadata['order_id'] != null) {
            MyAppRoute.router.push(
              AppRoutes.orderDetails,
              extra: {
                'orderId': int.parse(metadata['order_id'].toString()),
                'from': true,
              },
            );
          }
          break;
        default:
          log('⚠️ Unknown notification type: $type');
          // Default to notifications list if type is unknown but tapped
          MyAppRoute.router.push(AppRoutes.notifications);
      }
    } catch (e) {
      log('❌ Redirection error: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedTokenKey);
      log('✅ FCM token deleted');
    } catch (e) {
      log('❌ Error deleting token: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('📨 Background message received: ${message.messageId}');
  log('Title: ${message.notification?.title}');
  log('Body: ${message.notification?.body}');
  log('Data: ${message.data}');
}
