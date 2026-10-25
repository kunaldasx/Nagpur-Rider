import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nagpur_rider/config/global.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/cubit/rider_popup_cubit.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/model/rider_popup_order.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/repo/rider_popup_repo.dart';
import 'support/fake_rider_popup_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late FakeRiderPopupRepo repo;
  late RiderPopupCubit cubit;
  late List<int> stopped;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rider-popup-test');
    Hive.init(directory.path);
    FlutterSecureStorage.setMockInitialValues({
      'userToken': 'test-rider-token',
    });
    await Global.initializeToken();
    await Global.setDeliveryBoyStatus(true);
    repo = FakeRiderPopupRepo();
    stopped = [];
    cubit = RiderPopupCubit(
      repo: repo,
      stopAlert: (id) async {
        stopped.add(id);
      },
    );
  });
  tearDown(() async {
    await cubit.close();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test('offer persists across polls until accepted', () async {
    await cubit.fetch();
    final order = cubit.state.available.single;
    await cubit.fetch();
    expect(cubit.state.available.single.id, order.id);
    expect(await cubit.accept(order), isTrue);
    expect(cubit.state.available, isEmpty);
    expect(cubit.state.accepted.single.id, order.id);
    await cubit.fetch();
    expect(cubit.state.available, isEmpty);
  });
  test(
    '409 refusal removes card, stops alert and shows exact server message',
    () async {
      repo.result = const AlertAcceptResult(
        AlertAcceptOutcome.unavailable,
        'This order is no longer assigned to you.',
      );
      await cubit.fetch();
      final order = cubit.state.available.single;
      expect(await cubit.accept(order), isFalse);
      expect(cubit.state.available, isEmpty);
      expect(
        cubit.state.errorMessage,
        'This order is no longer assigned to you.',
      );
      expect(stopped, [order.id]);
      await cubit.fetch();
      expect(cubit.state.available, isEmpty);
    },
  );
  test('network retry retains card and ring', () async {
    repo.result = const AlertAcceptResult(
      AlertAcceptOutcome.retry,
      'No internet',
    );
    await cubit.fetch();
    final order = cubit.state.available.single;
    expect(await cubit.accept(order), isFalse);
    expect(cubit.state.available.single.id, order.id);
    expect(stopped, isEmpty);
  });
  for (final reason in ['reassigned', 'cancelled']) {
    test('withdrawn $reason removes card immediately with reason', () async {
      await cubit.fetch();
      final order = cubit.state.available.single;
      await cubit.offerWithdrawn(order.id, reason);
      expect(cubit.state.available, isEmpty);
      expect(
        cubit.state.errorMessage,
        reason == 'reassigned' ? 'Order reassigned' : 'Order cancelled',
      );
      expect(stopped, [order.id]);
    });
  }
  test(
    'accepted withdrawal re-reads assignment and removes old rider card',
    () async {
      await cubit.fetch();
      final order = cubit.state.available.single;
      await cubit.accept(order);
      final before = repo.detailCalls;
      repo.detail = popupOrder(riderId: 77);
      await cubit.offerWithdrawn(order.id, 'reassigned');
      expect(repo.detailCalls, before + 1);
      expect(cubit.state.accepted, isEmpty);
      expect(cubit.state.errorMessage, 'Order reassigned');
    },
  );
  test(
    'accepted order retained when detail still confirms same rider',
    () async {
      await cubit.openAccepted(8801);
      await cubit.offerWithdrawn(8801, 'reassigned');
      expect(cubit.state.accepted, hasLength(1));
    },
  );
  test('late fetch cannot resurrect withdrawn offer', () async {
    await cubit.fetch();
    final pending = Completer<List<RiderPopupOrder>>();
    repo.fetch = () => pending.future;
    final fetching = cubit.fetch();
    await Future<void>.delayed(Duration.zero);
    await cubit.offerWithdrawn(8801, 'cancelled');
    pending.complete(repo.offers);
    await fetching;
    expect(cubit.state.available, isEmpty);
  });
}
