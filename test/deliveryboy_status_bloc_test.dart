import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';
import 'package:nagpur_rider/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart';
import 'package:nagpur_rider/utils/location_tracker.dart';
import 'support/fake_location.dart';

class _Rig {
  _Rig(this.time) {
    source = FakePositionSource(now);
    upload = FakeLocationRepo(now);
    tracker = LocationTracker.withDependencies(
      source: source,
      repo: upload,
      now: now,
      connectivity: FakeClockStream(const Stream<bool>.empty()),
      notifyGpsOff: () async {},
    );
    bloc = DeliveryBoyStatusBloc(
      locationTracker: tracker,
      repo: repo,
      saveStatus: (active) async {
        saved.add(active);
      },
    );
  }
  final FakeAsync time;
  late final FakePositionSource source;
  late final FakeLocationRepo upload;
  final repo = FakeDutyRepo();
  final saved = <bool>[];
  late final LocationTracker tracker;
  late final DeliveryBoyStatusBloc bloc;
  DateTime now() => DateTime.utc(2026, 10, 25).add(time.elapsed);
  void flush() => time.flushMicrotasks();
  void online() {
    bloc.add(const ToggleStatus(true));
    flush();
  }

  void good() {
    source.emit();
    flush();
  }

  void close() {
    bloc.close();
    tracker.stopTracking();
    flush();
  }
}

void _scenario(void Function(_Rig) body) => fakeAsync((time) {
  final r = _Rig(time);
  body(r);
  r.close();
});

void main() {
  test(
    'GPS off stays offline with fix action and never calls API',
    () => _scenario((r) {
      r.source.enabled = false;
      r.online();
      expect(r.bloc.state.isOnline, isFalse);
      expect(
        (r.bloc.state as DeliveryBoyStatusError).errorMessage,
        'Turn on location to go online',
      );
      expect(
        (r.bloc.state as DeliveryBoyStatusError).locationIssue,
        LocationHealthStatus.serviceOff,
      );
      expect(r.repo.calls, isEmpty);
    }),
  );
  for (final permission in [
    LocationPermission.denied,
    LocationPermission.deniedForever,
  ]) {
    test(
      '$permission stays offline without API',
      () => _scenario((r) {
        r.source.permission = permission;
        r.online();
        expect(r.bloc.state.isOnline, isFalse);
        expect(
          (r.bloc.state as DeliveryBoyStatusError).errorMessage,
          'Allow location access to go online',
        );
        expect(r.repo.calls, isEmpty);
        expect(
          r.source.permissionRequests,
          permission == LocationPermission.denied ? 1 : 0,
        );
      }),
    );
  }
  test(
    'no usable fix waits 15 seconds then stays offline and stops stream',
    () => _scenario((r) {
      r.online();
      r.source.emit(accuracy: 120);
      r.flush();
      r.time.elapse(const Duration(seconds: 14));
      r.flush();
      expect(r.bloc.state, isA<DeliveryBoyStatusLoading>());
      r.time.elapse(const Duration(seconds: 1));
      r.flush();
      expect(
        (r.bloc.state as DeliveryBoyStatusError).errorMessage,
        'Weak GPS signal. Move to an open area and try again.',
      );
      expect(r.repo.calls, isEmpty);
      expect(r.source.activeStreams, 0);
    }),
  );
  test(
    'usable fix used only at deadline, best usable retained',
    () => _scenario((r) {
      r.online();
      r.source.emit(accuracy: 80);
      r.source.emit(accuracy: 90);
      r.flush();
      expect(r.repo.calls, isEmpty);
      r.time.elapse(const Duration(seconds: 15));
      r.flush();
      expect(r.repo.calls.single.active, isTrue);
      expect(r.tracker.health.value.lastAccuracyMeters, 80);
      expect(r.tracker.isTracking, isTrue);
    }),
  );
  test(
    'good fix activates API before tracker first heartbeat, with one reused stream',
    () => _scenario((r) {
      r.repo.update = (active) async {
        expect(r.tracker.isTracking, isFalse);
        expect(r.upload.sends, isEmpty);
        return {'success': true};
      };
      r.online();
      r.good();
      expect(r.repo.calls.single.active, isTrue);
      expect(r.repo.calls.single.latitude, 21.1458);
      expect(r.repo.calls.single.longitude, 79.0882);
      expect(r.bloc.state.isOnline, isTrue);
      expect(r.tracker.isTracking, isTrue);
      expect(r.source.streamCalls, 1);
      expect(r.upload.sends, hasLength(1));
    }),
  );
  test(
    'failed active API stays offline and cancels prepared stream',
    () => _scenario((r) {
      r.repo.update =
          (_) async => {'success': false, 'message': 'No delivery zone'};
      r.online();
      r.good();
      expect(r.bloc.state.isOnline, isFalse);
      expect(r.tracker.isTracking, isFalse);
      expect(r.source.activeStreams, 0);
      expect(r.upload.sends, isEmpty);
      expect(r.saved, isEmpty);
    }),
  );
  test(
    'inactive API runs before stop; failure keeps tracking',
    () => _scenario((r) {
      r.online();
      r.good();
      r.repo.update = (active) async {
        expect(active, isFalse);
        expect(r.tracker.isTracking, isTrue);
        return {'success': false, 'message': 'Offline failed'};
      };
      r.bloc.add(const ToggleStatus(false));
      r.flush();
      expect(r.bloc.state.isOnline, isTrue);
      expect(r.tracker.isTracking, isTrue);
      r.repo.update = (active) async {
        expect(r.tracker.isTracking, isTrue);
        return {'success': true};
      };
      r.bloc.add(const ToggleStatus(false));
      r.flush();
      expect(r.bloc.state.isOnline, isFalse);
      expect(r.tracker.isTracking, isFalse);
      expect(r.source.activeStreams, 0);
    }),
  );
  test(
    'closing bloc leaves duty tracker running',
    () => _scenario((r) {
      r.online();
      r.good();
      r.bloc.close();
      r.flush();
      expect(r.tracker.isTracking, isTrue);
      expect(r.source.activeStreams, 1);
      r.time.elapse(const Duration(seconds: 60));
      r.flush();
      expect(r.upload.sends, hasLength(2));
    }),
  );
  test(
    'background explanation precedes prompt and refusal still allows online',
    () => _scenario((r) {
      r.source.permission = LocationPermission.whileInUse;
      r.bloc.add(
        ToggleStatus(
          true,
          explainBackground: () async {
            expect(r.source.backgroundRequests, 0);
            return false;
          },
        ),
      );
      r.flush();
      r.good();
      expect(r.bloc.state.isOnline, isTrue);
      expect(r.source.backgroundRequests, 0);
      expect(
        r.tracker.health.value.status,
        LocationHealthStatus.backgroundDenied,
      );
    }),
  );
  test(
    'background explanation approval requests background permission',
    () => _scenario((r) {
      r.source.permission = LocationPermission.whileInUse;
      r.bloc.add(
        ToggleStatus(
          true,
          explainBackground: () async {
            expect(r.source.backgroundRequests, 0);
            return true;
          },
        ),
      );
      r.flush();
      r.good();
      expect(r.source.backgroundRequests, 1);
      expect(r.bloc.state.isOnline, isTrue);
    }),
  );
  test(
    'rapid duplicate online taps do not create duplicate streams',
    () => _scenario((r) {
      r.online();
      r.bloc.add(const ToggleStatus(true));
      r.flush();
      r.good();
      expect(r.repo.calls, hasLength(1));
      expect(r.source.streamCalls, 1);
    }),
  );
}
