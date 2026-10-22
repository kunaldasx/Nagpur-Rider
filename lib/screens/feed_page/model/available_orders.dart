import 'package:nagpur_rider/utils/services/json_parser.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/model/rider_popup_order.dart';
import 'package:nagpur_rider/screens/feed_page/rider_popup/model/rider_popup_order.dart'
    as rider_bag;

const String modelName = 'available_orders_model';

class AvailableOrdersResponse {
  final bool success;
  final String message;
  final AvailableOrdersData data;

  AvailableOrdersResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AvailableOrdersResponse.fromJson(Map<String, dynamic> json) {
    return AvailableOrdersResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: AvailableOrdersData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class AvailableOrdersData {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int from;
  final int to;
  final List<Orders> orders;

  AvailableOrdersData({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
    required this.orders,
  });

  factory AvailableOrdersData.fromJson(Map<String, dynamic> json) {
    return AvailableOrdersData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 0),
      lastPage: JsonParser.intValue(json['last_page'] ?? 0),
      perPage: JsonParser.intValue(json['per_page'] ?? 0),
      total: JsonParser.intValue(json['total'] ?? 0),
      from: JsonParser.intValue(json['from'] ?? 0),
      to: JsonParser.intValue(json['to'] ?? 0),
      orders: JsonParser.list<Orders>(
        json['orders'],
        (order) => Orders.fromJson(order as Map<String, dynamic>),
      ),
    );
  }
}

class Orders {
  final int? id;
  final String? uuid;
  final String? slug;
  final String? status;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? fulfillmentType;
  final int? estimatedDeliveryTime;
  final int? deliveryTimeSlotId;
  final int? deliveryBoyId;
  final String? deliveryCharge;
  final String? subtotal;
  final String? totalPayable;
  final String? orderNote;
  final String? finalTotal;
  final String? shippingName;
  final String? shippingAddress1;
  final String? shippingAddress2;
  final String? shippingLandmark;
  final String? shippingZip;
  final String? shippingPhone;
  final String? shippingPhonecode;
  final String? shippingAddressType;
  final String? shippingLatitude;
  final String? shippingLongitude;
  final String? shippingCity;
  final String? shippingState;
  final String? shippingCountry;
  final DeliveryRoute? deliveryRoute;
  final Earnings? earnings;
  final List<Items>? items;
  final DeliveryZone? deliveryZone;
  final int? otpVerified;
  final String? createdAt;
  final String? updatedAt;
  final String? total;
  final String? cancelReason;
  final String? cancelledBy;

  /// Per-seller share of the order with the bag it was packed into.
  final List<RiderSellerOrder>? sellerOrders;

  Orders({
    this.id,
    this.uuid,
    this.slug,
    this.status,
    this.paymentMethod,
    this.paymentStatus,
    this.fulfillmentType,
    this.orderNote,
    this.estimatedDeliveryTime,
    this.deliveryTimeSlotId,
    this.deliveryBoyId,
    this.deliveryCharge,
    this.subtotal,
    this.totalPayable,
    this.finalTotal,
    this.shippingName,
    this.shippingAddress1,
    this.shippingAddress2,
    this.shippingLandmark,
    this.shippingZip,
    this.shippingPhone,
    this.shippingPhonecode,
    this.shippingAddressType,
    this.shippingLatitude,
    this.shippingLongitude,
    this.shippingCity,
    this.shippingState,
    this.shippingCountry,
    this.deliveryRoute,
    this.earnings,
    this.items,
    this.deliveryZone,
    this.otpVerified,
    this.createdAt,
    this.updatedAt,
    this.total,
    this.cancelReason,
    this.cancelledBy,
    this.sellerOrders,
  });

  /// A seller bag is still to be scanned: no item may be collected yet.
  bool get needsBagScan => rider_bag.needsBagScan(sellerOrders);

  factory Orders.fromJson(Map<String, dynamic> json) {
    return Orders(
      id: JsonParser.intValue(json['id']),
      uuid: JsonParser.string(json['uuid']),
      slug: JsonParser.string(json['slug']),
      status: JsonParser.string(json['status']),
      paymentMethod: JsonParser.string(json['payment_method']),
      paymentStatus: JsonParser.string(json['payment_status']),
      fulfillmentType: JsonParser.string(json['fulfillment_type']),
      orderNote: JsonParser.string(json['order_note']),
      estimatedDeliveryTime: JsonParser.intValue(
        json['estimated_delivery_time'],
      ),
      deliveryTimeSlotId: JsonParser.intValue(json['delivery_time_slot_id']),
      deliveryBoyId: JsonParser.intValue(json['delivery_boy_id']),
      deliveryCharge: JsonParser.string(json['delivery_charge']),
      subtotal: JsonParser.string(json['subtotal']),
      totalPayable: JsonParser.string(json['total_payable']),
      finalTotal: JsonParser.string(json['final_total']),
      shippingName: JsonParser.string(json['shipping_name']),
      shippingAddress1: JsonParser.string(json['shipping_address_1']),
      shippingAddress2: JsonParser.string(json['shipping_address_2']),
      shippingLandmark: JsonParser.string(json['shipping_landmark']),
      shippingZip: JsonParser.string(json['shipping_zip']),
      shippingPhone: JsonParser.string(json['shipping_phone']),
      shippingPhonecode: JsonParser.string(json['shipping_phonecode']),
      shippingAddressType: JsonParser.string(json['shipping_address_type']),
      shippingLatitude: JsonParser.string(json['shipping_latitude']),
      shippingLongitude: JsonParser.string(json['shipping_longitude']),
      shippingCity: JsonParser.string(json['shipping_city']),
      shippingState: JsonParser.string(json['shipping_state']),
      shippingCountry: JsonParser.string(json['shipping_country']),
      deliveryRoute:
          json['delivery_route'] != null
              ? DeliveryRoute.fromJson(
                json['delivery_route'] as Map<String, dynamic>,
              )
              : null,
      earnings:
          json['earnings'] != null
              ? Earnings.fromJson(json['earnings'] as Map<String, dynamic>)
              : null,
      items: JsonParser.list<Items>(
        json['items'],
        (item) => Items.fromJson(item as Map<String, dynamic>),
      ),
      deliveryZone:
          json['delivery_zone'] != null
              ? DeliveryZone.fromJson(
                json['delivery_zone'] as Map<String, dynamic>,
              )
              : null,
      otpVerified: JsonParser.intValue(json['otp_verified']),
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
      total: JsonParser.string(json['total']),
      cancelReason: JsonParser.string(
        json['cancel_reason'] ??
            json['cancellation_reason'] ??
            json['cancelled_reason'],
      ),
      cancelledBy: JsonParser.string(
        json['cancelled_by'] ?? json['canceled_by'] ?? json['cancel_by'],
      ),
      sellerOrders:
          json['seller_orders'] is List || json['pickup_bags'] is List
              ? RiderSellerOrder.listFromOrder(json)
              : null,
    );
  }

  // copyWith method remains unchanged (as it's business logic)
  Orders copyWith({
    int? id,
    String? uuid,
    String? slug,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    String? fulfillmentType,
    int? estimatedDeliveryTime,
    int? deliveryTimeSlotId,
    int? deliveryBoyId,
    String? deliveryCharge,
    String? subtotal,
    String? orderNote,
    String? totalPayable,
    String? finalTotal,
    String? shippingName,
    String? shippingAddress1,
    String? shippingAddress2,
    String? shippingLandmark,
    String? shippingZip,
    String? shippingPhone,
    String? shippingPhonecode,
    String? shippingAddressType,
    String? shippingLatitude,
    String? shippingLongitude,
    String? shippingCity,
    String? shippingState,
    String? shippingCountry,
    DeliveryRoute? deliveryRoute,
    Earnings? earnings,
    List<Items>? items,
    DeliveryZone? deliveryZone,
    int? otpVerified,
    String? createdAt,
    String? updatedAt,
    String? total,
    String? cancelReason,
    String? cancelledBy,
    List<RiderSellerOrder>? sellerOrders,
  }) {
    return Orders(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      slug: slug ?? this.slug,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      orderNote: orderNote ?? this.orderNote,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      deliveryTimeSlotId: deliveryTimeSlotId ?? this.deliveryTimeSlotId,
      deliveryBoyId: deliveryBoyId ?? this.deliveryBoyId,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      subtotal: subtotal ?? this.subtotal,
      totalPayable: totalPayable ?? this.totalPayable,
      finalTotal: finalTotal ?? this.finalTotal,
      shippingName: shippingName ?? this.shippingName,
      shippingAddress1: shippingAddress1 ?? this.shippingAddress1,
      shippingAddress2: shippingAddress2 ?? this.shippingAddress2,
      shippingLandmark: shippingLandmark ?? this.shippingLandmark,
      shippingZip: shippingZip ?? this.shippingZip,
      shippingPhone: shippingPhone ?? this.shippingPhone,
      shippingPhonecode: shippingPhonecode ?? this.shippingPhonecode,
      shippingAddressType: shippingAddressType ?? this.shippingAddressType,
      shippingLatitude: shippingLatitude ?? this.shippingLatitude,
      shippingLongitude: shippingLongitude ?? this.shippingLongitude,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingState: shippingState ?? this.shippingState,
      shippingCountry: shippingCountry ?? this.shippingCountry,
      deliveryRoute: deliveryRoute ?? this.deliveryRoute,
      earnings: earnings ?? this.earnings,
      items: items ?? this.items,
      deliveryZone: deliveryZone ?? this.deliveryZone,
      otpVerified: otpVerified ?? this.otpVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      total: total ?? this.total,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      sellerOrders: sellerOrders ?? this.sellerOrders,
    );
  }
}

class DeliveryRoute {
  final double? totalDistance;
  final List<int>? route;
  final List<RouteDetails>? routeDetails;

  DeliveryRoute({this.totalDistance, this.route, this.routeDetails});

  factory DeliveryRoute.fromJson(Map<String, dynamic> json) {
    return DeliveryRoute(
      totalDistance: JsonParser.doubleValue(json['total_distance']),
      route: JsonParser.list<int>(json['route'], (v) => JsonParser.intValue(v)),
      routeDetails: JsonParser.list<RouteDetails>(
        json['route_details'],
        (detail) => RouteDetails.fromJson(detail as Map<String, dynamic>),
      ),
    );
  }
}

class RouteDetails {
  final int? storeId;
  final String? storeName;
  final double? distanceFromCustomer;
  final double? distanceFromPrevious;
  final String? address;
  final String? city;
  final String? landmark;
  final String? state;
  final String? zipcode;
  final String? country;
  final String? countryCode;
  final double? latitude;
  final double? longitude;

  RouteDetails({
    this.storeId,
    this.storeName,
    this.distanceFromCustomer,
    this.distanceFromPrevious,
    this.address,
    this.city,
    this.landmark,
    this.state,
    this.zipcode,
    this.country,
    this.countryCode,
    this.latitude,
    this.longitude,
  });

  factory RouteDetails.fromJson(Map<String, dynamic> json) {
    return RouteDetails(
      storeId: JsonParser.intValue(json['store_id']),
      storeName: JsonParser.string(json['store_name']),
      distanceFromCustomer: JsonParser.doubleValue(
        json['distance_from_customer'],
      ),
      distanceFromPrevious: JsonParser.doubleValue(
        json['distance_from_previous'],
      ),
      address: JsonParser.string(json['address']),
      city: JsonParser.string(json['city']),
      landmark: JsonParser.string(json['landmark']),
      state: JsonParser.string(json['state']),
      zipcode: JsonParser.string(json['zipcode']),
      country: JsonParser.string(json['country']),
      countryCode: JsonParser.string(json['country_code']),
      latitude: JsonParser.doubleValue(json['latitude']),
      longitude: JsonParser.doubleValue(json['longitude']),
    );
  }
}

class Earnings {
  final double? total;
  final EarningsBreakdown? breakdown;

  Earnings({this.total, this.breakdown});

  factory Earnings.fromJson(Map<String, dynamic> json) {
    return Earnings(
      total: JsonParser.doubleValue(json['total']),
      breakdown:
          json['breakdown'] != null
              ? EarningsBreakdown.fromJson(
                json['breakdown'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

class EarningsBreakdown {
  final double? baseFee;
  final double? perStorePickupFee;
  final double? distanceBasedFee;
  final double? perOrderIncentive;

  EarningsBreakdown({
    this.baseFee,
    this.perStorePickupFee,
    this.distanceBasedFee,
    this.perOrderIncentive,
  });

  factory EarningsBreakdown.fromJson(Map<String, dynamic> json) {
    return EarningsBreakdown(
      baseFee: JsonParser.doubleValue(json['base_fee']),
      perStorePickupFee: JsonParser.doubleValue(json['per_store_pickup_fee']),
      distanceBasedFee: JsonParser.doubleValue(json['distance_based_fee']),
      perOrderIncentive: JsonParser.doubleValue(json['per_order_incentive']),
    );
  }
}

class Items {
  final int? id;
  final int? orderId;
  final int? productId;
  final int? productVariantId;
  final int? storeId;
  final String? title;
  final String? variantTitle;
  final String? giftCardDiscount;
  final String? adminCommissionAmount;
  final String? sellerCommissionAmount;
  final String? commissionSettled;
  final String? discountedPrice;
  final String? discount;
  final String? taxAmount;
  final String? taxPercent;
  final String? sku;
  final int? quantity;
  final String? price;
  final String? subtotal;
  final String? status;
  final int? otpVerified;
  final bool reachedDestination;
  final Product? product;
  final Variant? variant;
  final Store? store;
  final String? createdAt;
  final String? updatedAt;

  Items({
    this.id,
    this.orderId,
    this.productId,
    this.productVariantId,
    this.storeId,
    this.title,
    this.variantTitle,
    this.giftCardDiscount,
    this.adminCommissionAmount,
    this.sellerCommissionAmount,
    this.commissionSettled,
    this.discountedPrice,
    this.discount,
    this.taxAmount,
    this.taxPercent,
    this.sku,
    this.quantity,
    this.price,
    this.subtotal,
    this.status,
    this.otpVerified,
    this.reachedDestination = false,
    this.product,
    this.variant,
    this.store,
    this.createdAt,
    this.updatedAt,
  });

  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(
      id: JsonParser.intValue(json['id']),
      orderId: JsonParser.intValue(json['order_id']),
      productId: JsonParser.intValue(json['product_id']),
      productVariantId: JsonParser.intValue(json['product_variant_id']),
      storeId: JsonParser.intValue(json['store_id']),
      title: JsonParser.string(json['title']),
      variantTitle: JsonParser.string(json['variant_title']),
      giftCardDiscount: JsonParser.string(json['gift_card_discount']),
      adminCommissionAmount: JsonParser.string(json['admin_commission_amount']),
      sellerCommissionAmount: JsonParser.string(
        json['seller_commission_amount'],
      ),
      commissionSettled: JsonParser.string(json['commission_settled']),
      discountedPrice: JsonParser.string(json['discounted_price']),
      discount: JsonParser.string(json['discount']),
      taxAmount: JsonParser.string(json['tax_amount']),
      taxPercent: JsonParser.string(json['tax_percent']),
      sku: JsonParser.string(json['sku']),
      quantity: JsonParser.intValue(json['quantity']),
      price: JsonParser.string(json['price']),
      subtotal: JsonParser.string(json['subtotal']),
      status: JsonParser.string(json['status']),
      otpVerified: JsonParser.intValue(json['otp_verified']),
      reachedDestination: false, // Default to false, bloc will update this
      product:
          json['product'] != null
              ? Product.fromJson(json['product'] as Map<String, dynamic>)
              : null,
      variant:
          json['variant'] != null
              ? Variant.fromJson(json['variant'] as Map<String, dynamic>)
              : null,
      store:
          json['store'] != null
              ? Store.fromJson(json['store'] as Map<String, dynamic>)
              : null,
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
    );
  }

  // copyWith remains unchanged
  Items copyWith({
    int? id,
    int? orderId,
    int? productId,
    int? productVariantId,
    int? storeId,
    String? title,
    String? variantTitle,
    String? giftCardDiscount,
    String? adminCommissionAmount,
    String? sellerCommissionAmount,
    String? commissionSettled,
    String? discountedPrice,
    String? discount,
    String? taxAmount,
    String? taxPercent,
    String? sku,
    int? quantity,
    String? price,
    String? subtotal,
    String? status,
    int? otpVerified,
    bool? reachedDestination,
    Product? product,
    Variant? variant,
    Store? store,
    String? createdAt,
    String? updatedAt,
  }) {
    return Items(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productVariantId: productVariantId ?? this.productVariantId,
      storeId: storeId ?? this.storeId,
      title: title ?? this.title,
      variantTitle: variantTitle ?? this.variantTitle,
      giftCardDiscount: giftCardDiscount ?? this.giftCardDiscount,
      adminCommissionAmount:
          adminCommissionAmount ?? this.adminCommissionAmount,
      sellerCommissionAmount:
          sellerCommissionAmount ?? this.sellerCommissionAmount,
      commissionSettled: commissionSettled ?? this.commissionSettled,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      discount: discount ?? this.discount,
      taxAmount: taxAmount ?? this.taxAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
      status: status ?? this.status,
      otpVerified: otpVerified ?? this.otpVerified,
      reachedDestination: reachedDestination ?? this.reachedDestination,
      product: product ?? this.product,
      variant: variant ?? this.variant,
      store: store ?? this.store,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Product {
  final int? id;
  final String? name;
  final String? slug;
  final String? image;
  final int? requiresOtp;

  Product({this.id, this.name, this.slug, this.image, this.requiresOtp});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: JsonParser.intValue(json['id']),
      name: JsonParser.string(json['name']),
      slug: JsonParser.string(json['slug']),
      image: JsonParser.string(json['image']),
      requiresOtp: JsonParser.intValue(json['requires_otp']),
    );
  }
}

class Variant {
  final int? id;
  final String? title;
  final String? slug;
  final String? image;

  Variant({this.id, this.title, this.slug, this.image});

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: JsonParser.intValue(json['id']),
      title: JsonParser.string(json['title']),
      slug: JsonParser.string(json['slug']),
      image: JsonParser.string(json['image']),
    );
  }
}

class Store {
  final int? id;
  final String? name;
  final String? slug;

  Store({this.id, this.name, this.slug});

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: JsonParser.intValue(json['id']),
      name: JsonParser.string(json['name']),
      slug: JsonParser.string(json['slug']),
    );
  }
}

class DeliveryZone {
  final int? id;
  final String? name;

  DeliveryZone({this.id, this.name});

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: JsonParser.intValue(json['id']),
      name: JsonParser.string(json['name']),
    );
  }
}
