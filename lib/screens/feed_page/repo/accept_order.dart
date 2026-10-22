import 'package:nagpur_rider/config/api_routes.dart';

import '../../../config/api_base_helper.dart';
import '../../../utils/services/order_alert_bridge.dart';

class AcceptOrderRepo {
  Future<Map<String, dynamic>> updateAcceptOrder({required int orderId}) async {
    try {
      Map<String, dynamic> body = {};

      final response = await ApiBaseHelper.post(
        url: "$acceptOrderApi/$orderId/accept",
        useAuthToken: true,
        body: body,
      );
      if (response['success'] == true) {
        // Accepted from the orders list while its alert was ringing.
        await OrderAlertBridge.stopAlert(orderId);
      }
      return response;
    } catch (error) {
      throw Exception('Error occurred');
    }
  }
}
