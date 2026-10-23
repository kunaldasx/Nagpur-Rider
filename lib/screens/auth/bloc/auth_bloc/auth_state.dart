import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  AuthSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Password login reached the backend but the seller has not approved it yet.
class AuthPendingApproval extends AuthState {
  final String message;
  final String email;
  final DateTime? requestedAt;
  AuthPendingApproval({
    required this.message,
    required this.email,
    this.requestedAt,
  });

  @override
  List<Object?> get props => [message, email, requestedAt];
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure({required this.error});
  @override
  List<Object?> get props => [error];
}
