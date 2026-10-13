import 'package:nagpur_rider/config/api_base_helper.dart';
import 'package:nagpur_rider/config/api_routes.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/model/rider_popup_order.dart';

/// Result of scanning a bag: the bag as the server now has it.
class BagScanResult {
  final int? sellerOrderId;
  final RiderBag bag;

  const BagScanResult(this.sellerOrderId, this.bag);
}

class RiderPopupRepo {
  static String _message(Map<String, dynamic> response, String fallback) {
    final message = response['message']?.toString().trim() ?? '';
    return message.isEmpty ? fallback : message;
  }

  /// Unassigned orders in the rider's zone that already have a seller bag
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
            if (order.hasBag) order,
    ];
  }

  /// Accepts [orderId]. Throws with the server's message when the order was
  /// taken by someone else or isn't in the rider's zone.
  Future<void> accept(int orderId) async {
    final response = await ApiBaseHelper.post(
      url: '$acceptOrderApi/$orderId/accept',
      useAuthToken: true,
    );
    if (response['success'] != true) {
      throw ApiException(_message(response, 'This order is unavailable.'));
    }
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
