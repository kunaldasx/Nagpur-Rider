import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:nagpur_rider/config/api_base_helper.dart';
import 'package:nagpur_rider/config/api_routes.dart';
import 'package:nagpur_rider/config/constant.dart';
import 'package:nagpur_rider/config/global.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final fcmToken = await Global.getFCMToken();

      Map<String, dynamic> body = {
        'email': email,
        'password': password,
        if (fcmToken != null && fcmToken.isNotEmpty) "fcm_token": fcmToken,
        "device_type": Platform.isAndroid ? 'android' : 'ios',
      };

      var response = await ApiBaseHelper.loginPost(url: loginApi, body: body);
      return response;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// Logs in with the opaque `qr_payload` scanned from the seller app.
  Future<Map<String, dynamic>> loginWithQr({required String qrToken}) async {
    try {
      final fcmToken = await Global.getFCMToken();

      Map<String, dynamic> body = {
        'qr_token': qrToken,
        if (fcmToken != null && fcmToken.isNotEmpty) "fcm_token": fcmToken,
        "device_type": Platform.isAndroid ? 'android' : 'ios',
      };

      var response = await ApiBaseHelper.loginPost(url: qrLoginApi, body: body);
      return response;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      return await ApiBaseHelper.post(url: logoutApi);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String mobile,
    required String country,
    required String iso2,
    required String password,
    required String confirmPassword,
    required String address,
    required String driverLicenseNumber,
    required String vehicleType,
    required int deliveryZoneId,
    required File driverLicenseFile,
    required File vehicleRegistrationFile,
  }) async {
    try {
      // === DEBUG: Print all incoming parameters ===
      if (kDebugMode) {
        debugPrint('🚀 === REGISTRATION DATA START ===');
        debugPrint('Name: $name');
        debugPrint('Email: $email');
        debugPrint('Mobile: $mobile');
        debugPrint('Country: $country ($iso2)');
        debugPrint('Address: $address');
        debugPrint('Driver License Number: $driverLicenseNumber');
        debugPrint('Vehicle Type: $vehicleType');
        debugPrint('Delivery Zone ID: $deliveryZoneId');
        debugPrint('Password: ${password.isNotEmpty ? '***SET***' : 'EMPTY'}');
        debugPrint(
          'Confirm Password: ${confirmPassword.isNotEmpty ? '***SET***' : 'EMPTY'}',
        );

        // File checks
        debugPrint(
          'Driver License File Exists: ${await driverLicenseFile.exists()}',
        );
        debugPrint('Driver License File Path: ${driverLicenseFile.path}');
        debugPrint(
          'Driver License File Size: ${await driverLicenseFile.length()} bytes',
        );

        debugPrint(
          'Vehicle Registration File Exists: ${await vehicleRegistrationFile.exists()}',
        );
        debugPrint(
          'Vehicle Registration File Path: ${vehicleRegistrationFile.path}',
        );
        debugPrint(
          'Vehicle Registration File Size: ${await vehicleRegistrationFile.length()} bytes',
        );
        debugPrint('=== REGISTRATION DATA END ===');
      }

      // Validate files exist before uploading
      if (!await driverLicenseFile.exists()) {
        throw Exception(
          'Driver license file does not exist at path: ${driverLicenseFile.path}',
        );
      }
      if (!await vehicleRegistrationFile.exists()) {
        throw Exception(
          'Vehicle registration file does not exist at path: ${vehicleRegistrationFile.path}',
        );
      }

      final fcmToken = await Global.getFCMToken();

      var data = FormData.fromMap({
        'driver_license': await MultipartFile.fromFile(
          driverLicenseFile.path,
          filename:
              driverLicenseFile.path.split(Platform.isAndroid ? '/' : '/').last,
        ),
        'vehicle_registration': await MultipartFile.fromFile(
          vehicleRegistrationFile.path,
          filename:
              vehicleRegistrationFile.path
                  .split(Platform.isAndroid ? '/' : '/')
                  .last,
        ),
        'email': email,
        'mobile': mobile,
        'password': password,
        'full_name': name,
        'address': address,
        'driver_license_number': driverLicenseNumber,
        'vehicle_type': vehicleType,
        'delivery_zone_id': deliveryZoneId.toString(),
        'country': country,
        'iso_2': iso2,
        'password_confirmation': confirmPassword,
        "fcm_token": fcmToken,
        "device_type": Platform.isAndroid ? 'android' : 'ios',
      });

      if (kDebugMode) {
        debugPrint('📤 FormData prepared successfully');
        debugPrint(
          'Total fields in FormData: ${data.fields.length + data.files.length}',
        );
        debugPrint(
          'Fields: ${data.fields.map((e) => '${e.key}: ${e.value}').join(' | ')}',
        );
        debugPrint(
          'Files: ${data.files.map((e) => '${e.key}: ${e.value.filename}').join(' | ')}',
        );
      }

      final response = await ApiBaseHelper.formPost(
        url: registerApi,
        useAuthToken: false, // Usually registration doesn't need auth token
        body: data,
      );

      if (kDebugMode) {
        debugPrint('✅ Registration API Response:');
        debugPrint(response.toString());
      }

      return response;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ REGISTRATION FAILED: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Re-throw or handle as needed
      throw Exception('Error occurred during registration: $e');
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      Map<String, dynamic> body = {'email': email};

      var response = await ApiBaseHelper.post(
        url: '${deliveryZoneUrl}forget-password',
        body: body,
      );
      return response;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
