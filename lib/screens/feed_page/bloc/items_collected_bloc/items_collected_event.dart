import 'package:equatable/equatable.dart';

abstract class ItemsCollectedEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ItemsCollected extends ItemsCollectedEvent {
  final String orderItemId;

  ItemsCollected(this.orderItemId);

  @override
  List<Object> get props => [orderItemId];
}

class ItemsCollectedWithOtp extends ItemsCollectedEvent {
  final String orderItemId;
  final String otp;
  final bool cashCollected;

  ItemsCollectedWithOtp({
    required this.orderItemId,
    required this.otp,
    this.cashCollected = false,
  });

  @override
  List<Object> get props => [orderItemId, otp, cashCollected];
}

class ItemsDelivered extends ItemsCollectedEvent {
  final String orderItemId;
  final bool cashCollected;

  ItemsDelivered(this.orderItemId, {this.cashCollected = false});

  @override
  List<Object> get props => [orderItemId, cashCollected];
}
