part of 'return_order_bloc.dart';

abstract class ReturnOrderState extends Equatable {
  @override
  List<Object> get props => [];
}

class ReturnOrderInitial extends ReturnOrderState {}

class ReturnOrderLoading extends ReturnOrderState {}

class AcceptReturnOrderSuccess extends ReturnOrderState {
  final String message;
  final String returnId; // useful for UI to remove/update specific item
  final Pickups pickup;

  AcceptReturnOrderSuccess({
    required this.message,
    required this.returnId,
    required this.pickup,
  });
}

class ReturnOrderError extends ReturnOrderState {
  final String errorMessage;

  ReturnOrderError(this.errorMessage);
}

class ReturnOrderActionCompleted extends ReturnOrderState {
  final String returnId;

  ReturnOrderActionCompleted(this.returnId);
}
