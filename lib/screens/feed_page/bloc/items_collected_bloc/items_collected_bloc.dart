import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/api_base_helper.dart';

import '../../repo/items_collected.dart';
import 'items_collected_event.dart';
import 'items_collected_state.dart';

class ItemsCollectedBloc
    extends Bloc<ItemsCollectedEvent, ItemsCollectedState> {
  ItemsCollectedBloc() : super(ItemsCollectedInitial()) {
    on<ItemsCollected>((event, emit) => _onItemsCollected(event, emit));
    on<ItemsCollectedWithOtp>(
      (event, emit) => _onItemsCollectedWithOtp(event, emit),
    );
    on<ItemsDelivered>((event, emit) => _onItemsDelivered(event, emit));
  }

  Future<void> _onItemsCollected(
    ItemsCollected event,
    Emitter<ItemsCollectedState> emit,
  ) async {
    try {
      emit(ItemsCollectedLoading(event.orderItemId));

      final response = await ItemsCollectedRepo().itemsCollected(
        event.orderItemId,
      );

      // Check if success is true OR if message contains "already has this status"
      bool isSuccess = response['success'] == true;
      String message = response['message'] ?? 'Failed to collect items';
      bool isAlreadyCollected = message.contains('already has this status');

      if (isSuccess || isAlreadyCollected) {
        // Both cases should be treated as success
        String successMessage = isAlreadyCollected ? 'Item already collected' : (response['message'] ?? 'Items collected successfully');
        emit(ItemsCollectedSuccess(successMessage, event.orderItemId));

      } else {
        emit(ItemsCollectedError(message, event.orderItemId));
      }
    } on ApiException catch (e) {
      emit(ItemsCollectedError("Error: $e", event.orderItemId));
    } catch (e) {
      emit(ItemsCollectedError("Unexpected error: $e", event.orderItemId));
    }
  }

  Future<void> _onItemsCollectedWithOtp(
    ItemsCollectedWithOtp event,
    Emitter<ItemsCollectedState> emit,
  ) async {
    try {
      emit(ItemsCollectedLoading(event.orderItemId));

      final response = await ItemsCollectedRepo().itemsDelivered(
        event.orderItemId,
        event.otp,
        cashCollected: event.cashCollected,
      );

      // Check if success is true OR if message contains "already has this status"
      bool isSuccess = response['success'] == true;
      String message = response['message'] ?? 'Failed to collect item with OTP';
      bool isAlreadyCollected = message.contains('already has this status');

      if (isSuccess || isAlreadyCollected) {
        // Both cases should be treated as success
        String successMessage = isAlreadyCollected ? 'Item already delivered' : (response['message'] ?? 'Item collected with OTP successfully');
        emit(ItemsCollectedSuccess(successMessage, event.orderItemId));
      } else {
        emit(ItemsCollectedError(message, event.orderItemId));
      }
    } on ApiException catch (e) {
      emit(ItemsCollectedError("Error: $e", event.orderItemId));
    } catch (e) {
      emit(ItemsCollectedError("Unexpected error: $e", event.orderItemId));
    }
  }

  Future<void> _onItemsDelivered(
    ItemsDelivered event,
    Emitter<ItemsCollectedState> emit,
  ) async {
    try {
      emit(ItemsCollectedLoading(event.orderItemId));

      final response = await ItemsCollectedRepo().itemsDelivered(
        event.orderItemId,
        null,
        cashCollected: event.cashCollected,
      );

      // Check if success is true OR if message contains "already has this status"
      bool isSuccess = response['success'] == true;
      String message = response['message'] ?? 'Failed to deliver item';
      bool isAlreadyDelivered = message.contains('already has this status');

      if (isSuccess || isAlreadyDelivered) {
        // Both cases should be treated as success
        String successMessage = isAlreadyDelivered ? 'Item already delivered' : (response['message'] ?? 'Item delivered successfully');
        emit(ItemsCollectedSuccess(successMessage, event.orderItemId));
      } else {
        emit(ItemsCollectedError(message, event.orderItemId));
      }
    } on ApiException catch (e) {
      emit(ItemsCollectedError("Error: $e", event.orderItemId));
    } catch (e) {
      emit(ItemsCollectedError("Unexpected error: $e", event.orderItemId));
    }
  }
}
