import 'package:nagpur_rider/config/api_base_helper.dart';
import 'package:nagpur_rider/config/api_routes.dart';

class ReturnOrderRepo {
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
    String status,
  ) async {
    try {
      final Map<String, dynamic> body = {'status': status};

      final response = await ApiBaseHelper.put(
        url: '$updateReturnOrderApi$returnId/status',
        useAuthToken: true,
        body: body,
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while updating return order');
    }
  }

  // Tells the backend the rider is at the customer's door, so it can push
  // "your rider is here" to the customer
  Future<Map<String, dynamic>> markArrivedAtCustomer(String returnId) async {
    try {
      final response = await ApiBaseHelper.post(
        url: '$updateReturnOrderApi$returnId/arrived',
        useAuthToken: true,
      );

      return response;
    } catch (error) {
      throw Exception('Error occurred while notifying the customer');
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
