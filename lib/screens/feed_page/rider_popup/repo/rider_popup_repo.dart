import 'package:nagpur_rider/config/api_base_helper.dart';
import 'package:nagpur_rider/config/api_routes.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/model/rider_popup_order.dart';
import 'package:nagpur_rider/utils/services/order_alert_bridge.dart';

enum AlertAcceptOutcome {
  /// The backend confirmed the order is this rider's.
  accepted,

  /// The backend refused: cancelled, or no longer assigned to this rider.
  unavailable,

  /// Network or server trouble: the order still needs accepting.
  retry,

  /// The session expired: the rider has to log in again.
  signedOut,
}

/// Result of accepting an order from its incoming-order alert.
class AlertAcceptResult {
  final AlertAcceptOutcome outcome;
  final String message;

  const AlertAcceptResult(this.outcome, [this.message = '']);
}

/// Result of scanning a bag: the bag as the server now has it.
class BagScanResult {
  final int? sellerOrderId;
  final RiderBag bag;

  const BagScanResult(this.sellerOrderId, this.bag);
}

class OfferAcceptException extends ApiException {
  final AlertAcceptResult result;
  OfferAcceptException(this.result) : super(result.message);
}

class RiderPopupRepo {
  static String _message(Map<String, dynamic> response, String fallback) {
    final message = response['message']?.toString().trim() ?? '';
    return message.isEmpty ? fallback : message;
  }

  /// Orders reserved to this rider with a pending offer, a seller bag,
  /// and at least one item in `preparing`.
  Future<List<RiderPopupOrder>> availableOrders() async {
    final response = await ApiBaseHelper.getApi(
      url: availableOrdersStatusApi,
      useAuthToken: true,
      params: {'order_mode': 'regular'},
    );
    if (response['success'] != true) {
      throw ApiException(_message(response, "Couldn't load orders"));
    }
    final data = response['data'];
    final list = data is Map ? data['orders'] : null;
    return [
      if (list is List)
        for (final json in list)
          if (RiderPopupOrder.tryParse(json) case final order?)
            if (order.hasBag && order.hasPreparingItem) order,
    ];
  }

  /// Accepts [orderId]. Throws with the server's message when the order was
  /// taken by someone else or isn't in the rider's zone.
  Future<void> accept(int orderId) async {
    final result = await acceptFromAlert(orderId);
    if (result.outcome != AlertAcceptOutcome.accepted) {
      throw OfferAcceptException(result);
    }
    await OrderAlertBridge.stopAlert(orderId);
  }

  /// Accepts [orderId] after the rider tapped Accept on its alert. Unlike
  /// [accept], tells a refusal apart from trouble reaching the server, so
  /// the alert only stops when the backend has decided.
  Future<AlertAcceptResult> acceptFromAlert(int orderId) async {
    final Map<String, dynamic> response;
    try {
      response = await ApiBaseHelper.post(
        url: '$acceptOrderApi/$orderId/accept',
        useAuthToken: true,
      );
    } on ApiException {
      return const AlertAcceptResult(
        AlertAcceptOutcome.retry,
        "Couldn't reach the server. Check your internet and try again.",
      );
    }
    if (response['success'] == true) {
      return const AlertAcceptResult(AlertAcceptOutcome.accepted);
    }
    final message = response['message']?.toString().trim() ?? '';
    final lower = message.toLowerCase();
    if (response['statusCode'] == 401 || lower.startsWith('unauthenticated')) {
      return const AlertAcceptResult(
        AlertAcceptOutcome.signedOut,
        'Your session expired. Log in again to accept this order.',
      );
    }
    final status = response['statusCode'];
    // Only a body with `success: false` is the backend's decision. A crash
    // (Laravel: `{"message": "Server Error"}`) has no `success` flag.
    final serverError =
        !response.containsKey('success') || (status is int && status >= 500);
    if (serverError) {
      return const AlertAcceptResult(
        AlertAcceptOutcome.retry,
        'The server had a problem. Try again.',
      );
    }
    return AlertAcceptResult(
      AlertAcceptOutcome.unavailable,
      message.isEmpty ? 'This order is unavailable.' : message,
    );
  }

  Future<RiderPopupOrder> orderDetail(int orderId) async {
    final response = await ApiBaseHelper.getApi(
      url: '$orderDetailsApi/$orderId',
      useAuthToken: true,
      params: {},
    );
    final data = response['data'];
    final order = RiderPopupOrder.tryParse(data is Map ? data['order'] : null);
    if (response['success'] != true || order == null) {
      throw ApiException(_message(response, "Couldn't load this order."));
    }
    return order;
  }

  /// Scans [barcode] as the bag of [orderId]. On success the server marks
  /// the bag picked up and its preparing items collected.
  Future<BagScanResult> scanBag(int orderId, String barcode) async {
    final response = await ApiBaseHelper.post(
      url: '$acceptOrderApi/$orderId/scan-bag',
      useAuthToken: true,
      body: {'barcode': barcode},
    );
    final data = response['data'];
    final bagJson = data is Map ? data['bag'] : null;
    final bag = RiderBag.tryParse(bagJson);
    if (response['success'] != true || bag == null) {
      throw ApiException(_message(response, "Couldn't scan this bag."));
    }
    final sellerOrderId = bagJson is Map ? bagJson['seller_order_id'] : null;
    return BagScanResult(
      sellerOrderId is num
          ? sellerOrderId.toInt()
          : int.tryParse('$sellerOrderId'),
      bag,
    );
  }
}
