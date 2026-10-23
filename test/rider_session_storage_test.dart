import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nagpur_rider/config/global.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDirectory;
  const secureStorage = FlutterSecureStorage();

  setUp(() async {
    storageDirectory = await Directory.systemTemp.createTemp('rider-session-');
    Hive.init(storageDirectory.path);
    FlutterSecureStorage.setMockInitialValues({});
    await Global.clearSession();
  });

  tearDown(() async {
    await Global.clearSession();
    await Hive.close();
    await storageDirectory.delete(recursive: true);
  });

  test(
    'migrates a legacy token into secure storage and removes Hive copy',
    () async {
      final box = await Hive.openBox('UserDataBox');
      await box.put('userToken', 'legacy-token');

      await Global.initializeToken();

      expect(Global.userToken, 'legacy-token');
      expect(await secureStorage.read(key: 'userToken'), 'legacy-token');
      expect(box.containsKey('userToken'), isFalse);
    },
  );

  test('stores new tokens securely without writing them to Hive', () async {
    await Global.setUserToken('rider-token');

    expect(await Global.getUserToken(), 'rider-token');
    expect(Global.userToken, 'rider-token');
    expect(await secureStorage.read(key: 'userToken'), 'rider-token');
    final box = await Hive.openBox('UserDataBox');
    expect(box.containsKey('userToken'), isFalse);
  });

  test('compares expiry instants in UTC and clears optional expiry', () async {
    expect(await Global.isUserTokenExpired(), isFalse);
    await Global.setUserTokenExpiresAt('2000-01-01T05:30:00+05:30');
    expect(await Global.getUserTokenExpiresAt(), DateTime.utc(2000));
    expect(await Global.isUserTokenExpired(), isTrue);
    await Global.setUserTokenExpiresAt('2999-01-01T00:00:00Z');
    expect(await Global.isUserTokenExpired(), isFalse);
    await Global.setUserTokenExpiresAt(null);
    expect(await secureStorage.read(key: 'userTokenExpiresAt'), isNull);
    await Global.setUserTokenExpiresAt('2999-01-01T00:00:00Z');
    await Global.setUserTokenExpiresAt('');
    expect(await Global.getUserTokenExpiresAt(), isNull);
  });

  test(
    'clears secure and legacy credentials, cached token and rider status',
    () async {
      await Global.setUserToken('rider-token');
      await Global.setUserTokenExpiresAt('2999-01-01T00:00:00Z');
      await Global.setIdToken('firebase-token');
      await Global.setDeliveryBoyStatus(true);
      final box = await Hive.openBox('UserDataBox');
      await box.put('userToken', 'stale-legacy-token');

      await Global.clearSession();

      expect(await secureStorage.readAll(), isEmpty);
      expect(await Global.getUserToken(), isNull);
      expect(Global.userToken, isNull);
      expect(await Global.getIdToken(), isNull);
      expect(await Global.getDeliveryBoyStatus(), isFalse);
      expect(box.containsKey('userToken'), isFalse);
    },
  );
}
