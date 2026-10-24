part of 'update_return_order_status_bloc.dart';

abstract class UpdateReturnOrderStatusEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

final class UpdateReturnOrderStatus extends UpdateReturnOrderStatusEvent {
  final String returnId;
  final String status;
  final String otp;

  UpdateReturnOrderStatus({
    required this.status,
    required this.returnId,
    required this.otp,
  });

  @override
  List<Object?> get props => [returnId, status, otp];

  // OTPs must not appear in observer/event logs.
  @override
  bool get stringify => false;
}
