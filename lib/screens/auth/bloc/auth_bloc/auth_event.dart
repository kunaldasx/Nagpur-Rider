import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequest extends AuthEvent {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Re-sends the email/password login held in memory while the rider waits
/// for seller approval. The password is never persisted.
class RetryPendingLoginRequest extends AuthEvent {}

class CancelPendingLoginRequest extends AuthEvent {}

class QrLoginRequest extends AuthEvent {
  final String qrToken;
  QrLoginRequest({required this.qrToken});

  @override
  List<Object?> get props => [qrToken];
}

class RegisterRequest extends AuthEvent {
  final String name;
  final String email;
  final String mobile;
  final String password;
  final String country;
  final String iso2;
  final String countryCode;
  final String completePhoneNumber;
  final String confirmPassword;
  final File? driverLicenseFile;
  final File? vehicleRegistrationFile;
  final String address;
  final String vehicleType;
  final String driverLicenseNumber;
  final int deliveryZoneId;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.mobile,
    required this.password,
    required this.country,
    required this.iso2,
    required this.countryCode,
    required this.completePhoneNumber,
    required this.confirmPassword,
    this.driverLicenseFile,
    required this.deliveryZoneId,
    this.vehicleRegistrationFile,
    required this.address,
    required this.vehicleType,
    required this.driverLicenseNumber,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    mobile,
    password,
    country,
    iso2,
    countryCode,
    completePhoneNumber,
    confirmPassword,
    driverLicenseFile,
    vehicleRegistrationFile,
    address,
    vehicleType,
    driverLicenseNumber,
  ];
}
