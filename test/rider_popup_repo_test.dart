import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nagpur_rider/config/api_base_helper.dart';
import 'package:nagpur_rider/config/api_routes.dart' as routes;
import 'package:nagpur_rider/config/global.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/repo/rider_popup_repo.dart';
import 'support/rider_popup_sample.dart';

class _LocalHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String acceptUrl, availableUrl;
  setUp(() async {
    acceptUrl = routes.acceptOrderApi;
    availableUrl = routes.availableOrdersStatusApi;
    FlutterSecureStorage.setMockInitialValues({
      'userToken': 'test-rider-token',
    });
    await Global.initializeToken();
  });
  tearDown(() {
    routes.acceptOrderApi = acceptUrl;
    routes.availableOrdersStatusApi = availableUrl;
  });

  Future<void> backend(
    int status,
    Object body,
    Future<void> Function(RiderPopupRepo) run,
  ) => HttpOverrides.runWithHttpOverrides(() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    routes.acceptOrderApi = 'http://127.0.0.1:${server.port}/orders';
    routes.availableOrdersStatusApi = '${routes.acceptOrderApi}/available';
    server.listen((request) async {
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer test-rider-token',
      );
      if (request.uri.path.endsWith('/scan-bag')) {
        expect(jsonDecode(await utf8.decoder.bind(request).join()), {
          'barcode': 'WRONG',
        });
      } else {
        await request.drain<void>();
      }
      if (request.method == 'GET') {
        expect(request.uri.queryParameters['order_mode'], 'regular');
      }
      request.response.statusCode = status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(body));
      await request.response.close();
    });
    try {
      await run(RiderPopupRepo());
    } finally {
      await server.close(force: true);
    }
  }, _LocalHttp());

  for (final status in [409, 404, 422]) {
    test(
      'accept $status is unavailable and retains exact server message',
      () => backend(
        status,
        {
          'success': false,
          'message': 'This order is no longer assigned to you.',
        },
        (repo) async {
          final result = await repo.acceptFromAlert(8801);
          expect(result.outcome, AlertAcceptOutcome.unavailable);
          expect(result.message, 'This order is no longer assigned to you.');
          await expectLater(
            repo.accept(8801),
            throwsA(
              isA<OfferAcceptException>()
                  .having(
                    (e) => e.result.outcome,
                    'outcome',
                    AlertAcceptOutcome.unavailable,
                  )
                  .having((e) => e.errorMessage, 'message', result.message),
            ),
          );
        },
      ),
    );
  }
  for (final body in [
    {'success': false, 'message': 'No longer assigned'},
    {'message': 'Server Error'},
  ]) {
    test(
      '500 is retry even if body says success false: $body',
      () => backend(500, body, (repo) async {
        expect(
          (await repo.acceptFromAlert(8801)).outcome,
          AlertAcceptOutcome.retry,
        );
      }),
    );
  }
  test(
    'missing success is retry',
    () => backend(200, {'message': 'Problem'}, (repo) async {
      expect(
        (await repo.acceptFromAlert(8801)).outcome,
        AlertAcceptOutcome.retry,
      );
    }),
  );
  test(
    'scan-bag 422 throws server message',
    () => backend(
      422,
      {
        'success': false,
        'message': 'This bag is not assigned to the scanned order.',
      },
      (repo) async {
        await expectLater(
          repo.scanBag(8801, 'WRONG'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.errorMessage,
              'message',
              'This bag is not assigned to the scanned order.',
            ),
          ),
        );
      },
    ),
  );
  test(
    'documented available sample parses; no bag or preparing item filtered',
    () async {
      final sample =
          jsonDecode(jsonEncode(availableOrdersSample)) as Map<String, dynamic>;
      final orders = sample['data']['orders'] as List;
      orders.add({...orders.first as Map, 'id': 8802, 'seller_orders': []});
      orders.add({...orders.first as Map, 'id': 8803, 'items': []});
      await backend(200, sample, (repo) async {
        final orders = await repo.availableOrders();
        expect(orders, hasLength(1));
        expect(orders.single.orderNumber, 'NM-20260930-AB3XK9ZM');
        expect(
          orders.single.baggedSellerOrders.single.bag!.barcode,
          'BAG-000033',
        );
        expect(orders.single.customerName, 'Customer Name');
      });
    },
  );
}
