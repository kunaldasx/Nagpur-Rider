import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nagpur_rider/utils/location_tracker.dart';
import 'support/fake_location.dart';

class _Rig {
  _Rig(this.async, {bool release = false}) {
    source = FakePositionSource(now);
    repo = FakeLocationRepo(now);
    tracker = LocationTracker.withDependencies(
      source: source,
      repo: repo,
      connectivity: FakeClockStream(network.stream),
      now: now,
      releaseMode: release,
      notifyGpsOff: () async {
        notifications++;
      },
    );
  }
  final FakeAsync async;
  final network = StreamController<bool>.broadcast(sync: true);
  late final FakePositionSource source;
  late final FakeLocationRepo repo;
  late final LocationTracker tracker;
  int notifications = 0;
  DateTime now() => DateTime.utc(2026, 10, 25).add(async.elapsed);
  void flush() => async.flushMicrotasks();
  void start() {
    tracker.startTracking();
    flush();
  }

  void stop() {
    tracker.stopTracking();
    flush();
  }

  void tick(int seconds) {
    async.elapse(Duration(seconds: seconds));
    flush();
  }
}

void _scenario(void Function(_Rig) body, {bool release = false}) =>
    fakeAsync((async) {
      final r = _Rig(async, release: release);
      body(r);
      r.stop();
      expect(r.source.activeStreams, 0);
      expect(async.periodicTimerCount, 0);
    });

void main() {
  test(
    'start sends exactly once; stationary sends every 60 seconds',
    () => _scenario((r) {
      r.start();
      expect(r.repo.sends, hasLength(1));
      expect(r.tracker.health.value.recordedAt, r.now());
      expect(r.source.activeStreams, 1);
      r.tick(59);
      expect(r.repo.sends, hasLength(1));
      r.tick(1);
      expect(r.repo.sends, hasLength(2));
      r.tick(60);
      expect(r.repo.sends, hasLength(3));
    }),
  );
  test(
    '30 m does not send; 60 m sends immediately as doubles',
    () => _scenario((r) {
      r.start();
      r.tick(10);
      r.source.emit(meters: 30);
      r.flush();
      expect(r.repo.sends, hasLength(1));
      r.tick(10);
      r.source.emit(meters: 60);
      r.flush();
      expect(r.repo.sends, hasLength(2));
      expect(r.repo.sends.last.latitude, isA<double>());
      expect(r.repo.sends.last.longitude, isA<double>());
    }),
  );
  test(
    '120 m never uploads; newest good is preferred to newer usable in window',
    () => _scenario((r) {
      r.start();
      r.tick(10);
      r.source.emit(accuracy: 120);
      r.flush();
      expect(r.repo.sends, hasLength(1));
      expect(r.tracker.lastWeakFix!.accuracy, 120);
      r.tick(10);
      r.source.emit(meters: 5, accuracy: 30);
      r.flush();
      r.tick(10);
      r.source.emit(meters: 10, accuracy: 80);
      r.flush();
      r.tick(30);
      expect(r.repo.sends, hasLength(2));
      expect(
        r.repo.sends.last.latitude,
        closeTo(riderPosition(r.now(), meters: 5).latitude, 0.000001),
      );
    }),
  );
  test(
    '80 m uploads when it is the best available',
    () => _scenario((r) {
      r.source.current = () async => riderPosition(r.now(), accuracy: 80);
      r.start();
      expect(r.repo.sends, hasLength(1));
      expect(r.tracker.health.value.lastAccuracyMeters, 80);
    }),
  );
  for (final invalid in ['old', 'zero', 'nan', 'latitude', 'longitude']) {
    test(
      'drops $invalid coordinates',
      () => _scenario((r) {
        r.start();
        r.tick(10);
        r.source.emit(
          time:
              invalid == 'old'
                  ? r.now().subtract(const Duration(minutes: 2))
                  : null,
          latitude: switch (invalid) {
            'zero' => 0,
            'nan' => double.nan,
            'latitude' => 91,
            _ => null,
          },
          longitude: switch (invalid) {
            'zero' => 0,
            'longitude' => -181,
            _ => null,
          },
        );
        r.flush();
        expect(r.repo.sends, hasLength(1));
      }),
    );
  }
  test(
    'release mocks are dropped and health reports mockLocation',
    () => _scenario((r) {
      r.start();
      r.tick(10);
      r.source.emit(meters: 60, mocked: true);
      r.flush();
      expect(r.repo.sends, hasLength(1));
      expect(r.tracker.health.value.status, LocationHealthStatus.mockLocation);
    }, release: true),
  );
  test(
    'debug allows emulator mocked positions',
    () => _scenario((r) {
      r.start();
      r.tick(10);
      r.source.emit(meters: 60, mocked: true);
      r.flush();
      expect(r.repo.sends, hasLength(2));
    }),
  );
  test(
    'spike held, original spot rejects it, confirming new area accepts',
    () => _scenario((r) {
      r.start();
      r.tick(5);
      r.source.emit(meters: 2000);
      r.flush();
      expect(r.repo.sends, hasLength(1));
      r.tick(5);
      r.source.emit();
      r.flush();
      expect(r.repo.sends, hasLength(1));
      r.tick(5);
      r.source.emit(meters: 2000);
      r.flush();
      expect(r.repo.sends, hasLength(1));
      r.tick(5);
      r.source.emit(meters: 2020);
      r.flush();
      expect(r.repo.sends, hasLength(2));
    }),
  );
  test(
    'no usable fix for 60 seconds requests current once; bad fallback not sent',
    () => _scenario((r) {
      r.start();
      final before = r.source.currentCalls;
      r.source.current = () async => riderPosition(r.now(), accuracy: 120);
      r.tick(60);
      expect(r.source.currentCalls, before + 1);
      expect(r.repo.sends, hasLength(1));
      expect(r.tracker.health.value.status, LocationHealthStatus.weakSignal);
    }),
  );
  test(
    'three fixes during upload coalesce to newest',
    () => _scenario((r) {
      final pending = Completer<Map<String, dynamic>>();
      r.repo.upload = () => pending.future;
      r.start();
      r.tick(10);
      for (final meters in [10.0, 20.0, 30.0]) {
        r.source.emit(meters: meters);
      }
      r.repo.upload = null;
      pending.complete({'success': true});
      r.flush();
      expect(r.repo.sends, hasLength(2));
      expect(
        r.repo.sends.last.latitude,
        riderPosition(r.now(), meters: 30).latitude,
      );
    }),
  );
  test(
    'bounded backoff retains newest and resets after success',
    () => _scenario((r) {
      r.repo.upload = () async => throw Exception('offline');
      r.start();
      for (final seconds in [2, 4, 8, 16, 32, 60, 60]) {
        final before = r.repo.sends.length;
        r.tick(seconds - 1);
        r.source.emit(meters: r.async.elapsed.inSeconds.toDouble());
        r.flush();
        expect(r.repo.sends, hasLength(before));
        r.tick(1);
        expect(r.repo.sends, hasLength(before + 1));
      }
      r.repo.upload = null;
      r.network.add(true);
      r.flush();
      r.repo.upload = () async => throw Exception('offline again');
      r.tick(10);
      r.source.emit(meters: 300);
      r.flush();
      final before = r.repo.sends.length;
      r.tick(1);
      expect(r.repo.sends, hasLength(before));
      r.tick(1);
      expect(r.repo.sends, hasLength(before + 1));
    }),
  );
  test(
    'connectivity restoration retries immediately with newest only',
    () => _scenario((r) {
      r.repo.upload = () async => throw Exception('offline');
      r.start();
      r.tick(1);
      r.source.emit(meters: 10);
      r.flush();
      r.repo.upload = null;
      r.network.add(true);
      r.flush();
      expect(r.repo.sends, hasLength(2));
      expect(
        r.repo.sends.last.latitude,
        riderPosition(r.now(), meters: 10).latitude,
      );
    }),
  );
  test(
    '401 stops subscriptions timers and all future sends',
    () => _scenario((r) {
      r.repo.upload =
          () async => {'statusCode': 401, 'message': 'Unauthenticated'};
      r.start();
      expect(r.tracker.isTracking, isFalse);
      expect(r.source.activeStreams, 0);
      expect(r.async.periodicTimerCount, 0);
      r.tick(180);
      r.source.emit();
      r.network.add(true);
      r.flush();
      expect(r.repo.sends, hasLength(1));
    }),
  );
  for (final code in [422, 403]) {
    test(
      '$code drops coordinate; new fix can upload',
      () => _scenario((r) {
        r.repo.upload = () async => {'success': false, 'statusCode': code};
        r.start();
        r.tick(10);
        expect(r.repo.sends, hasLength(1));
        r.repo.upload = null;
        r.network.add(true);
        r.flush();
        expect(r.repo.sends, hasLength(1));
        r.source.emit(meters: 10);
        r.flush();
        expect(r.repo.sends, hasLength(2));
      }),
    );
  }
  test(
    'service off gives health and one notification; recovery sends immediately',
    () => _scenario((r) {
      r.start();
      r.source.setService(false);
      r.flush();
      expect(r.tracker.health.value.status, LocationHealthStatus.serviceOff);
      expect(r.tracker.isTracking, isTrue);
      r.source.setService(false);
      r.flush();
      expect(r.notifications, 1);
      r.source.fixes.addError(Exception('GPS disabled'));
      r.flush();
      expect(r.tracker.health.value.status, LocationHealthStatus.serviceOff);
      r.source.emit(meters: 100);
      r.flush();
      expect(r.repo.sends, hasLength(1));
      r.source.setService(true);
      r.flush();
      expect(r.repo.sends, hasLength(2));
    }),
  );
  test(
    'resume online sends immediately; offline does nothing',
    () => _scenario((r) {
      r.start();
      r.tracker.onResume();
      r.flush();
      expect(r.repo.sends, hasLength(2));
      r.stop();
      r.tracker.onResume();
      r.flush();
      expect(r.repo.sends, hasLength(2));
    }),
  );
  test(
    'permission revocation on resume blocks; restoration sends',
    () => _scenario((r) {
      r.start();
      r.source.permission = LocationPermission.deniedForever;
      r.tracker.onResume();
      r.flush();
      expect(
        r.tracker.health.value.status,
        LocationHealthStatus.permissionDenied,
      );
      expect(r.source.permissionRequests, 0);
      r.source.permission = LocationPermission.whileInUse;
      r.tracker.onResume();
      r.flush();
      expect(r.repo.sends, hasLength(2));
      expect(
        r.tracker.health.value.status,
        LocationHealthStatus.backgroundDenied,
      );
    }),
  );
  test(
    'start stop start serialized; one stream timer; final stop silences callbacks',
    () => _scenario((r) {
      r.tracker.startTracking();
      r.tracker.stopTracking();
      r.tracker.startTracking();
      r.flush();
      expect(r.source.activeStreams, 1);
      expect(r.source.maxStreams, 1);
      expect(r.async.periodicTimerCount, 1);
      r.tracker.startTracking();
      r.flush();
      expect(r.source.activeStreams, 1);
      r.stop();
      final before = r.repo.sends.length;
      r.tick(180);
      r.source.emit();
      r.flush();
      expect(r.repo.sends, hasLength(before));
    }),
  );
  test(
    'network outage becomes stale after two minutes',
    () => _scenario((r) {
      r.repo.upload = () async => throw Exception('offline');
      r.start();
      r.tick(120);
      expect(r.tracker.health.value.status, LocationHealthStatus.stale);
    }),
  );
  test(
    'cold start never prompts and GPS recovery starts one stream',
    () => _scenario((r) {
      r.source.enabled = false;
      r.start();
      expect(r.source.permissionRequests, 0);
      expect(r.source.streamCalls, 0);
      expect(r.tracker.health.value.status, LocationHealthStatus.serviceOff);
      r.source.setService(true);
      r.flush();
      expect(r.source.streamCalls, 1);
      expect(r.repo.sends, hasLength(1));
    }),
  );
  test(
    'weak initial fix is never uploaded',
    () => _scenario((r) {
      r.source.current = () async => riderPosition(r.now(), accuracy: 120);
      r.start();
      expect(r.repo.sends, isEmpty);
      expect(r.tracker.health.value.status, LocationHealthStatus.weakSignal);
    }),
  );
  test(
    'mock release fixes cannot leak through resume or heartbeat',
    () => _scenario((r) {
      r.start();
      r.tick(10);
      r.source.current = () async => riderPosition(r.now(), mocked: true);
      r.source.emit(mocked: true);
      r.flush();
      r.tracker.onResume();
      r.flush();
      r.tick(60);
      expect(r.repo.sends, hasLength(1));
      expect(r.tracker.health.value.status, LocationHealthStatus.mockLocation);
    }, release: true),
  );
  test(
    'upload finishing after GPS off cannot overwrite blocking health',
    () => _scenario((r) {
      final uploading = Completer<Map<String, dynamic>>();
      r.repo.upload = () => uploading.future;
      r.start();
      r.source.setService(false);
      r.flush();
      uploading.complete({'success': true});
      r.flush();
      expect(r.tracker.health.value.status, LocationHealthStatus.serviceOff);
    }),
  );
  test(
    'stop while current fix is pending cannot leak callbacks into restart',
    () => _scenario((r) {
      final oldFix = Completer<Position>();
      r.source.current = () => oldFix.future;
      r.start();
      r.stop();
      r.source.current = null;
      r.start();
      expect(r.source.activeStreams, 1);
      expect(r.repo.sends, hasLength(1));
      oldFix.complete(riderPosition(r.now(), meters: 1000));
      r.flush();
      expect(r.repo.sends, hasLength(1));
    }),
  );
  test(
    'map listener receives live fixes and closing it leaves duty running',
    () => _scenario((r) {
      r.start();
      final mapFixes = <Position>[];
      final map = r.source.positions().listen(mapFixes.add);
      r.tick(10);
      r.source.emit(meters: 60);
      r.flush();
      expect(mapFixes, hasLength(1));
      map.cancel();
      r.flush();
      r.tick(10);
      r.source.emit(meters: 120);
      r.flush();
      expect(mapFixes, hasLength(1));
      expect(r.repo.sends, hasLength(3));
      expect(r.tracker.isTracking, isTrue);
    }),
  );
  test(
    'current-position timeout cannot overwrite GPS-off health',
    () => _scenario((r) {
      final fix = Completer<Position>();
      r.source.current = () => fix.future;
      r.start();
      r.source.setService(false);
      r.flush();
      r.tick(10);
      expect(r.tracker.health.value.status, LocationHealthStatus.serviceOff);
      expect(r.repo.sends, isEmpty);
    }),
  );
  test(
    'platform settings retain foreground notification and iOS background flags',
    () {
      final android =
          dutyLocationSettings(platform: TargetPlatform.android)
              as AndroidSettings;
      expect(android.accuracy, LocationAccuracy.high);
      expect(android.foregroundNotificationConfig!.enableWakeLock, isTrue);
      expect(android.foregroundNotificationConfig!.setOngoing, isTrue);
      expect(android.forceLocationManager, isFalse);
      final apple =
          dutyLocationSettings(platform: TargetPlatform.iOS) as AppleSettings;
      expect(apple.allowBackgroundLocationUpdates, isTrue);
      expect(apple.pauseLocationUpdatesAutomatically, isFalse);
      expect(apple.showBackgroundLocationIndicator, isTrue);
    },
  );
}
