part of 'update_return_order_status_bloc.dart';

abstract class UpdateReturnOrderStatusState extends Equatable {
  @override
  List<Object?> get props => [];
}

final class UpdateReturnOrderStatusInitial
    extends UpdateReturnOrderStatusState {}

final class UpdateReturnOrderStatusLoading
    extends UpdateReturnOrderStatusState {}

final class UpdateReturnOrderStatusSuccess
    extends UpdateReturnOrderStatusState {
  final String message;
  final String returnId;
  final Pickups pickup;

  UpdateReturnOrderStatusSuccess({
    required this.message,
    required this.returnId,
    required this.pickup,
  });
}

final class UpdateReturnOrderStatusFailed extends UpdateReturnOrderStatusState {
  final String error;
  final String? code;
  final Pickups? pickup;
  UpdateReturnOrderStatusFailed(this.error, {this.code, this.pickup});
}

class ReturnOrderStatusCompleted extends UpdateReturnOrderStatusState {
  final String returnId;

  ReturnOrderStatusCompleted(this.returnId);
}
