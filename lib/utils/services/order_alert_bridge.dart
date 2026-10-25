import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart side of the native incoming-order alert (Android only; see
/// `android/.../orderalert/`).
///
/// The backend sends a data-only, high-priority FCM message
/// (`type: new_order`, `order_id`). Native code rings and shows the alert
/// even when the app is closed. Its Accept button opens the app, which
/// accepts the order with the backend and then calls [stopAlert].
///
/// Every call is a no-op off Android and in isolates without the channel
/// (the background location service, the FCM background handler).
class OrderAlertBridge {
  OrderAlertBridge._();

  static const _channel = MethodChannel('com.nagpurmart.rider/order_alert');

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Orders ringing natively right now.
  static final ValueNotifier<Set<int>> ringing = ValueNotifier(const {});

  static final _acceptRequests = StreamController<void>.broadcast();

  /// The rider tapped Accept on an alert: call [takePendingAccept].
  static Stream<void> get acceptRequests => _acceptRequests.stream;

  static final _cancellations =
      StreamController<({int orderId, String reason})>.broadcast();
  static Stream<({int orderId, String reason})> get cancellations =>
      _cancellations.stream;

  /// Pull only after the popup subscribes; native persists events until then.
  static Future<void> deliverPendingCancellations() async {
    if (!_cancellations.hasListener) return;
    final events = await _invoke<List<dynamic>>('takePendingCancellations');
    for (final event in events ?? const []) {
      if (event is! Map) continue;
      final id = int.tryParse('${event['orderId']}');
      if (id != null) {
        _cancellations.add((orderId: id, reason: '${event['reason']}'));
      }
    }
  }

  static void init() {
    if (!_supported) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'acceptRequested':
          _acceptRequests.add(null);
          break;
        case 'alertCancelled':
          await deliverPendingCancellations();
          break;
        case 'alertsChanged':
          ringing.value = _ids(call.arguments);
          break;
      }
    });
    refreshRinging();
  }

  static Future<void> refreshRinging() async {
    final ids = await _invoke<List<dynamic>>('pendingAlerts');
    if (ids != null) ringing.value = _ids(ids);
  }

  /// Alerts only ring while a rider is logged in. Logging out stops them.
  static Future<void> setLoggedIn(bool loggedIn) =>
      _invoke<void>('setLoggedIn', {'loggedIn': loggedIn});

  /// Stops ringing for [orderId] once the backend confirmed it's accepted,
  /// or said it's no longer this rider's.
  static Future<void> stopAlert(int orderId) =>
      _invoke<void>('stopAlert', {'orderId': orderId.toString()});

  /// The order whose Accept the rider tapped, once; null if none.
  static Future<int?> takePendingAccept() async {
    final id = await _invoke<String>('takePendingAccept');
    return id == null ? null : int.tryParse(id);
  }

  /// Android 14+ can deny showing the alert over the lock screen.
  static Future<bool> canUseFullScreenIntent() async =>
      await _invoke<bool>('canUseFullScreenIntent') ?? true;

  static Future<void> openFullScreenIntentSettings() =>
      _invoke<void>('openFullScreenIntentSettings');

  /// The alert plays on the alarm stream, so a muted alarm volume silences it.
  static Future<bool> isAlarmMuted() async =>
      await _invoke<bool>('isAlarmMuted') ?? false;

  static Set<int> _ids(dynamic list) => {
    if (list is List)
      for (final id in list)
        if (int.tryParse('$id') case final parsed?) parsed,
  };

  static Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } catch (e) {
      debugPrint('[OrderAlert] $method failed: $e');
      return null;
    }
  }
}
