import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/return_order/accept_return_order_bloc/return_order_bloc.dart'
    as accept;
import 'package:nagpur_rider/screens/feed_page/bloc/return_order/update_return_order_status_bloc/update_return_order_status_bloc.dart';

import 'support/fake_return_order_repo.dart';

Future<List<UpdateReturnOrderStatusState>> update(
  UpdateReturnOrderStatusBloc bloc, {
  String status = 'picked_up',
  String otp = '012345',
}) async {
  final states = <UpdateReturnOrderStatusState>[];
  final subscription = bloc.stream.listen(states.add);
  final done = bloc.stream.firstWhere(
    (s) =>
        s is ReturnOrderStatusCompleted || s is UpdateReturnOrderStatusFailed,
  );
  bloc.add(UpdateReturnOrderStatus(returnId: '731', status: status, otp: otp));
  await done;
  await subscription.cancel();
  return states;
}

void main() {
  test(
    'customer and seller handoffs preserve OTP strings and updated resources',
    () async {
      final repo = FakeReturnOrderRepo();
      final bloc = UpdateReturnOrderStatusBloc(repository: repo);
      addTearDown(bloc.close);
      final customer = await update(bloc);
      final seller = await update(
        bloc,
        status: 'delivered_to_seller',
        otp: '007890',
      );
      expect(repo.updates.map((u) => u.otp), ['012345', '007890']);
      expect(
        customer
            .whereType<UpdateReturnOrderStatusSuccess>()
            .single
            .pickup
            .pickupStatus,
        'picked_up',
      );
      expect(
        seller
            .whereType<UpdateReturnOrderStatusSuccess>()
            .single
            .pickup
            .pickupStatus,
        'delivered_to_seller',
      );
      expect(
        seller
            .whereType<UpdateReturnOrderStatusSuccess>()
            .single
            .pickup
            .store!
            .name,
        'Seller',
      );
    },
  );

  test('missing or malformed OTP never reaches the server', () async {
    final repo = FakeReturnOrderRepo();
    final bloc = UpdateReturnOrderStatusBloc(repository: repo);
    addTearDown(bloc.close);
    for (final otp in ['', '12345', '1234567', '12ab56']) {
      final states = await update(bloc, otp: otp);
      expect(states.last, isA<UpdateReturnOrderStatusFailed>());
      expect(states.whereType<UpdateReturnOrderStatusSuccess>(), isEmpty);
    }
    expect(repo.updates, isEmpty);
  });

  test(
    'wrong OTP and SMS failure leave the return uncompleted and retryable',
    () async {
      final repo = FakeReturnOrderRepo();
      final bloc = UpdateReturnOrderStatusBloc(repository: repo);
      addTearDown(bloc.close);
      for (final code in ['invalid_otp', 'otp_delivery_failed']) {
        repo.update = (_) async => returnFailure(code, 'Please try again');
        final states = await update(bloc);
        expect((states.last as UpdateReturnOrderStatusFailed).code, code);
        expect(states.whereType<UpdateReturnOrderStatusSuccess>(), isEmpty);
        expect(states.whereType<ReturnOrderStatusCompleted>(), isEmpty);
      }
      repo.update = null;
      expect(
        (await update(bloc)).whereType<UpdateReturnOrderStatusSuccess>(),
        hasLength(1),
      );
    },
  );

  test(
    'invalid transition fetches the actual pickup without reporting verification',
    () async {
      final repo =
          FakeReturnOrderRepo()
            ..update =
                (_) async =>
                    returnFailure('invalid_transition', 'Status changed');
      final bloc = UpdateReturnOrderStatusBloc(repository: repo);
      addTearDown(bloc.close);
      final failure =
          (await update(bloc)).last as UpdateReturnOrderStatusFailed;
      expect(repo.detailCalls, 1);
      expect(failure.code, 'invalid_transition');
      expect(failure.pickup!.pickupStatus, 'picked_up');
    },
  );

  test(
    'failed reconciliation and network errors never fabricate an updated pickup',
    () async {
      final repo = FakeReturnOrderRepo();
      repo.update =
          (_) async => returnFailure('invalid_transition', 'Status changed');
      repo.details = () async => throw Exception('offline');
      final bloc = UpdateReturnOrderStatusBloc(repository: repo);
      addTearDown(bloc.close);
      expect(
        ((await update(bloc)).last as UpdateReturnOrderStatusFailed).pickup,
        isNull,
      );
      repo.update = (_) async => throw Exception('offline');
      expect((await update(bloc)).last, isA<UpdateReturnOrderStatusFailed>());
    },
  );

  test('repeated submit while waiting sends one request', () async {
    final pending = Completer<Map<String, dynamic>>();
    final repo = FakeReturnOrderRepo()..update = (_) => pending.future;
    final bloc = UpdateReturnOrderStatusBloc(repository: repo);
    addTearDown(bloc.close);
    final loading = bloc.stream.firstWhere(
      (s) => s is UpdateReturnOrderStatusLoading,
    );
    bloc.add(
      UpdateReturnOrderStatus(
        returnId: '731',
        status: 'picked_up',
        otp: '012345',
      ),
    );
    await loading;
    bloc.add(
      UpdateReturnOrderStatus(
        returnId: '731',
        status: 'picked_up',
        otp: '012345',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repo.updates, hasLength(1));
    final completed = bloc.stream.firstWhere(
      (s) => s is ReturnOrderStatusCompleted,
    );
    pending.complete(pickupResponse('picked_up'));
    await completed;
  });

  test('OTP is excluded from event logging', () {
    expect(
      UpdateReturnOrderStatus(
        returnId: '731',
        status: 'picked_up',
        otp: '012345',
      ).toString(),
      isNot(contains('012345')),
    );
  });

  test('accept uses the assigned pickup returned by the server', () async {
    final repo = FakeReturnOrderRepo();
    final bloc = accept.ReturnOrderBloc(repository: repo);
    addTearDown(bloc.close);
    final result = bloc.stream.firstWhere(
      (s) => s is accept.AcceptReturnOrderSuccess,
    );
    bloc.add(accept.AcceptReturnOrder(returnId: '731'));
    final state = await result as accept.AcceptReturnOrderSuccess;
    expect(state.pickup.pickupStatus, 'assigned');
    expect(state.pickup.order!.shippingPhone, '+919999999999');
  });

  test('accept SMS and network failures emit errors and allow retry', () async {
    final repo =
        FakeReturnOrderRepo()
          ..accept =
              () async => returnFailure(
                'otp_delivery_failed',
                'Could not send pickup OTP',
              );
    final bloc = accept.ReturnOrderBloc(repository: repo);
    addTearDown(bloc.close);
    Future<accept.ReturnOrderError> attempt() async {
      final result = bloc.stream.firstWhere(
        (s) => s is accept.ReturnOrderError,
      );
      bloc.add(accept.AcceptReturnOrder(returnId: '731'));
      return await result as accept.ReturnOrderError;
    }

    expect((await attempt()).errorMessage, 'Could not send pickup OTP');
    repo.accept = () async => throw Exception('offline');
    expect((await attempt()).errorMessage, contains('try again'));
    expect(repo.acceptCalls, 2);
  });
}
