import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/api_base_helper.dart';
import '../../../../config/api_routes.dart';
import '../../../../config/global.dart';
import '../../../../utils/location_tracker.dart';
import '../../repo/deliveryboy_status.dart';
import 'deliveryboy_status_event.dart';
import 'deliveryboy_status_state.dart';

class DeliveryBoyStatusBloc
    extends Bloc<DeliveryBoyStatusEvent, DeliveryBoyStatusState> {
  final LocationTracker _locationTracker;
  final DeliveryBoyStatusRepo _deliveryBoyStatusRepo;
  final Future<void> Function(bool) _saveStatus;
  bool _isProcessing = false;
  bool _isCheckingApi = false;

  DeliveryBoyStatusBloc({
    LocationTracker? locationTracker,
    DeliveryBoyStatusRepo? repo,
    Future<void> Function(bool)? saveStatus,
  }) : _locationTracker = locationTracker ?? LocationTracker(),
       _deliveryBoyStatusRepo = repo ?? DeliveryBoyStatusRepo(),
       _saveStatus = saveStatus ?? Global.setDeliveryBoyStatus,
       super(DeliveryBoyStatusInitial()) {
    on<SyncInitialStatus>(_onSyncInitialStatus);
    on<CheckApiStatus>(_onCheckApiStatus);
    on<ToggleStatus>(_onToggleStatus);
  }

  Future<void> _onSyncInitialStatus(
    SyncInitialStatus event,
    Emitter<DeliveryBoyStatusState> emit,
  ) async {
    try {
      if (_isProcessing) return;
      // Emit the local status immediately
      emit(DeliveryBoyStatusLoaded(isOnline: event.isOnline));

      // Start location services if online
      if (event.isOnline && (Global.userToken ?? '').trim().isNotEmpty) {
        _locationTracker.startTracking();
      }
    } catch (e) {
      emit(
        DeliveryBoyStatusError(
          'Failed to sync initial status: ${e.toString()}',
          isOnline: state.isOnline,
        ),
      );
    }
  }

  Future<void> _onCheckApiStatus(
    CheckApiStatus event,
    Emitter<DeliveryBoyStatusState> emit,
  ) async {
    if (_isCheckingApi) {
      return;
    }

    _isCheckingApi = true;

    try {
      if (_isProcessing) return;
      await Global.refreshCachedToken();

      Map<String, dynamic> response;

      // First try the profile endpoint
      try {
        response = await ApiBaseHelper.getApi(
          url: deliveryBoyProfileApi,
          useAuthToken: true,
          params: {},
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
              'Profile endpoint timed out after 10 seconds',
            );
          },
        );
      } catch (e) {
        // Fallback to status endpoint if profile fails
        response = await ApiBaseHelper.getApi(
          url: deliveryBoyStatusApi,
          useAuthToken: true,
          params: {},
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException(
              'Status endpoint also timed out after 5 seconds',
            );
          },
        );
      }

      if (response['success'] == true) {
        if (_isProcessing) return;
        bool isOnline = false;
        bool isVerified = true;

        if (response['data'] != null) {
          // Try to get status from different possible locations
          isOnline =
              response['data']?['is_online'] ??
              response['data']?['delivery_boy']?['status'] == 'active' ??
              response['data']?['delivery_boy']?['is_online'] ??
              false;
        }

        emit(
          DeliveryBoyStatusLoaded(isOnline: isOnline, isVerified: isVerified),
        );

        // Update local storage
        await Global.setDeliveryBoyStatus(isOnline);

        // Start/stop location services based on API status
        if (isOnline) {
          _locationTracker.startTracking();
        } else {
          _locationTracker.stopTracking();
        }
      } else {
        // Explicitly check for verification error
        final String? message = response['message'];
        final bool isUnverified =
            message != null &&
            message.toLowerCase().contains('not been verified yet');

        if (isUnverified) {
          emit(
            DeliveryBoyStatusLoaded(
              isOnline: false,
              isVerified: false,
              message: message,
            ),
          );
          // Also force local status to offline for unverified accounts
          await Global.setDeliveryBoyStatus(false);
          return;
        }

        emit(
          DeliveryBoyStatusError(
            response['message'] ?? 'Failed to check status',
            isOnline: state.isOnline,
            isVerified: state.isVerified,
          ),
        );
      }
    } catch (e) {
      emit(
        DeliveryBoyStatusError(
          'Failed to check API status: ${e.toString()}',
          isOnline: state.isOnline,
          isVerified: state.isVerified,
        ),
      );
    } finally {
      _isCheckingApi = false;
    }
  }

  Future<void> _onToggleStatus(
    ToggleStatus event,
    Emitter<DeliveryBoyStatusState> emit,
  ) async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;

    // Emit loading state immediately for better UX
    final currentIsOnline = state.isOnline;
    final currentIsVerified = state.isVerified;

    // Prevent toggling to online if not verified
    if (event.isOnline && !currentIsVerified) {
      emit(
        DeliveryBoyStatusError(
          'Your account has not been verified yet.',
          isOnline: false,
          isVerified: false,
        ),
      );
      _isProcessing = false;
      return;
    }

    emit(
      DeliveryBoyStatusLoading(
        isOnline: currentIsOnline,
        isVerified: currentIsVerified,
      ),
    );

    try {
      if (event.isOnline) {
        await _locationTracker.checkDutyAccess(
          explainBackground: event.explainBackground,
        );
        final position = await _locationTracker.prepareForDuty();
        if (position == null) {
          throw const DutyLocationException(
            LocationHealthStatus.weakSignal,
            'Weak GPS signal. Move to an open area and try again.',
          );
        }
        final response = await _deliveryBoyStatusRepo.updateDeliveryBoyStatus(
          isOnline: true,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        if (response['success'] != true) {
          throw ApiException(
            response['message']?.toString() ?? 'Failed to update status',
          );
        }
        // Reuse the gate's stream only after the server made duty active.
        if (!await _locationTracker.startTracking()) {
          throw ApiException('Your session expired. Log in again.');
        }
      } else {
        final response = await _deliveryBoyStatusRepo.updateDeliveryBoyStatus(
          isOnline: false,
        );
        if (response['success'] != true) {
          throw ApiException(
            response['message']?.toString() ?? 'Failed to update status',
          );
        }
        await _locationTracker.stopTracking();
      }
      await _saveStatus(event.isOnline);
      emit(DeliveryBoyStatusLoaded(isOnline: event.isOnline));
    } catch (e) {
      if (event.isOnline && !currentIsOnline) {
        await _locationTracker.stopTracking();
      }
      emit(
        DeliveryBoyStatusError(
          e.toString(),
          isOnline: currentIsOnline,
          isVerified: currentIsVerified,
          locationIssue: e is DutyLocationException ? e.status : null,
        ),
      );
    } finally {
      _isProcessing = false;
    }
  }
}
