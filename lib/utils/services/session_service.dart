import 'package:go_router/go_router.dart';
import 'package:nagpur_rider/config/global.dart';
import 'package:nagpur_rider/router/app_routes.dart';
import 'package:nagpur_rider/utils/location_tracker.dart';

class SessionService {
  static bool _isExpiring = false;

  /// Stops tracking and clears every locally stored rider credential.
  static Future<void> endLocalSession() async {
    LocationTracker().stopTracking();
    await Global.setDeliveryBoyStatus(false);
    await Global.clearSession();
  }

  /// Called when the backend rejects the rider token (approval deadline
  /// passed, QR session expired or revoked, seller rejected the rider).
  static Future<void> expireSession() async {
    if (_isExpiring) return;
    _isExpiring = true;
    try {
      await endLocalSession();
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        GoRouter.of(context).go(AppRoutes.login);
      }
    } finally {
      _isExpiring = false;
    }
  }
}
