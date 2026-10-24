import 'package:nagpur_rider/screens/feed_page/repo/return_order_repo.dart';

Map<String, dynamic> pickupResponse(String status) => {
  'success': true,
  'message': 'Status updated successfully',
  'data': {
    'pickup': {
      'id': 731,
      'pickup_status': status,
      'order': {
        'shipping_name': 'Customer',
        'shipping_phone': '+919999999999',
        'shipping_latitude': '21.1458',
        'shipping_longitude': '79.0882',
      },
      'store': {'name': 'Seller', 'latitude': '21.15', 'longitude': '79.09'},
    },
  },
};

Map<String, dynamic> returnFailure(String code, String message) => {
  'success': false,
  'message': message,
  'data': {'error': code},
};

class FakeReturnOrderRepo extends ReturnOrderRepo {
  final List<({String returnId, String status, String otp})> updates = [];
  int acceptCalls = 0;
  int detailCalls = 0;
  Future<Map<String, dynamic>> Function()? accept;
  Future<Map<String, dynamic>> Function(String status)? update;
  Future<Map<String, dynamic>> Function()? details;

  @override
  Future<Map<String, dynamic>> acceptReturnOrder(String returnId) async {
    acceptCalls++;
    return accept != null ? await accept!() : pickupResponse('assigned');
  }

  @override
  Future<Map<String, dynamic>> updateReturnOrderStatus(
    String returnId,
    String status, {
    required String otp,
  }) async {
    updates.add((returnId: returnId, status: status, otp: otp));
    return update != null ? await update!(status) : pickupResponse(status);
  }

  @override
  Future<Map<String, dynamic>> getReturnPickupsDetails(String returnId) async {
    detailCalls++;
    return details != null ? await details!() : pickupResponse('picked_up');
  }
}
