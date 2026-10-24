import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagpur_rider/config/api_routes.dart' as routes;
import 'package:nagpur_rider/config/global.dart';
import 'package:nagpur_rider/screens/feed_page/repo/return_order_repo.dart';

import 'support/fake_return_order_repo.dart';

// Only these tests use real HTTP, against a local fake backend.
class _LocalHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String originalStatusUrl;
  late String originalAcceptUrl;

  setUp(() async {
    originalStatusUrl = routes.updateReturnOrderApi;
    originalAcceptUrl = routes.acceptReturnOrderApi;
    FlutterSecureStorage.setMockInitialValues({
      'userToken': 'test-rider-token',
    });
    await Global.initializeToken();
  });

  tearDown(() {
    routes.updateReturnOrderApi = originalStatusUrl;
    routes.acceptReturnOrderApi = originalAcceptUrl;
  });

  test(
    'both handoffs send authenticated JSON OTP strings without logging them',
    () async {
      final logs = <String>[];
      final originalPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) logs.add(message);
      };
      addTearDown(() => debugPrint = originalPrint);
      await HttpOverrides.runWithHttpOverrides(() async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        routes.updateReturnOrderApi =
            'http://127.0.0.1:${server.port}/return-pickups/';
        final requests = <Map<String, dynamic>>[];
        final headers = <String?>[];
        server.listen((request) async {
          expect(request.method, 'PUT');
          expect(request.uri.path, '/return-pickups/731/status');
          expect(request.headers.contentType!.mimeType, 'application/json');
          headers.add(request.headers.value(HttpHeaders.authorizationHeader));
          final body =
              jsonDecode(await utf8.decoder.bind(request).join())
                  as Map<String, dynamic>;
          requests.add(body);
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(pickupResponse(body['status'] as String)),
          );
          await request.response.close();
        });
        final repo = ReturnOrderRepo();
        await repo.updateReturnOrderStatus('731', 'picked_up', otp: '012345');
        await repo.updateReturnOrderStatus(
          '731',
          'delivered_to_seller',
          otp: '007890',
        );
        expect(requests, [
          {'status': 'picked_up', 'otp': '012345'},
          {'status': 'delivered_to_seller', 'otp': '007890'},
        ]);
        expect(headers, everyElement('Bearer test-rider-token'));
      }, _LocalHttp());
      expect(logs.join('\n'), isNot(contains('012345')));
      expect(logs.join('\n'), isNot(contains('007890')));
      expect(logs.join('\n'), contains('Body: [REDACTED]'));
    },
  );

  test(
    'HTTP validation and SMS errors retain their backend codes and messages',
    () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        final url = 'http://127.0.0.1:${server.port}/return-pickups/';
        routes.updateReturnOrderApi = url;
        routes.acceptReturnOrderApi = url;
        server.listen((request) async {
          await request.drain<void>();
          final accepting = request.uri.path.endsWith('/accept');
          request.response.statusCode = accepting ? 503 : 422;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(
              returnFailure(
                accepting ? 'otp_delivery_failed' : 'invalid_otp',
                accepting ? 'Could not send pickup OTP' : 'Invalid OTP',
              ),
            ),
          );
          await request.response.close();
        });
        final repo = ReturnOrderRepo();
        final invalid = await repo.updateReturnOrderStatus(
          '731',
          'picked_up',
          otp: '111111',
        );
        expect(invalid['success'], isFalse);
        expect(invalid['data']['error'], 'invalid_otp');
        final failedSms = await repo.acceptReturnOrder('731');
        expect(failedSms['success'], isFalse);
        expect(failedSms['data']['error'], 'otp_delivery_failed');
        expect(failedSms['message'], 'Could not send pickup OTP');
      }, _LocalHttp());
    },
  );
}
