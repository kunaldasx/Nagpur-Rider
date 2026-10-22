import 'package:nagpur_rider/config/api_routes.dart';
import '../../../config/api_base_helper.dart';
import '../model/cod_payment.dart';

class CodPaymentRepo {
  /// GET /order-items/{id}/payment-instructions
  Future<CodPaymentInstructions> getPaymentInstructions(
    String orderItemId,
  ) async {
    final response = await ApiBaseHelper.getApi(
      url: '$itemsCollectedApi/$orderItemId/payment-instructions',
      useAuthToken: true,
      params: {},
    );
    return _parse(response, 'Failed to fetch payment details');
  }

  /// POST /order-items/{id}/payment-qr — creates or reuses the active QR.
  Future<CodPaymentInstructions> createPaymentQr(String orderItemId) async {
    final response = await ApiBaseHelper.formPost(
      url: '$itemsCollectedApi/$orderItemId/payment-qr',
    );
    return _parse(response, 'Failed to create UPI QR');
  }

  CodPaymentInstructions _parse(
    Map<String, dynamic> response,
    String fallbackMessage,
  ) {
    final data = response['data'];
    if (response['success'] == true && data is Map<String, dynamic>) {
      return CodPaymentInstructions.fromJson(data);
    }
    throw ApiException(response['message']?.toString() ?? fallbackMessage);
  }
}
