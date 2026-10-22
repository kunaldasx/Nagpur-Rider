import 'package:nagpur_rider/config/api_routes.dart';
import '../../../config/api_base_helper.dart';

class ItemsCollectedRepo {
  Future<Map<String, dynamic>> itemsCollected(String orderItemId) async {
    try {
      final response = await ApiBaseHelper.put(
        url: '$itemsCollectedApi/$orderItemId/status',
        body: {'status': 'collected'},
      );

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> itemsDelivered(
    String orderItemId,
    String? otp, {
    bool cashCollected = false,
  }) async {
    try {
      // Initialize the body with the status
      final Map<String, dynamic> body = {'status': 'delivered'};

      // Add otp to the body only if it is not null or empty
      if (otp != null && otp.isNotEmpty) {
        body['otp'] = otp;
      }

      // Cash COD is confirmed together with the delivery. UPI is confirmed
      // by the Razorpay webhook, so it is never sent here.
      if (cashCollected) {
        body['payment_collection'] = {'method': 'cash'};
      }

      final response = await ApiBaseHelper.put(
        url: '$itemsCollectedApi/$orderItemId/status',
        body: body,
      );

      return response;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
