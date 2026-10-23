import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nagpur_rider/utils/services/order_alert_bridge.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class Global {
  static const String _boxName = 'UserDataBox';
  static const String _tokenKey = 'userToken';
  static const String _idTokenKey = 'firebaseIdToken';
  static const String _tokenExpiresAtKey = 'userTokenExpiresAt';

  static const String _statusBoxName = 'DeliveryBoyStatusBox';
  static const String _statusKey = 'isOnline';

  // The rider access token and its expiry live in the platform keystore
  // (Android Keystore / iOS Keychain), not in the plain Hive box.
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<Box> get _userBox async {
    return await Hive.openBox(_boxName);
  }

  static Future<Box> get _statusBox async {
    return await Hive.openBox(_statusBoxName);
  }

  static Future<void> setUserToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    _cachedToken = token;
    await OrderAlertBridge.setLoggedIn(token.trim().isNotEmpty);
  }

  static Future<void> refreshCachedToken() async {
    _cachedToken = await getUserToken();
  }

  static Future<String?> getUserToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null) return token;
    return _migrateLegacyToken();
  }

  /// Moves a token saved by older app versions out of the plain Hive box.
  static Future<String?> _migrateLegacyToken() async {
    final box = await _userBox;
    final legacyToken = box.get(_tokenKey);
    if (legacyToken is! String) return null;
    await _secureStorage.write(key: _tokenKey, value: legacyToken);
    await box.delete(_tokenKey);
    return legacyToken;
  }

  static String? _cachedToken;

  static Future<void> initializeToken() async {
    _cachedToken = await getUserToken();
  }

  static String? get userToken {
    return _cachedToken;
  }

  static Future<void> clearUserToken() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _tokenExpiresAtKey);
    final box = await _userBox;
    await box.delete(_tokenKey);
    _cachedToken = null;
    // Stops any ringing order alert, and no alert rings until the next login.
    await OrderAlertBridge.setLoggedIn(false);
  }

  // Rider tokens expire at the seller approval deadline (password login)
  // or at the QR's expires_at (QR login).
  static Future<void> setUserTokenExpiresAt(String? expiresAt) async {
    if (expiresAt == null || expiresAt.isEmpty) {
      await _secureStorage.delete(key: _tokenExpiresAtKey);
    } else {
      await _secureStorage.write(key: _tokenExpiresAtKey, value: expiresAt);
    }
  }

  static Future<DateTime?> getUserTokenExpiresAt() async {
    final value = await _secureStorage.read(key: _tokenExpiresAtKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  static Future<bool> isUserTokenExpired() async {
    final expiresAt = await getUserTokenExpiresAt();
    if (expiresAt == null) return false;
    return !DateTime.now().toUtc().isBefore(expiresAt.toUtc());
  }

  /// Clears every locally stored rider credential.
  static Future<void> clearSession() async {
    await clearUserToken();
    await clearIdToken();
    await clearDeliveryBoyStatus();
  }

  // Firebase ID Token management
  static String? _cachedIdToken;

  static Future<void> setIdToken(String idToken) async {
    final box = await _userBox;
    await box.put(_idTokenKey, idToken);
    _cachedIdToken = idToken;
    debugPrint('🔐 FIREBASE ID TOKEN SAVED TO HIVE');
  }

  static Future<String?> getIdToken() async {
    if (_cachedIdToken != null) {
      return _cachedIdToken;
    }

    final box = await _userBox;
    final idToken = box.get(_idTokenKey);
    _cachedIdToken = idToken;

    return idToken;
  }

  static Future<void> initializeIdToken() async {
    final box = await _userBox;
    _cachedIdToken = box.get(_idTokenKey);
  }

  static String? get idToken => _cachedIdToken;

  static Future<void> clearIdToken() async {
    final box = await _userBox;
    await box.delete(_idTokenKey);
    _cachedIdToken = null;
  }

  static const String _fcmTokenKey = 'fcmTokenValue';
  static String? _cachedFcmToken;

  static Future<void> setFCMToken(String token) async {
    final box = await _userBox;
    await box.put(_fcmTokenKey, token);
    _cachedFcmToken = token;
    debugPrint('🔔 FCM TOKEN SAVED TO HIVE: $token');
  }

  static Future<String?> getFCMToken() async {
    if (_cachedFcmToken != null) {
      return _cachedFcmToken;
    }

    final box = await _userBox;
    final token = box.get(_fcmTokenKey);
    _cachedFcmToken = token;

    if (token != null) {
      log('TOKEN :::: $token');
    } else {}

    return token;
  }

  static Future<void> printFCMToken() async {
    final token = await getFCMToken();
    if (token != null) {
      log('TOKEN :::::::::: $token');
    } else {}
  }

  static Future<void> setDeliveryBoyStatus(bool isOnline) async {
    final box = await _statusBox;
    await box.put(_statusKey, isOnline);
  }

  static Future<bool?> getDeliveryBoyStatus() async {
    final box = await _statusBox;
    return box.get(_statusKey) ?? false;
  }

  static bool? _cachedStatus;

  static Future<void> initializeStatus() async {
    final box = await _statusBox;
    _cachedStatus = box.get(_statusKey) ?? false;
  }

  static bool? get deliveryBoyStatus => _cachedStatus;

  static Future<void> debugTokenState() async {
    // final userBox = await _userBox;
    // final tokenFromBox = userBox.get(_tokenKey);
  }

  static Future<void> clearDeliveryBoyStatus() async {
    final box = await _statusBox;
    await box.delete(_statusKey);
    _cachedStatus = null;
  }
}
