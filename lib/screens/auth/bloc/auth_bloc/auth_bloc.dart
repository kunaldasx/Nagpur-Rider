import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nagpur_rider/config/global.dart';
import 'package:nagpur_rider/screens/auth/repo/auth_repo.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Kept in memory only so the pending screen can retry; never persisted.
  String? _pendingEmail;
  String? _pendingPassword;
  AuthPendingApproval? _lastPendingApproval;

  bool get hasPendingLogin => _pendingEmail != null;
  AuthPendingApproval? get lastPendingApproval => _lastPendingApproval;

  AuthBloc() : super(AuthInitial()) {
    on<LoginRequest>(_onLoginRequest);
    on<RetryPendingLoginRequest>(_onRetryPendingLoginRequest);
    on<CancelPendingLoginRequest>(_onCancelPendingLoginRequest);
    on<QrLoginRequest>(_onQrLoginRequest);
    on<RegisterRequest>(_onRegisterRequest);
  }

  Future<void> _onLoginRequest(
    LoginRequest event,
    Emitter<AuthState> emit,
  ) async {
    await _passwordLogin(event.email, event.password, emit);
  }

  Future<void> _onRetryPendingLoginRequest(
    RetryPendingLoginRequest event,
    Emitter<AuthState> emit,
  ) async {
    final email = _pendingEmail;
    final password = _pendingPassword;
    if (email == null || password == null) {
      emit(AuthInitial());
      return;
    }
    await _passwordLogin(email, password, emit);
  }

  void _onCancelPendingLoginRequest(
    CancelPendingLoginRequest event,
    Emitter<AuthState> emit,
  ) {
    _clearPendingCredentials();
    emit(AuthInitial());
  }

  Future<void> _passwordLogin(
    String email,
    String password,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await AuthRepository().login(
        email: email,
        password: password,
      );
      if (response['success'] == true) {
        _clearPendingCredentials();
        await _saveSession(response);
        emit(AuthSuccess(message: response['message']));
        return;
      }

      final data = response['data'];
      if (data is Map && data['login_approval_status'] == 'pending') {
        _pendingEmail = email;
        _pendingPassword = password;
        _lastPendingApproval = AuthPendingApproval(
          message: response['message'] ?? '',
          email: email,
          requestedAt: DateTime.tryParse(
            data['approval_requested_at']?.toString() ?? '',
          ),
        );
        emit(_lastPendingApproval!);
        return;
      }

      _clearPendingCredentials();
      emit(AuthFailure(error: response['message'] ?? 'Login failed'));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onQrLoginRequest(
    QrLoginRequest event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await AuthRepository().loginWithQr(
        qrToken: event.qrToken,
      );
      if (response['success'] == true) {
        await _saveSession(response);
        emit(AuthSuccess(message: response['message']));
      } else {
        emit(AuthFailure(error: response['message'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _saveSession(Map<String, dynamic> response) async {
    final data = response['data'] as Map<String, dynamic>;
    await Global.setUserToken(data['access_token'].toString());
    await Global.setUserTokenExpiresAt(data['expires_at']?.toString());
  }

  void _clearPendingCredentials() {
    _pendingEmail = null;
    _pendingPassword = null;
    _lastPendingApproval = null;
  }

  Future<void> _onRegisterRequest(
    RegisterRequest event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Map<String, dynamic> response = {};
      final response = await AuthRepository().register(
        name: event.name,
        email: event.email,
        mobile: event.mobile,
        password: event.password,
        confirmPassword: event.confirmPassword,
        address: event.address,
        driverLicenseNumber: event.driverLicenseNumber,
        vehicleType: event.vehicleType,
        deliveryZoneId: event.deliveryZoneId,
        driverLicenseFile: event.driverLicenseFile!, // File
        vehicleRegistrationFile: event.vehicleRegistrationFile!, // File
        country: event.country,
        iso2: event.iso2,
      );

      if (response['success'] == true) {
        final token = response['access_token'].toString();

        await Global.setUserToken(token);
        await Global.setUserTokenExpiresAt(null);

        emit(AuthSuccess(message: response['message']));
      } else {
        emit(AuthFailure(error: response['message']));
      }
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }
}
