import 'dart:convert';

import 'package:nagpur_rider/screens/feed_page/rider_popup/model/rider_popup_order.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/repo/rider_popup_repo.dart';
import 'rider_popup_sample.dart';

RiderPopupOrder popupOrder({int? riderId = 14, String status = 'assigned'}) {
  final raw =
      jsonDecode(jsonEncode(availableOrdersSample['data']['orders'][0]))
          as Map<String, dynamic>;
  raw['delivery_boy_id'] = riderId;
  raw['status'] = status;
  return RiderPopupOrder.tryParse(raw)!;
}

class FakeRiderPopupRepo extends RiderPopupRepo {
  List<RiderPopupOrder> offers = [popupOrder(status: 'pending')];
  RiderPopupOrder detail = popupOrder();
  int detailCalls = 0;
  AlertAcceptResult result = const AlertAcceptResult(
    AlertAcceptOutcome.accepted,
  );
  Future<List<RiderPopupOrder>> Function()? fetch;
  @override
  Future<List<RiderPopupOrder>> availableOrders() async =>
      fetch != null ? fetch!() : offers;
  @override
  Future<void> accept(int orderId) async {
    if (result.outcome != AlertAcceptOutcome.accepted) {
      throw OfferAcceptException(result);
    }
  }

  @override
  Future<RiderPopupOrder> orderDetail(int orderId) async {
    detailCalls++;
    return detail;
  }
}
