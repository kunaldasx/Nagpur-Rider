import 'package:latlong2/latlong.dart';

import '../../../model/return_orders_list_model.dart';

/// Which trip of a return pickup the rider is on.
enum ReturnPickupLeg { toCustomer, toSeller, completed }

/// Pure helpers for the return pickup map, kept free of Flutter state so
/// they can be unit tested.
class ReturnPickupFlow {
  const ReturnPickupFlow._();

  static ReturnPickupLeg legFor(String? pickupStatus) {
    switch (pickupStatus) {
      case 'picked_up':
        return ReturnPickupLeg.toSeller;
      case 'delivered_to_seller':
        return ReturnPickupLeg.completed;
      default:
        return ReturnPickupLeg.toCustomer;
    }
  }

  /// Where the package is collected. The order's shipping coordinates are
  /// the customer's own; the first route stop is the fallback.
  static LatLng? customerLocation(Pickups pickup) {
    final order = pickup.order;
    final fromOrder = _parse(order?.shippingLatitude, order?.shippingLongitude);
    if (fromOrder != null) return fromOrder;

    final stops = pickup.deliveryRoute?.routeDetails;
    if (stops == null || stops.isEmpty) return null;
    return _valid(stops.first.latitude, stops.first.longitude);
  }

  /// Where the package is returned: the store, else the last route stop.
  static LatLng? sellerLocation(Pickups pickup) {
    final store = pickup.store;
    final fromStore = _parse(store?.latitude, store?.longitude);
    if (fromStore != null) return fromStore;

    final stops = pickup.deliveryRoute?.routeDetails;
    if (stops == null || stops.isEmpty) return null;
    return _valid(stops.last.latitude, stops.last.longitude);
  }

  static LatLng? destinationFor(Pickups pickup, ReturnPickupLeg leg) {
    switch (leg) {
      case ReturnPickupLeg.toCustomer:
        return customerLocation(pickup);
      case ReturnPickupLeg.toSeller:
      case ReturnPickupLeg.completed:
        return sellerLocation(pickup);
    }
  }

  static String customerName(Pickups pickup) =>
      _firstNonEmpty([pickup.order?.shippingName, pickup.user?.name]);

  static String customerAddress(Pickups pickup) {
    final order = pickup.order;
    if (order == null) return '';
    return _join([
      order.shippingAddress1,
      order.shippingAddress2,
      order.shippingLandmark,
      order.shippingCity,
    ]);
  }

  static String sellerName(Pickups pickup) => _firstNonEmpty([
    pickup.store?.name,
    if (pickup.deliveryRoute?.routeDetails?.isNotEmpty ?? false)
      pickup.deliveryRoute!.routeDetails!.last.storeName,
  ]);

  static String sellerAddress(Pickups pickup) {
    final store = pickup.store;
    if (store == null) return '';
    return _join([store.address, store.city]);
  }

  /// Dialable customer number, or null when none was sent. The rider only ever
  /// calls the customer; the seller has no number in the pickup.
  static String? customerPhone(Pickups pickup) => _dialable(
    _firstNonEmpty([pickup.order?.shippingPhone, pickup.user?.phone]),
  );

  /// The product being returned, e.g. "Dettol Handwash · 750 ml".
  static String itemTitle(Pickups pickup) {
    final product = pickup.orderItem?.product?.name ?? '';
    final variant = pickup.orderItem?.variant?.title ?? '';
    if (product.isEmpty) return variant;
    if (variant.isEmpty || variant == product) return product;
    return '$product · $variant';
  }

  static String? _dialable(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    return digits.isEmpty ? null : digits;
  }

  static LatLng? _parse(String? lat, String? lng) =>
      _valid(double.tryParse(lat ?? ''), double.tryParse(lng ?? ''));

  // The JSON parser turns a missing coordinate into 0.0, so 0,0 means none
  static LatLng? _valid(double? lat, double? lng) {
    if (lat == null || lng == null) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat == 0 && lng == 0) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static String _join(List<String?> parts) => parts
      .where((p) => p != null && p.trim().isNotEmpty)
      .map((p) => p!.trim())
      .join(', ');
}
