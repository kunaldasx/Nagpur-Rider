import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nagpur_rider/config/global.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/repo/rider_popup_repo.dart';
import 'package:nagpur_rider/utils/services/order_alert_bridge.dart';

enum AlertAcceptPhase {
  idle,
  accepting,

  /// Couldn't reach the server: the alert keeps ringing, the rider retries.
  retry,

  /// The backend refused: the alert stopped, the rider reads why.
  unavailable,
}

class AlertAcceptState extends Equatable {
  final AlertAcceptPhase phase;
  final int? orderId;
  final String message;

  /// Bumped on each accepted order, for the caller to open it.
  final int acceptedVersion;
  final int? acceptedOrderId;

  const AlertAcceptState({
    this.phase = AlertAcceptPhase.idle,
    this.orderId,
    this.message = '',
    this.acceptedVersion = 0,
    this.acceptedOrderId,
  });

  bool get isShown => phase != AlertAcceptPhase.idle;

  AlertAcceptState copyWith({
    AlertAcceptPhase? phase,
    int? orderId,
    String? message,
    int? acceptedVersion,
    int? acceptedOrderId,
  }) => AlertAcceptState(
    phase: phase ?? this.phase,
    orderId: orderId ?? this.orderId,
    message: message ?? this.message,
    acceptedVersion: acceptedVersion ?? this.acceptedVersion,
    acceptedOrderId: acceptedOrderId ?? this.acceptedOrderId,
  );

  @override
  List<Object?> get props => [
    phase,
    orderId,
    message,
    acceptedVersion,
    acceptedOrderId,
  ];
}

/// Accepts the order of an incoming-order alert once the rider tapped
/// Accept on it (in the notification or on the native full-screen alert).
///
/// The alert only stops when the backend decides: accepted, or no longer
/// this rider's. Without a connection it keeps ringing and the rider retries.
class AlertAcceptCubit extends Cubit<AlertAcceptState> {
  final RiderPopupRepo _repo;

  AlertAcceptCubit({RiderPopupRepo? repo})
    : _repo = repo ?? RiderPopupRepo(),
      super(const AlertAcceptState());

  /// Returns the outcome, or null when an accept is already running (a
  /// duplicate tap).
  Future<AlertAcceptOutcome?> accept(int orderId) async {
    if (state.phase == AlertAcceptPhase.accepting) return null;
    emit(
      state.copyWith(
        phase: AlertAcceptPhase.accepting,
        orderId: orderId,
        message: '',
      ),
    );
    final result = await _repo.acceptFromAlert(orderId);
    if (isClosed) return result.outcome;
    switch (result.outcome) {
      case AlertAcceptOutcome.accepted:
        await OrderAlertBridge.stopAlert(orderId);
        emit(
          AlertAcceptState(
            acceptedVersion: state.acceptedVersion + 1,
            acceptedOrderId: orderId,
          ),
        );
        break;
      case AlertAcceptOutcome.unavailable:
        await OrderAlertBridge.stopAlert(orderId);
        emit(
          state.copyWith(
            phase: AlertAcceptPhase.unavailable,
            message: result.message,
          ),
        );
        break;
      case AlertAcceptOutcome.retry:
        emit(
          state.copyWith(
            phase: AlertAcceptPhase.retry,
            message: result.message,
          ),
        );
        break;
      case AlertAcceptOutcome.signedOut:
        // Same as the 401 handling in ApiBaseHelper.getApi. Clearing the
        // token also stops every alert (Global.clearUserToken).
        await Global.clearUserToken();
        await Global.clearIdToken();
        await Global.clearDeliveryBoyStatus();
        emit(
          AlertAcceptState(
            acceptedVersion: state.acceptedVersion,
            acceptedOrderId: state.acceptedOrderId,
          ),
        );
        break;
    }
    return result.outcome;
  }

  Future<void> retry() async {
    final orderId = state.orderId;
    if (orderId != null) await accept(orderId);
  }

  /// Hides the retry card. The alert keeps ringing until accepted.
  void dismiss() {
    if (state.phase == AlertAcceptPhase.accepting) return;
    emit(
      AlertAcceptState(
        acceptedVersion: state.acceptedVersion,
        acceptedOrderId: state.acceptedOrderId,
      ),
    );
  }
}
