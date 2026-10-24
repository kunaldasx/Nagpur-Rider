import 'package:nagpur_rider/config/api_base_helper.dart';
import 'package:nagpur_rider/config/api_routes.dart';
import '../model/return_orders_list_model.dart';

class ReturnOrderRepo {
  static Pickups pickupFromResponse(
    Map<String, dynamic> response,
    String returnId,
  ) {
    final pickup = Pickups.fromJson(
      response['data']['pickup'] as Map<String, dynamic>,
    );
    if (pickup.id.toString() != returnId ||
        ![
          'assigned',
          'picked_up',
          'delivered_to_seller',
        ].contains(pickup.pickupStatus)) {
      throw const FormatException('Invalid return pickup response');
    }
    return pickup;
  }

  Future<Map<String, dynamic>> getReturnOrder({int? limit, int? offset}) async {
    try {
      Map<String, dynamic> body = {};
      if (limit != null) {
        body["per_page"] = limit;
      }
      if (offset != null) {
        // Convert offset to page number (offset 0 = page 1, offset 10 = page 2, etc.)
        int page = (offset ~/ (limit ?? 10)) + 1;
        body["page"] = page;
      }

      final response = await ApiBaseHelper.getApi(
        url: getReturnOrdersApi,
        useAuthToken: true,
        params: body,
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while fetching return order details');
    }
  }

  Future<Map<String, dynamic>> acceptReturnOrder(String returnId) async {
    try {
      final response = await ApiBaseHelper.post(
        url: '$acceptReturnOrderApi$returnId/accept',
        useAuthToken: true,
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while accepting return order');
    }
  }

  Future<Map<String, dynamic>> updateReturnOrderStatus(
    String returnId,
    String status, {
    required String otp,
  }) async {
    try {
      final Map<String, dynamic> body = {'status': status, 'otp': otp};

      final response = await ApiBaseHelper.put(
        url: '$updateReturnOrderApi$returnId/status',
        useAuthToken: true,
        body: body,
        redactBody: true,
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while updating return order');
    }
  }

  Future<Map<String, dynamic>> getReturnPickups({
    int? limit,
    int? offset,
  }) async {
    try {
      Map<String, dynamic> body = {};
      if (limit != null) {
        body["per_page"] = limit;
      }
      if (offset != null) {
        // Convert offset to page number (offset 0 = page 1, offset 10 = page 2, etc.)
        int page = (offset ~/ (limit ?? 10)) + 1;
        body["page"] = page;
      }

      final response = await ApiBaseHelper.getApi(
        url: listPickupsApi,
        useAuthToken: true,
        params: body,
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while fetching return pickups');
    }
  }

  Future<Map<String, dynamic>> getReturnPickupsDetails(String returnId) async {
    try {
      final response = await ApiBaseHelper.getApi(
        url: '$pickupDetailsApi$returnId',
        useAuthToken: true,
        params: {},
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while fetching return pickups details');
    }
  }
}
