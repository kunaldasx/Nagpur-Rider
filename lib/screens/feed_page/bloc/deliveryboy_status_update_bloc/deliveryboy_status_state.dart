// delivery_boy_status_state.dart

import 'package:equatable/equatable.dart';
import '../../../../utils/location_tracker.dart';

abstract class DeliveryBoyStatusState extends Equatable {
  final bool isOnline;
  final bool isVerified;
  final String? message;

  const DeliveryBoyStatusState({
    required this.isOnline,
    this.isVerified = true,
    this.message,
  });

  @override
  List<Object?> get props => [isOnline, isVerified, message];
}

class DeliveryBoyStatusInitial extends DeliveryBoyStatusState {
  const DeliveryBoyStatusInitial() : super(isOnline: false, isVerified: true);
}

class DeliveryBoyStatusLoading extends DeliveryBoyStatusState {
  const DeliveryBoyStatusLoading({required super.isOnline, super.isVerified});
}

class DeliveryBoyStatusLoaded extends DeliveryBoyStatusState {
  final double? latitude;
  final double? longitude;

  const DeliveryBoyStatusLoaded({
    required super.isOnline,
    super.isVerified,
    this.latitude,
    this.longitude,
    super.message,
  });

  @override
  List<Object?> get props => [
    isOnline,
    isVerified,
    latitude,
    longitude,
    message,
  ];
}

class DeliveryBoyStatusError extends DeliveryBoyStatusState {
  final String errorMessage;
  final LocationHealthStatus? locationIssue;

  const DeliveryBoyStatusError(
    this.errorMessage, {
    required super.isOnline,
    super.isVerified,
    this.locationIssue,
  }) : super(message: errorMessage);

  @override
  List<Object?> get props => [
    isOnline,
    isVerified,
    errorMessage,
    message,
    locationIssue,
  ];
}
