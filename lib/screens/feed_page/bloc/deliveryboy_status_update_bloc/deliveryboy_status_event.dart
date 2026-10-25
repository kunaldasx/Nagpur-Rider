// delivery_boy_status_event.dart

import 'package:equatable/equatable.dart';

abstract class DeliveryBoyStatusEvent extends Equatable {
  const DeliveryBoyStatusEvent();

  @override
  List<Object?> get props => [];
}

class ToggleStatus extends DeliveryBoyStatusEvent {
  final bool isOnline;

  final Future<bool> Function()? explainBackground;
  const ToggleStatus(this.isOnline, {this.explainBackground});

  @override
  List<Object?> get props => [isOnline];
}

class SyncInitialStatus extends DeliveryBoyStatusEvent {
  final bool isOnline;
  const SyncInitialStatus(this.isOnline);
}

class CheckApiStatus extends DeliveryBoyStatusEvent {
  const CheckApiStatus();
}
