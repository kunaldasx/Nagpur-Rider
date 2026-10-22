import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nagpur_rider/l10n/app_localizations.dart';
import 'package:nagpur_rider/config/global.dart';

class LocationHandler {
  static bool _isDialogShowing = false;
  static StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  /// Initialize monitoring of location service status
  static void initialize() {
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
      ServiceStatus status,
    ) {
      if (status == ServiceStatus.disabled) {
        checkLocationAvailability();
      } else if (status == ServiceStatus.enabled) {
        // If GPS is enabled and our dialog is showing, we close it
        final context = navigatorKey.currentContext;
        if (_isDialogShowing && context != null && context.mounted) {
          try {
            Navigator.of(context, rootNavigator: true).pop();
          } catch (e) {
            debugPrint('Error popping location dialog: $e');
          }
          _isDialogShowing = false;
        }
      }
    });

    // Initial check
    checkLocationAvailability();
  }

  /// Stop monitoring
  static void dispose() {
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;
  }

  /// Check location service and permission, show dialog if needed
  static Future<void> checkLocationAvailability() async {
    final context = navigatorKey.currentContext;
    if (_isDialogShowing || context == null || !context.mounted) return;

    // Only show location prompt if user is logged in
    final token = Global.userToken;
    if (token == null || token.isEmpty) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showPermissionDeniedDialog(isPermanent: false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        showPermissionDeniedDialog(isPermanent: true);
        return;
      }
    } catch (e) {
      debugPrint('Error checking location availability: $e');
    }
  }

  static void showLocationServiceDialog() {
    final context = navigatorKey.currentContext;
    if (_isDialogShowing || context == null || !context.mounted) return;
    _isDialogShowing = true;

    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              _getString(
                l10n,
                'locationServiceDisabled',
                'Location Service Disabled',
              ),
            ),
            content: Text(
              _getString(
                l10n,
                'locationServiceDescription',
                'GPS is required to track your delivery progress. Please enable location services to continue.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  _isDialogShowing = false;
                  await Geolocator.openLocationSettings();
                },
                child: Text(_getString(l10n, 'enable', 'Enable')),
              ),
            ],
          ),
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  static void showPermissionDeniedDialog({required bool isPermanent}) {
    final context = navigatorKey.currentContext;
    if (_isDialogShowing || context == null || !context.mounted) return;
    _isDialogShowing = true;

    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              _getString(
                l10n,
                'locationPermissionDenied',
                'Location Permission Denied',
              ),
            ),
            content: Text(
              isPermanent
                  ? _getString(
                    l10n,
                    'locationPermissionPermanentDescription',
                    'Location permission is permanently denied. Please enable it from app settings to continue.',
                  )
                  : _getString(
                    l10n,
                    'locationPermissionDescription',
                    'This app needs location permission to track your delivery in real-time.',
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  _isDialogShowing = false;
                  if (isPermanent) {
                    await Geolocator.openAppSettings();
                  } else {
                    checkLocationAvailability();
                  }
                },
                child: Text(
                  isPermanent
                      ? _getString(l10n, 'settings', 'Settings')
                      : _getString(l10n, 'retry', 'Retry'),
                ),
              ),
            ],
          ),
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  /// Helper to safely get localized string or fallback
  static String _getString(
    AppLocalizations? l10n,
    String key,
    String fallback,
  ) {
    if (l10n == null) return fallback;

    // Use dynamic access to avoid compilation errors if keys are newly added to ARB
    // but not yet generated in the AppLocalizations class.
    try {
      final dynamic dynamicL10n = l10n;
      // We try to access the property by its name.
      // If it exists as a getter, dynamic access will work.
      switch (key) {
        case 'locationServiceDisabled':
          return dynamicL10n.locationServiceDisabled?.toString() ?? fallback;
        case 'locationServiceDescription':
          return dynamicL10n.locationServiceDescription?.toString() ?? fallback;
        case 'enable':
          return dynamicL10n.enable?.toString() ?? fallback;
        case 'locationPermissionDenied':
          return dynamicL10n.locationPermissionDenied?.toString() ?? fallback;
        case 'locationPermissionDescription':
          return dynamicL10n.locationPermissionDescription?.toString() ??
              fallback;
        case 'locationPermissionPermanentDescription':
          return dynamicL10n.locationPermissionPermanentDescription
                  ?.toString() ??
              fallback;
        case 'settings':
          return dynamicL10n.settings?.toString() ?? fallback;
        case 'retry':
          return dynamicL10n.retry?.toString() ?? fallback;
        default:
          return fallback;
      }
    } catch (_) {
      return fallback;
    }
  }
}
