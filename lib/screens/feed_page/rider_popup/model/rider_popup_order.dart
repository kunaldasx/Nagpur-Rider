import 'package:equatable/equatable.dart';

String _str(dynamic value) => value == null ? '' : value.toString().trim();

int? _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(_str(value));

double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(_str(value)) ?? 0;

Map<String, dynamic>? _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

/// The bag a seller packed an order's items into. The rider must scan it
/// before those items can move to `collected`.
///
/// [barcode] is empty when the server hides it (the live `pickup_bags`
/// payload does), so the rider can only get it from the physical bag.
class RiderBag extends Equatable {
  final int id;
  final String barcode;
  final String pickupStatus;
  final DateTime? pickedUpAt;
  final int? pickedUpByDeliveryBoyId;

  const RiderBag({
    required this.id,
    required this.barcode,
    this.pickupStatus = '',
    this.pickedUpAt,
    this.pickedUpByDeliveryBoyId,
  });

  static RiderBag? tryParse(dynamic json) {
    final map = _map(json);
    if (map == null) return null;
    final id = _int(map['id']) ?? _int(map['seller_order_id']);
    if (id == null) return null;
    return RiderBag(
      id: id,
      barcode: _str(map['barcode']),
      pickupStatus: _str(map['pickup_status']),
      pickedUpAt: DateTime.tryParse(_str(map['picked_up_at'])),
      pickedUpByDeliveryBoyId: _int(map['picked_up_by_delivery_boy_id']),
    );
  }

  bool get isPickedUp => pickedUpAt != null || pickupStatus == 'picked_up';

  bool get hasKnownBarcode => barcode.isNotEmpty;

  bool matches(String code) =>
      hasKnownBarcode && barcode.toLowerCase() == code.trim().toLowerCase();

  Map<String, dynamic> toJson() => {
    'id': id,
    'barcode': barcode,
    'pickup_status': pickupStatus,
    'picked_up_at': pickedUpAt?.toIso8601String(),
    'picked_up_by_delivery_boy_id': pickedUpByDeliveryBoyId,
  };

  @override
  List<Object?> get props => [
    id,
    barcode,
    pickupStatus,
    pickedUpAt,
    pickedUpByDeliveryBoyId,
  ];
}

/// One seller's share of an order, with the bag it was packed into.
class RiderSellerOrder extends Equatable {
  final int id;
  final String sellerName;
  final String sellerPhone;
  final RiderBag? bag;

  const RiderSellerOrder({
    required this.id,
    this.sellerName = '',
    this.sellerPhone = '',
    this.bag,
  });

  static RiderSellerOrder? tryParse(dynamic json) {
    final map = _map(json);
    final id = _int(map?['id']);
    if (map == null || id == null) return null;
    final seller = _map(map['seller']) ?? const {};
    return RiderSellerOrder(
      id: id,
      sellerName: _str(seller['name']),
      sellerPhone: _str(seller['phone']),
      bag: RiderBag.tryParse(map['bag']),
    );
  }

  /// An entry of the `pickup_bags` list the live API sends instead of
  /// `seller_orders[].bag`: one bag per seller order, barcode withheld.
  static RiderSellerOrder? tryParsePickupBag(dynamic json) {
    final map = _map(json);
    final id = _int(map?['seller_order_id']);
    if (map == null || id == null) return null;
    final storeName = _str(map['store_name']);
    return RiderSellerOrder(
      id: id,
      sellerName: storeName.isNotEmpty ? storeName : _str(map['seller_name']),
      sellerPhone: _str(map['contact_phone']),
      bag: RiderBag.tryParse(map),
    );
  }

  static List<RiderSellerOrder> listFrom(dynamic json) => [
    if (json is List)
      for (final entry in json)
        if (tryParse(entry) case final sellerOrder?) sellerOrder,
  ];

  /// Seller orders of an order payload: `seller_orders` (as documented) or,
  /// failing that, `pickup_bags` (as the server sends today).
  static List<RiderSellerOrder> listFromOrder(Map json) {
    final documented = listFrom(json['seller_orders']);
    if (documented.any((s) => s.bag != null)) return documented;
    final pickupBags = json['pickup_bags'];
    if (pickupBags is! List || pickupBags.isEmpty) return documented;
    return [
      for (final entry in pickupBags)
        if (tryParsePickupBag(entry) case final sellerOrder?) sellerOrder,
    ];
  }

  RiderSellerOrder copyWith({RiderBag? bag}) => RiderSellerOrder(
    id: id,
    sellerName: sellerName,
    sellerPhone: sellerPhone,
    bag: bag ?? this.bag,
  );

  @override
  List<Object?> get props => [id, sellerName, sellerPhone, bag];
}

/// True when [sellerOrders] carry a bag the rider hasn't scanned yet, so no
/// item may be marked collected.
bool needsBagScan(List<RiderSellerOrder>? sellerOrders) =>
    sellerOrders?.any((s) => s.bag != null && !s.bag!.isPickedUp) ?? false;

class RiderPopupItem extends Equatable {
  final int id;
  final String productName;
  final String variantName;
  final String status;
  final int quantity;
  final double subtotal;
  final String storeName;
  final String storeContact;

  const RiderPopupItem({
    required this.id,
    required this.productName,
    this.variantName = '',
    this.status = '',
    this.quantity = 0,
    this.subtotal = 0,
    this.storeName = '',
    this.storeContact = '',
  });

  static RiderPopupItem? tryParse(dynamic json) {
    final map = _map(json);
    final id = _int(map?['id']);
    if (map == null || id == null) return null;
    final store = _map(map['store']) ?? const {};
    final product = _map(map['product']) ?? const {};
    return RiderPopupItem(
      id: id,
      productName: [
        _str(map['product_name']),
        _str(map['title']),
        _str(product['name']),
      ].firstWhere((s) => s.isNotEmpty, orElse: () => 'Item'),
      variantName:
          _str(map['variant_name']).isNotEmpty
              ? _str(map['variant_name'])
              : _str(map['variant_title']),
      status: _str(map['status']),
      quantity: _int(map['quantity']) ?? 0,
      subtotal: _double(map['subtotal']),
      storeName: _str(store['name']),
      storeContact: _str(store['contact_number']),
    );
  }

  @override
  List<Object?> get props => [id, status, quantity];
}

/// An order as the rider popup shows it, parsed from either the available
/// orders list or the order detail endpoint. [raw] is kept so the order can
/// be persisted and handed to the existing screens (`Orders.fromJson`).
class RiderPopupOrder extends Equatable {
  final int id;
  final String orderNumber;
  final String status;
  final DateTime? createdAt;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String paymentMethod;
  final double total;
  final List<RiderPopupItem> items;
  final List<RiderSellerOrder> sellerOrders;
  final Map<String, dynamic> raw;

  const RiderPopupOrder({
    required this.id,
    required this.orderNumber,
    this.status = '',
    this.createdAt,
    this.customerName = '',
    this.customerPhone = '',
    this.customerAddress = '',
    this.paymentMethod = '',
    this.total = 0,
    this.items = const [],
    this.sellerOrders = const [],
    this.raw = const {},
  });

  static RiderPopupOrder? tryParse(dynamic json) {
    final map = _map(json);
    final id = _int(map?['id']);
    if (map == null || id == null) return null;
    final customer = _map(map['customer']) ?? const {};
    final address =
        _str(customer['address']).isNotEmpty
            ? _str(customer['address'])
            : [
              map['shipping_address_1'],
              map['shipping_address_2'],
              map['shipping_landmark'],
              map['shipping_city'],
              map['shipping_state'],
              map['shipping_zip'],
            ].map(_str).where((s) => s.isNotEmpty).join(', ');
    final orderNumber = [
      _str(map['order_number']),
      _str(map['slug']),
    ].firstWhere((s) => s.isNotEmpty, orElse: () => '$id');
    return RiderPopupOrder(
      id: id,
      orderNumber: orderNumber,
      status: _str(map['status']),
      createdAt: DateTime.tryParse(_str(map['created_at'])),
      customerName:
          _str(customer['name']).isNotEmpty
              ? _str(customer['name'])
              : _str(map['shipping_name']),
      customerPhone:
          _str(customer['phone']).isNotEmpty
              ? _str(customer['phone'])
              : _str(map['shipping_phone']),
      customerAddress: address,
      paymentMethod: _str(map['payment_method']),
      total: _double(map['total'] ?? map['final_total']),
      items: [
        if (map['items'] is List)
          for (final entry in map['items'] as List)
            if (RiderPopupItem.tryParse(entry) case final item?) item,
      ],
      sellerOrders: RiderSellerOrder.listFromOrder(map),
      raw: map,
    );
  }

  /// Seller orders the rider has to pick a bag up from.
  List<RiderSellerOrder> get baggedSellerOrders =>
      sellerOrders.where((s) => s.bag != null).toList();

  bool get hasBag => baggedSellerOrders.isNotEmpty;

  bool get hasPreparingItem => items.any((i) => i.status == 'preparing');

  bool get allBagsPickedUp =>
      hasBag && baggedSellerOrders.every((s) => s.bag!.isPickedUp);

  bool get isClosed => const {
    'delivered',
    'cancelled',
    'canceled',
    'failed',
    'returned',
  }.contains(status.toLowerCase());

  /// Store/seller contacts to call about the pickup, without duplicates.
  List<({String name, String phone})> get pickupContacts {
    final seen = <String>{};
    final contacts = <({String name, String phone})>[];
    void add(String name, String phone) {
      if (phone.isEmpty || !seen.add(phone)) return;
      contacts.add((name: name.isEmpty ? 'Store' : name, phone: phone));
    }

    for (final s in sellerOrders) {
      add(s.sellerName, s.sellerPhone);
    }
    for (final item in items) {
      add(item.storeName, item.storeContact);
    }
    return contacts;
  }

  /// This order with the bag of seller order [sellerOrderId] replaced.
  RiderPopupOrder withBag(int sellerOrderId, RiderBag bag) => withSellerOrders([
    for (final s in sellerOrders)
      s.id == sellerOrderId ? s.copyWith(bag: bag) : s,
  ]);

  /// This order with [sellerOrders] in place of its own, e.g. to keep bags
  /// known from the orders list when the detail payload has none.
  RiderPopupOrder withSellerOrders(List<RiderSellerOrder> sellerOrders) {
    return RiderPopupOrder(
      id: id,
      orderNumber: orderNumber,
      status: status,
      createdAt: createdAt,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      paymentMethod: paymentMethod,
      total: total,
      items: items,
      sellerOrders: sellerOrders,
      raw: {
        ...raw,
        'seller_orders': [
          for (final s in sellerOrders)
            {
              'id': s.id,
              'seller': {'name': s.sellerName, 'phone': s.sellerPhone},
              'bag': s.bag?.toJson(),
            },
        ],
      },
    );
  }

  /// [fresh], keeping this order's bags if [fresh] came without any.
  RiderPopupOrder keepBagsIn(RiderPopupOrder fresh) =>
      !fresh.hasBag && hasBag ? fresh.withSellerOrders(sellerOrders) : fresh;

  @override
  List<Object?> get props => [id, status, items, sellerOrders];
}
