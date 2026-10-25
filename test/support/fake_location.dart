import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:nagpur_rider/screens/feed_page/repo/update_current_location.dart';
import 'package:nagpur_rider/screens/feed_page/repo/deliveryboy_status.dart';
import 'package:nagpur_rider/utils/location_tracker.dart';

Position riderPosition(
  DateTime time, {
  double meters = 0,
  double accuracy = 30,
  double? latitude,
  double? longitude,
  bool mocked = false,
}) => Position(
  latitude: latitude ?? 21.1458 + meters / 111195,
  longitude: longitude ?? 79.0882,
  timestamp: time,
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: mocked,
);

class FakePositionSource implements RiderPositionSource {
  FakePositionSource(this.now) {
    fixes = StreamController<Position>.broadcast(
      sync: true,
      onListen: () {
        activeStreams++;
        maxStreams = activeStreams > maxStreams ? activeStreams : maxStreams;
      },
      onCancel: () {
        activeStreams--;
      },
    );
  }
  final DateTime Function() now;
  late final StreamController<Position> fixes;
  final service = StreamController<ServiceStatus>.broadcast(sync: true);
  bool enabled = true;
  LocationPermission permission = LocationPermission.always;
  LocationPermission requestedPermission = LocationPermission.denied;
  int streamCalls = 0, currentCalls = 0, activeStreams = 0, maxStreams = 0;
  int permissionRequests = 0, backgroundRequests = 0;
  Future<Position> Function()? current;
  void emit({
    double meters = 0,
    double accuracy = 30,
    DateTime? time,
    double? latitude,
    double? longitude,
    bool mocked = false,
  }) {
    fixes.add(
      riderPosition(
        time ?? now(),
        meters: meters,
        accuracy: accuracy,
        latitude: latitude,
        longitude: longitude,
        mocked: mocked,
      ),
    );
  }

  void setService(bool value) {
    enabled = value;
    service.add(value ? ServiceStatus.enabled : ServiceStatus.disabled);
  }

  @override
  Future<bool> serviceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return permission = requestedPermission;
  }

  @override
  Future<void> requestBackgroundPermission() async {
    backgroundRequests++;
  }

  @override
  Stream<Position> positions() {
    streamCalls++;
    return FakeClockStream(fixes.stream);
  }

  @override
  Stream<ServiceStatus> serviceStatuses() => FakeClockStream(service.stream);
  @override
  Future<Position> currentPosition() async {
    currentCalls++;
    return current != null ? current!() : riderPosition(now());
  }
}

class FakeLocationRepo extends UpdateCurrentLocationRepo {
  FakeLocationRepo(this.now);
  final DateTime Function() now;
  final List<({double? latitude, double? longitude, DateTime at})> sends = [];
  Future<Map<String, dynamic>> Function()? upload;
  @override
  Future<Map<String, dynamic>> updateCurrentLocation({
    double? latitude,
    double? longitude,
  }) async {
    sends.add((latitude: latitude, longitude: longitude, at: now()));
    return upload != null
        ? upload!()
        : {
          'success': true,
          'data': {'recorded_at': now().toIso8601String()},
        };
  }
}

class FakeDutyRepo extends DeliveryBoyStatusRepo {
  final List<({bool active, double? latitude, double? longitude})> calls = [];
  Future<Map<String, dynamic>> Function(bool active)? update;
  @override
  Future<Map<String, dynamic>> updateDeliveryBoyStatus({
    required bool isOnline,
    double? latitude,
    double? longitude,
  }) async {
    calls.add((active: isOnline, latitude: latitude, longitude: longitude));
    return update != null ? update!(isOnline) : {'success': true};
  }
}

/// SDK broadcast cancellation can return a future bound to the test runner's
/// zone. Keep fake cancellations in the injected clock's zone.
class FakeClockStream<T> extends Stream<T> {
  FakeClockStream(this.stream);
  final Stream<T> stream;
  @override
  StreamSubscription<T> listen(
    void Function(T)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _FakeSubscription(
    stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    ),
  );
}

class _FakeSubscription<T> implements StreamSubscription<T> {
  _FakeSubscription(this.delegate);
  final StreamSubscription<T> delegate;
  @override
  Future<void> cancel() {
    delegate.cancel();
    return Future<void>.value();
  }

  @override
  void onData(void Function(T)? handler) => delegate.onData(handler);
  @override
  void onError(Function? handler) => delegate.onError(handler);
  @override
  void onDone(void Function()? handler) => delegate.onDone(handler);
  @override
  void pause([Future<void>? resumeSignal]) => delegate.pause(resumeSignal);
  @override
  void resume() => delegate.resume();
  @override
  bool get isPaused => delegate.isPaused;
  @override
  Future<E> asFuture<E>([E? futureValue]) => delegate.asFuture<E>(futureValue);
}
