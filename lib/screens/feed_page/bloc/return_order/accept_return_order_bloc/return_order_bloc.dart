import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:nagpur_rider/config/api_base_helper.dart';
import 'package:nagpur_rider/screens/feed_page/repo/return_order_repo.dart';
import 'package:nagpur_rider/screens/feed_page/model/return_orders_list_model.dart';

part 'return_order_event.dart';
part 'return_order_state.dart';

class ReturnOrderBloc extends Bloc<ReturnOrderEvent, ReturnOrderState> {
  final ReturnOrderRepo _repo;
  bool _isAccepting = false;

  ReturnOrderBloc({ReturnOrderRepo? repository})
    : _repo = repository ?? ReturnOrderRepo(),
      super(ReturnOrderInitial()) {
    on<AcceptReturnOrder>(_onAcceptReturnOrder);
  }

  Future<void> _onAcceptReturnOrder(
    AcceptReturnOrder event,
    Emitter<ReturnOrderState> emit,
  ) async {
    if (_isAccepting) return;
    _isAccepting = true;
    try {
      emit(ReturnOrderLoading());

      final response = await _repo.acceptReturnOrder(event.returnId);

      if (response['success'] == true) {
        final String message =
            response['message'] ?? 'Return order accepted successfully';

        emit(
          AcceptReturnOrderSuccess(
            message: message,
            returnId: event.returnId,
            pickup: ReturnOrderRepo.pickupFromResponse(
              response,
              event.returnId,
            ),
          ),
        );

        emit(ReturnOrderActionCompleted(event.returnId));
      } else {
        emit(
          ReturnOrderError(
            response['message'] ?? 'Failed to accept return order',
          ),
        );
      }
    } on ApiException catch (e) {
      emit(
        ReturnOrderError(
          kDebugMode ? "Network error: $e" : "Network error. Please try again.",
        ),
      );
    } catch (e) {
      emit(ReturnOrderError("Something went wrong. Please try again."));
    } finally {
      _isAccepting = false;
    }
  }
}
