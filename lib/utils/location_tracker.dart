import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

import '../screens/feed_page/repo/update_current_location.dart';

const locationDistanceFilterMeters = 10;
const locationStreamInterval = Duration(seconds: 10);
const locationGoodAccuracyMeters = 50.0;
const locationUsableAccuracyMeters = 100.0;
const locationMaxFixAge = Duration(seconds: 30);
const locationMovementMeters = 50.0;
const locationMaxSpeedMetersPerSecond = 40.0;
const locationJumpConfirmationMeters = 100.0;
const locationHeartbeatInterval = Duration(seconds: 60);
const locationCurrentFixTimeout = Duration(seconds: 10);
const locationDutyFixTimeout = Duration(seconds: 15);
const locationUploadTimeout = Duration(seconds: 15);
const locationStaleInterval = Duration(minutes: 2);
const locationRetrySeconds = [2, 4, 8, 16, 32, 60];
const _gpsNotificationId = 891;

/// Android's fused provider owns the foreground service; Dart keeps auth here.
LocationSettings dutyLocationSettings({TargetPlatform? platform}) {
  switch (platform ?? defaultTargetPlatform) {
    case TargetPlatform.android:
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: locationDistanceFilterMeters,
        intervalDuration: locationStreamInterval,
        forceLocationManager: false,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "You're online",
          notificationText: 'Sharing your location so you get nearby orders',
          setOngoing: true,
          enableWakeLock: true,
        ),
      );
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: locationDistanceFilterMeters,
        activityType: ActivityType.otherNavigation,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    default:
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: locationDistanceFilterMeters,
      );
  }
}

enum LocationHealthStatus {
  ok,
  backgroundDenied,
  permissionDenied,
  serviceOff,
  weakSignal,
  mockLocation,
  stale,
}

@immutable
class LocationHealth {
  final LocationHealthStatus status;
  final DateTime? lastSentAt;
  final double? lastAccuracyMeters;
  final DateTime? recordedAt;
  const LocationHealth({
    this.status = LocationHealthStatus.ok,
    this.lastSentAt,
    this.lastAccuracyMeters,
    this.recordedAt,
  });
}

/// Device access is injectable so tests never need GPS or platform channels.
abstract class RiderPositionSource {
  Future<bool> serviceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<void> requestBackgroundPermission();
  Stream<Position> positions();
  Stream<ServiceStatus> serviceStatuses();
  Future<Position> currentPosition();
}

class GeolocatorPositionSource implements RiderPositionSource {
  @override
  Future<bool> serviceEnabled() => Geolocator.isLocationServiceEnabled();
  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();
  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();
  @override
  Future<void> requestBackgroundPermission() async {
    await permissions.Permission.locationAlways.request();
  }

  @override
  Stream<Position> positions() =>
      Geolocator.getPositionStream(locationSettings: dutyLocationSettings());
  @override
  Stream<ServiceStatus> serviceStatuses() =>
      Geolocator.getServiceStatusStream();
  @override
  Future<Position> currentPosition() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: locationCurrentFixTimeout,
    ),
  );
}

class DutyLocationException implements Exception {
  final LocationHealthStatus status;
  final String message;
  const DutyLocationException(this.status, this.message);
  @override
  String toString() => message;
}

class LocationTracker {
  static final LocationTracker _instance = LocationTracker.withDependencies();
  factory LocationTracker() => _instance;

  LocationTracker.withDependencies({
    RiderPositionSource? source,
    UpdateCurrentLocationRepo? repo,
    Stream<bool>? connectivity,
    DateTime Function()? now,
    Timer Function(Duration, void Function())? timer,
    Timer Function(Duration, void Function(Timer))? periodicTimer,
    bool? releaseMode,
    Future<void> Function()? notifyGpsOff,
  }) : _source = source ?? GeolocatorPositionSource(),
       _repo = repo ?? UpdateCurrentLocationRepo(),
       _connectivity =
           connectivity ??
           Connectivity().onConnectivityChanged.map(
             (states) => states.any((s) => s != ConnectivityResult.none),
           ),
       _now = now ?? DateTime.now,
       _timerFactory = timer ?? Timer.new,
       _periodicFactory = periodicTimer ?? Timer.periodic,
       _releaseMode = releaseMode ?? kReleaseMode,
       _notifyGpsOff = notifyGpsOff ?? _showGpsOffNotification;

  final RiderPositionSource _source;
  final UpdateCurrentLocationRepo _repo;
  final Stream<bool> _connectivity;
  final DateTime Function() _now;
  final Timer Function(Duration, void Function()) _timerFactory;
  final Timer Function(Duration, void Function(Timer)) _periodicFactory;
  final bool _releaseMode;
  final Future<void> Function() _notifyGpsOff;
  final _health = ValueNotifier(const LocationHealth());
  ValueListenable<LocationHealth> get health => _health;
  bool get isTracking => _online;
  Position? get currentLocation => _accepted;
  Position? get lastWeakFix => _weak;

  Future<void> _operations = Future.value();
  StreamSubscription<Position>? _positions;
  StreamSubscription<ServiceStatus>? _services;
  StreamSubscription<bool>? _network;
  Timer? _heartbeatTimer, _retryTimer, _gateTimer;
  Completer<Position?>? _gate;
  bool _online = false, _backgroundAllowed = false, _gpsNotified = false;
  bool _allowed = false;
  int? _refreshingGeneration;
  int _generation = 0, _retryStep = 0;
  bool _sending = false, _activating = false;
  Position? _good, _usable, _accepted, _weak, _jump, _pending, _lastSent;
  DateTime? _lastUsableAt, _onlineAt;
  final Set<Position> _rejected = {};

  Future<T> _serialize<T>(Future<T> Function() action) {
    final next = _operations.then((_) => action());
    _operations = next.then<void>(
      (_) {},
      onError: (Object e, StackTrace s) {
        debugPrint('[LocationTracker] $e');
      },
    );
    return next;
  }

  static bool _granted(LocationPermission p) =>
      p == LocationPermission.always || p == LocationPermission.whileInUse;

  /// Only an explicit online tap may prompt. Cold starts/resumes never prompt.
  Future<void> checkDutyAccess({
    Future<bool> Function()? explainBackground,
  }) async {
    if (!await _source.serviceEnabled()) {
      _setHealth(LocationHealthStatus.serviceOff);
      throw const DutyLocationException(
        LocationHealthStatus.serviceOff,
        'Turn on location to go online',
      );
    }
    var permission = await _source.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _source.requestPermission();
    }
    if (!_granted(permission)) {
      _setHealth(LocationHealthStatus.permissionDenied);
      throw const DutyLocationException(
        LocationHealthStatus.permissionDenied,
        'Allow location access to go online',
      );
    }
    if (permission != LocationPermission.always &&
        explainBackground != null &&
        await explainBackground()) {
      try {
        await _source.requestBackgroundPermission();
        permission = await _source.checkPermission();
      } catch (e) {
        debugPrint('[LocationTracker] background permission: $e');
      }
    }
    _backgroundAllowed = permission == LocationPermission.always;
  }

  /// Opens the duty stream once, retaining it through the status API request.
  Future<Position?> prepareForDuty() async {
    late Future<Position?> fix;
    await _serialize(() async {
      await _reset();
      final generation = _generation;
      _allowed = true;
      _gate = Completer<Position?>();
      fix = _gate!.future;
      _gateTimer = _timerFactory(locationDutyFixTimeout, () {
        if (generation == _generation) _completeGate(_best);
      });
      try {
        _ensurePositions(generation);
      } catch (e) {
        debugPrint('[LocationTracker] $e');
        _completeGate(null);
      }
    });
    return fix;
  }

  Future<bool> startTracking() => _serialize(() async {
    if (_online) return true;
    _online = true;
    _activating = true;
    _onlineAt = _now();
    final generation = _generation;
    try {
      _services = _source.serviceStatuses().listen(
        (status) {
          if (generation != _generation || !_online) return;
          if (status == ServiceStatus.disabled) {
            _allowed = false;
            _clearFixes();
            _setHealth(LocationHealthStatus.serviceOff);
            if (!_gpsNotified) {
              _gpsNotified = true;
              _notifyGpsOff().catchError((Object e) {
                debugPrint('[LocationTracker] $e');
              });
            }
          } else {
            _gpsNotified = false;
            onResume();
          }
        },
        onError: (Object e) {
          debugPrint('[LocationTracker] $e');
        },
      );
      _network = _connectivity.listen(
        (connected) {
          if (generation != _generation || !_online || !connected) return;
          _retryTimer?.cancel();
          _retryTimer = null;
          if (_pending != null) {
            _drain();
          } else {
            _heartbeat(generation);
          }
        },
        onError: (Object e) {
          debugPrint('[LocationTracker] $e');
        },
      );
      _heartbeatTimer = _periodicFactory(
        locationHeartbeatInterval,
        (_) => _heartbeat(generation),
      );
      await _checkAccessAndStream(generation);
      _activating = false;
      if (generation == _generation && _allowed) {
        if (_best != null) {
          _enqueue(_best!);
        } else {
          _heartbeat(generation);
        }
      }
      return _online;
    } catch (e) {
      _activating = false;
      debugPrint('[LocationTracker] start failed: $e');
      _setHealth(LocationHealthStatus.weakSignal);
      return _online;
    }
  });

  Future<void> stopTracking() => _serialize(_reset);

  Future<void> _reset() async {
    _generation++;
    _online = false;
    _refreshingGeneration = null;
    _allowed = false;
    _heartbeatTimer?.cancel();
    _retryTimer?.cancel();
    _gateTimer?.cancel();
    _heartbeatTimer = _retryTimer = _gateTimer = null;
    _completeGate(null);
    final subscriptions = [_positions, _services, _network];
    _positions = null;
    _services = null;
    _network = null;
    for (final subscription in subscriptions) {
      try {
        await subscription?.cancel();
      } catch (e) {
        debugPrint('[LocationTracker] $e');
      }
    }
    _clearFixes();
    _lastSent = null;
    _retryStep = 0;
    _gpsNotified = false;
    _rejected.clear();
    _health.value = const LocationHealth();
    // An old upload may still complete; generation checks discard its result.
    // _sending remains true until it finishes, preventing overlapping requests.
  }

  void _clearFixes() {
    _good = _usable = _accepted = _weak = _jump = _pending = null;
    _lastUsableAt = null;
  }

  Future<void> _checkAccessAndStream(int generation) async {
    final service = await _source.serviceEnabled();
    final permission = await _source.checkPermission();
    if (generation != _generation) return;
    _backgroundAllowed = permission == LocationPermission.always;
    _allowed = service && _granted(permission);
    if (!_allowed) {
      _clearFixes();
      _setHealth(
        service
            ? LocationHealthStatus.permissionDenied
            : LocationHealthStatus.serviceOff,
      );
      return;
    }
    _ensurePositions(generation);
    _setHealth(
      _backgroundAllowed
          ? LocationHealthStatus.ok
          : LocationHealthStatus.backgroundDenied,
    );
  }

  void _ensurePositions(int generation) {
    if (_positions != null) return;
    _positions = _source.positions().listen(
      (p) {
        if (generation == _generation && _allowed) _onPosition(p);
      },
      onError: (Object e) {
        if (generation != _generation) return;
        debugPrint('[LocationTracker] stream: $e');
        final old = _positions;
        _positions = null;
        old?.cancel();
        if (_allowed) _setHealth(LocationHealthStatus.weakSignal);
      },
      onDone: () {
        if (generation == _generation) _positions = null;
      },
    );
  }

  void _completeGate(Position? position) {
    _gateTimer?.cancel();
    if (_gate != null && !_gate!.isCompleted) _gate!.complete(position);
    _gate = null;
  }

  Position? get _best =>
      _good ?? _usable ?? (_rejected.contains(_accepted) ? null : _accepted);

  bool _validate(Position p) {
    if (!p.latitude.isFinite ||
        !p.longitude.isFinite ||
        p.latitude.abs() > 90 ||
        p.longitude.abs() > 180 ||
        (p.latitude == 0 && p.longitude == 0) ||
        _now().difference(p.timestamp) > locationMaxFixAge ||
        !p.accuracy.isFinite ||
        p.accuracy < 0) {
      return false;
    }
    if (_releaseMode && p.isMocked) {
      _good = _usable = _accepted = _jump = _pending = null;
      _lastUsableAt = null;
      _setHealth(LocationHealthStatus.mockLocation);
      return false;
    }
    if (p.accuracy > locationUsableAccuracyMeters) {
      _weak = p;
      _setHealth(LocationHealthStatus.weakSignal);
      return false;
    }
    return true;
  }

  static double _distance(Position a, Position b) => Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );

  bool _onPosition(Position p, {bool sendMovement = true}) {
    if (!_validate(p)) return false;
    if (_jump != null) {
      final confirmed = _distance(_jump!, p) <= locationJumpConfirmationMeters;
      _jump = null;
      if (confirmed) {
        _acceptFix(p, sendMovement);
        return true;
      }
    }
    final previous = _accepted;
    if (previous != null && p.timestamp.isBefore(previous.timestamp)) {
      return false;
    }
    if (p.accuracy <= locationGoodAccuracyMeters && previous != null) {
      final elapsed =
          p.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
      final distance = _distance(previous, p);
      if (distance > locationJumpConfirmationMeters &&
          (elapsed <= 0 ||
              distance / elapsed > locationMaxSpeedMetersPerSecond)) {
        _jump = p;
        return false;
      }
    }
    _acceptFix(p, sendMovement);
    return true;
  }

  void _acceptFix(Position p, bool sendMovement) {
    _accepted = p;
    _lastUsableAt = _now();
    if (p.accuracy <= locationGoodAccuracyMeters) {
      _good = p;
    }
    if (_gate == null || _usable == null || p.accuracy <= _usable!.accuracy) {
      _usable = p;
    }
    _setHealth(
      _backgroundAllowed
          ? LocationHealthStatus.ok
          : LocationHealthStatus.backgroundDenied,
    );
    if (_gate != null && p.accuracy <= locationGoodAccuracyMeters) {
      _completeGate(p);
    }
    if (!_online || _activating) return;
    // While offline or uploading, keep exactly the newest fix, not a backlog.
    if (_pending != null || _sending) {
      _pending = p;
      return;
    }
    if (_refreshingGeneration == _generation && sendMovement) return;
    if (sendMovement &&
        (_lastSent == null ||
            _distance(_lastSent!, p) >= locationMovementMeters)) {
      _enqueue(_best!);
    }
  }

  Future<void> onResume() async {
    if (!_online) return;
    final generation = _generation;
    try {
      await _checkAccessAndStream(generation);
      if (generation == _generation && _allowed) await _heartbeat(generation);
    } catch (e) {
      debugPrint('[LocationTracker] resume: $e');
    }
  }

  Future<void> _heartbeat(int generation) async {
    if (!_online ||
        generation != _generation ||
        _refreshingGeneration == generation) {
      return;
    }
    _updateStaleness();
    _refreshingGeneration = generation;
    try {
      if (!_allowed) await _checkAccessAndStream(generation);
      if (!_allowed || generation != _generation) return;
      if (_lastUsableAt == null ||
          _now().difference(_lastUsableAt!) >= locationHeartbeatInterval) {
        final position = await _source.currentPosition().timeout(
          locationCurrentFixTimeout,
        );
        if (generation != _generation || !_online || !_allowed) return;
        if (!_onPosition(position, sendMovement: false)) {
          if (_health.value.status != LocationHealthStatus.mockLocation) {
            _setHealth(LocationHealthStatus.weakSignal);
          }
          return;
        }
      }
      if (_best case final best?) {
        _enqueue(best);
        _good = _usable = null;
      }
    } catch (e) {
      if (generation == _generation &&
          _allowed &&
          _health.value.status != LocationHealthStatus.mockLocation) {
        _setHealth(LocationHealthStatus.weakSignal);
      }
      debugPrint('[LocationTracker] fix: $e');
    } finally {
      if (_refreshingGeneration == generation) _refreshingGeneration = null;
      _updateStaleness();
    }
  }

  void _enqueue(Position p) {
    if (!_online || !_allowed || _rejected.contains(p)) return;
    _pending = p;
    _good = _usable = null;
    if (_retryTimer == null) _drain();
  }

  Future<void> _drain() async {
    if (_sending ||
        !_online ||
        !_allowed ||
        _pending == null ||
        _health.value.status == LocationHealthStatus.mockLocation) {
      return;
    }
    final position = _pending!;
    // Retrying an old point cannot make stale GPS look fresh at the backend.
    if (_now().difference(position.timestamp) > locationHeartbeatInterval) {
      _pending = null;
      _heartbeat(_generation);
      return;
    }
    _pending = null;
    _sending = true;
    final generation = _generation;
    bool retry = false;
    try {
      final response = await _repo
          .updateCurrentLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          )
          .timeout(locationUploadTimeout);
      if (generation != _generation || !_online || !_allowed) return;
      final status = response['statusCode'];
      final message = '${response['message']}'.toLowerCase();
      if (status == 401 || message.startsWith('unauthenticated')) {
        // ApiBaseHelper owns session expiry/navigation; do not invoke it twice.
        await stopTracking();
        return;
      }
      if (status == 422 || status == 403) {
        _rejected.add(position);
        if (_good == position) _good = null;
        if (_usable == position) _usable = null;
      } else if (response['success'] == true) {
        _lastSent = position;
        _retryStep = 0;
        final data = response['data'];
        _health.value = LocationHealth(
          status:
              _backgroundAllowed
                  ? LocationHealthStatus.ok
                  : LocationHealthStatus.backgroundDenied,
          lastSentAt: _now(),
          lastAccuracyMeters: position.accuracy,
          recordedAt:
              data is Map ? DateTime.tryParse('${data['recorded_at']}') : null,
        );
      } else {
        retry =
            !response.containsKey('success') ||
            (status is int && status >= 500);
        if (!retry) _rejected.add(position);
      }
    } catch (e) {
      retry = true;
      debugPrint('[LocationTracker] upload: $e');
    } finally {
      _sending = false;
      if (_online && generation == _generation) {
        if (retry) {
          _pending ??= position;
          final seconds =
              locationRetrySeconds[math.min(
                _retryStep,
                locationRetrySeconds.length - 1,
              )];
          _retryStep++;
          _retryTimer?.cancel();
          _retryTimer = _timerFactory(Duration(seconds: seconds), () {
            _retryTimer = null;
            if (generation == _generation) _drain();
          });
        } else if (_pending != null) {
          _drain();
        }
        _updateStaleness();
      } else if (_online && _pending != null) {
        _drain();
      }
    }
  }

  void _updateStaleness() {
    if (!_online) return;
    final last = _health.value.lastSentAt ?? _onlineAt;
    if (last != null &&
        _now().difference(last) >= locationStaleInterval &&
        !{
          LocationHealthStatus.serviceOff,
          LocationHealthStatus.permissionDenied,
          LocationHealthStatus.mockLocation,
        }.contains(_health.value.status)) {
      _setHealth(LocationHealthStatus.stale);
    }
  }

  void _setHealth(LocationHealthStatus status) {
    _health.value = LocationHealth(
      status: status,
      lastSentAt: _health.value.lastSentAt,
      lastAccuracyMeters: _health.value.lastAccuracyMeters,
      recordedAt: _health.value.recordedAt,
    );
  }

  static Future<void> _showGpsOffNotification() async {
    await FlutterLocalNotificationsPlugin().show(
      _gpsNotificationId,
      'GPS is off',
      "GPS is off. You won't get orders until you turn it on.",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'location_health',
          'Location status',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
