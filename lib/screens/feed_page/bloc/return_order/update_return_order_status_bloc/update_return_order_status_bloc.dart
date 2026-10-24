import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:nagpur_rider/config/api_base_helper.dart';
import 'package:nagpur_rider/screens/feed_page/repo/return_order_repo.dart';
import 'package:nagpur_rider/screens/feed_page/model/return_orders_list_model.dart';

part 'update_return_order_status_event.dart';
part 'update_return_order_status_state.dart';

class UpdateReturnOrderStatusBloc
    extends Bloc<UpdateReturnOrderStatusEvent, UpdateReturnOrderStatusState> {
  final ReturnOrderRepo _repo;
  bool _isUpdating = false;

  UpdateReturnOrderStatusBloc({ReturnOrderRepo? repository})
    : _repo = repository ?? ReturnOrderRepo(),
      super(UpdateReturnOrderStatusInitial()) {
    on<UpdateReturnOrderStatus>(_onUpdateReturnOrderStatus);
  }

  Future<void> _onUpdateReturnOrderStatus(
    UpdateReturnOrderStatus event,
    Emitter<UpdateReturnOrderStatusState> emit,
  ) async {
    if (_isUpdating) return;
    _isUpdating = true;
    try {
      emit(UpdateReturnOrderStatusLoading());

      if (!RegExp(r'^[0-9]{6}$').hasMatch(event.otp)) {
        emit(
          UpdateReturnOrderStatusFailed(
            'Enter a valid six-digit OTP.',
            code: 'invalid_otp',
          ),
        );
        return;
      }

      final response = await _repo.updateReturnOrderStatus(
        event.returnId,
        event.status,
        otp: event.otp,
      );

      if (response['success'] == true) {
        final String message =
            response['message'] ?? 'Status updated successfully';

        emit(
          UpdateReturnOrderStatusSuccess(
            message: message,
            returnId: event.returnId,
            pickup: ReturnOrderRepo.pickupFromResponse(
              response,
              event.returnId,
            ),
          ),
        );

        emit(ReturnOrderStatusCompleted(event.returnId));
      } else {
        final code =
            response['data'] is Map
                ? response['data']['error'] as String?
                : null;
        Pickups? currentPickup;
        if (code == 'invalid_transition') {
          try {
            final details = await _repo.getReturnPickupsDetails(event.returnId);
            if (details['success'] == true) {
              currentPickup = ReturnOrderRepo.pickupFromResponse(
                details,
                event.returnId,
              );
            }
          } catch (_) {
            // Keep the current step when reconciliation is unavailable.
          }
        }
        emit(
          UpdateReturnOrderStatusFailed(
            response['message'] ?? 'Failed to update status',
            code: code,
            pickup: currentPickup,
          ),
        );
      }
    } on ApiException catch (e) {
      emit(
        UpdateReturnOrderStatusFailed(
          kDebugMode ? "Network error: $e" : "Network error. Please try again.",
        ),
      );
    } catch (e) {
      emit(
        UpdateReturnOrderStatusFailed(
          "Something went wrong. Please try again.",
        ),
      );
    } finally {
      _isUpdating = false;
    }
  }
}
