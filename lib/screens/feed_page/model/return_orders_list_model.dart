import 'package:nagpur_rider/utils/services/json_parser.dart';

const String modelName = 'return_orders_list_model';

class ReturnOrderModel {
  bool? success;
  String? message;
  Data? data;

  ReturnOrderModel({this.success, this.message, this.data});

  factory ReturnOrderModel.fromJson(Map<String, dynamic> json) {
    return ReturnOrderModel(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data:
          json['data'] != null
              ? Data.fromJson(json['data'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  int? from;
  int? to;
  List<Pickups>? pickups;

  Data({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.from,
    this.to,
    this.pickups,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      currentPage: JsonParser.intValue(json['current_page'] ?? 0),
      lastPage: JsonParser.intValue(json['last_page'] ?? 0),
      perPage: JsonParser.intValue(json['per_page'] ?? 0),
      total: JsonParser.intValue(json['total'] ?? 0),
      from: JsonParser.intValue(json['from'] ?? 0),
      to: JsonParser.intValue(json['to'] ?? 0),
      pickups: JsonParser.list<Pickups>(
        json['pickups'],
        (v) => Pickups.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    data['from'] = from;
    data['to'] = to;
    if (pickups != null) {
      data['pickups'] = pickups!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Pickups {
  int? id;
  int? orderId;
  int? orderItemId;
  int? userId;
  int? sellerId;
  int? storeId;
  int? deliveryBoyId;
  String? reason;
  String? refundAmount;
  String? sellerComment;
  String? pickupStatus;
  String? returnStatus;
  String? sellerApprovedAt;
  String? pickedUpAt;
  String? receivedAt;
  String? refundProcessedAt;
  List<String>? images;
  DeliveryRoute? deliveryRoute;
  Earnings? earnings;
  DeliveryZone? deliveryZone;
  Order? order;
  OrderItem? orderItem;
  Store? store;
  User? user;
  String? createdAt;
  String? updatedAt;

  Pickups({
    this.id,
    this.orderId,
    this.orderItemId,
    this.userId,
    this.sellerId,
    this.storeId,
    this.deliveryBoyId,
    this.reason,
    this.refundAmount,
    this.sellerComment,
    this.pickupStatus,
    this.returnStatus,
    this.sellerApprovedAt,
    this.pickedUpAt,
    this.receivedAt,
    this.refundProcessedAt,
    this.images,
    this.deliveryRoute,
    this.earnings,
    this.deliveryZone,
    this.order,
    this.orderItem,
    this.store,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory Pickups.fromJson(Map<String, dynamic> json) {
    return Pickups(
      id: JsonParser.intValue(json['id']),
      orderId: JsonParser.intValue(json['order_id']),
      orderItemId: JsonParser.intValue(json['order_item_id']),
      userId: JsonParser.intValue(json['user_id']),
      sellerId: JsonParser.intValue(json['seller_id']),
      storeId: JsonParser.intValue(json['store_id']),
      deliveryBoyId: JsonParser.intValue(json['delivery_boy_id']),
      reason: JsonParser.string(json['reason']),
      refundAmount: JsonParser.string(json['refund_amount']),
      sellerComment: JsonParser.string(json['seller_comment']),
      pickupStatus: JsonParser.string(json['pickup_status']),
      returnStatus: JsonParser.string(json['return_status']),
      sellerApprovedAt: JsonParser.string(json['seller_approved_at']),
      pickedUpAt: JsonParser.string(json['picked_up_at']),
      receivedAt: JsonParser.string(json['received_at']),
      refundProcessedAt: JsonParser.string(json['refund_processed_at']),
      images: JsonParser.list<String>(
        json['images'],
        (v) => JsonParser.string(v),
      ),
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
      deliveryZone:
          json['delivery_zone'] != null
              ? DeliveryZone.fromJson(
                json['delivery_zone'] as Map<String, dynamic>,
              )
              : null,
      order:
          json['order'] != null
              ? Order.fromJson(json['order'] as Map<String, dynamic>)
              : null,
      orderItem:
          json['order_item'] != null
              ? OrderItem.fromJson(json['order_item'] as Map<String, dynamic>)
              : null,
      store:
          json['store'] != null
              ? Store.fromJson(json['store'] as Map<String, dynamic>)
              : null,
      user:
          json['user'] != null
              ? User.fromJson(json['user'] as Map<String, dynamic>)
              : null,
      createdAt: JsonParser.string(json['created_at']),
      updatedAt: JsonParser.string(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_id'] = orderId;
    data['order_item_id'] = orderItemId;
    data['user_id'] = userId;
    data['seller_id'] = sellerId;
    data['store_id'] = storeId;
    data['delivery_boy_id'] = deliveryBoyId;
    data['reason'] = reason;
    data['refund_amount'] = refundAmount;
    data['seller_comment'] = sellerComment;
    data['pickup_status'] = pickupStatus;
    data['return_status'] = returnStatus;
    data['seller_approved_at'] = sellerApprovedAt;
    data['picked_up_at'] = pickedUpAt;
    data['received_at'] = receivedAt;
    data['refund_processed_at'] = refundProcessedAt;
    data['images'] = images;
    if (deliveryRoute != null) {
      data['delivery_route'] = deliveryRoute!.toJson();
    }
    if (earnings != null) {
      data['earnings'] = earnings!.toJson();
    }
    if (deliveryZone != null) {
      data['delivery_zone'] = deliveryZone!.toJson();
    }
    if (order != null) {
      data['order'] = order!.toJson();
    }
    if (orderItem != null) {
      data['order_item'] = orderItem!.toJson();
    }
    if (store != null) {
      data['store'] = store!.toJson();
    }
    if (user != null) {
      data['user'] = user!.toJson();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class DeliveryRoute {
  num? totalDistance;
  List<int>? route;
  List<RouteDetails>? routeDetails;

  DeliveryRoute({this.totalDistance, this.route, this.routeDetails});

  factory DeliveryRoute.fromJson(Map<String, dynamic> json) {
    return DeliveryRoute(
      totalDistance: JsonParser.doubleValue(
        json['total_distance'],
      ), // num can accept double
      route: JsonParser.list<int>(json['route'], (v) => JsonParser.intValue(v)),
      routeDetails: JsonParser.list<RouteDetails>(
        json['route_details'],
        (v) => RouteDetails.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_distance'] = totalDistance;
    data['route'] = route;
    if (routeDetails != null) {
      data['route_details'] = routeDetails!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RouteDetails {
  int? storeId;
  String? storeName;
  num? distanceFromCustomer;
  String? address;
  String? city;
  String? landmark;
  String? state;
  String? zipcode;
  String? country;
  String? countryCode;
  double? latitude;
  double? longitude;
  num? distanceFromPrevious;

  RouteDetails({
    this.storeId,
    this.storeName,
    this.distanceFromCustomer,
    this.address,
    this.city,
    this.landmark,
    this.state,
    this.zipcode,
    this.country,
    this.countryCode,
    this.latitude,
    this.longitude,
    this.distanceFromPrevious,
  });

  factory RouteDetails.fromJson(Map<String, dynamic> json) {
    return RouteDetails(
      storeId: JsonParser.intValue(json['store_id']),
      storeName: JsonParser.string(json['store_name']),
      distanceFromCustomer: JsonParser.doubleValue(
        json['distance_from_customer'],
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
      distanceFromPrevious: JsonParser.doubleValue(
        json['distance_from_previous'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['store_id'] = storeId;
    data['store_name'] = storeName;
    data['distance_from_customer'] = distanceFromCustomer;
    data['address'] = address;
    data['city'] = city;
    data['landmark'] = landmark;
    data['state'] = state;
    data['zipcode'] = zipcode;
    data['country'] = country;
    data['country_code'] = countryCode;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['distance_from_previous'] = distanceFromPrevious;
    return data;
  }
}

class Earnings {
  int? total;
  Breakdown? breakdown;

  Earnings({this.total, this.breakdown});

  factory Earnings.fromJson(Map<String, dynamic> json) {
    return Earnings(
      total: JsonParser.intValue(json['total']),
      breakdown:
          json['breakdown'] != null
              ? Breakdown.fromJson(json['breakdown'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total'] = total;
    if (breakdown != null) {
      data['breakdown'] = breakdown!.toJson();
    }
    return data;
  }
}

class Breakdown {
  int? baseFee;
  int? perStorePickupFee;
  int? distanceBasedFee;
  int? perOrderIncentive;

  Breakdown({
    this.baseFee,
    this.perStorePickupFee,
    this.distanceBasedFee,
    this.perOrderIncentive,
  });

  factory Breakdown.fromJson(Map<String, dynamic> json) {
    return Breakdown(
      baseFee: JsonParser.intValue(json['base_fee']),
      perStorePickupFee: JsonParser.intValue(json['per_store_pickup_fee']),
      distanceBasedFee: JsonParser.intValue(json['distance_based_fee']),
      perOrderIncentive: JsonParser.intValue(json['per_order_incentive']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['base_fee'] = baseFee;
    data['per_store_pickup_fee'] = perStorePickupFee;
    data['distance_based_fee'] = distanceBasedFee;
    data['per_order_incentive'] = perOrderIncentive;
    return data;
  }
}

class DeliveryZone {
  int? id;
  String? name;

  DeliveryZone({this.id, this.name});

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: JsonParser.intValue(json['id']),
      name: JsonParser.string(json['name']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}

class Order {
  int? id;
  String? uuid;
  String? shippingName;
  String? shippingPhone;
  String? shippingAddress1;
  String? shippingAddress2;
  String? shippingLandmark;
  String? shippingCity;
  String? shippingState;
  String? shippingZip;
  String? shippingCountry;
  String? shippingLatitude;
  String? shippingLongitude;

  Order({
    this.id,
    this.uuid,
    this.shippingName,
    this.shippingPhone,
    this.shippingAddress1,
    this.shippingAddress2,
    this.shippingLandmark,
    this.shippingCity,
    this.shippingState,
    this.shippingZip,
    this.shippingCountry,
    this.shippingLatitude,
    this.shippingLongitude,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: JsonParser.intValue(json['id']),
      uuid: JsonParser.string(json['uuid']),
      shippingName: JsonParser.string(json['shipping_name']),
      shippingPhone: JsonParser.string(json['shipping_phone']),
      shippingAddress1: JsonParser.string(json['shipping_address_1']),
      shippingAddress2: JsonParser.string(json['shipping_address_2']),
      shippingLandmark: JsonParser.string(json['shipping_landmark']),
      shippingCity: JsonParser.string(json['shipping_city']),
      shippingState: JsonParser.string(json['shipping_state']),
      shippingZip: JsonParser.string(json['shipping_zip']),
      shippingCountry: JsonParser.string(json['shipping_country']),
      shippingLatitude: JsonParser.string(json['shipping_latitude']),
      shippingLongitude: JsonParser.string(json['shipping_longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['shipping_name'] = shippingName;
    data['shipping_phone'] = shippingPhone;
    data['shipping_address_1'] = shippingAddress1;
    data['shipping_address_2'] = shippingAddress2;
    data['shipping_landmark'] = shippingLandmark;
    data['shipping_city'] = shippingCity;
    data['shipping_state'] = shippingState;
    data['shipping_zip'] = shippingZip;
    data['shipping_country'] = shippingCountry;
    data['shipping_latitude'] = shippingLatitude;
    data['shipping_longitude'] = shippingLongitude;
    return data;
  }
}

class OrderItem {
  int? id;
  Product? product;
  Variant? variant;

  OrderItem({this.id, this.product, this.variant});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: JsonParser.intValue(json['id']),
      product:
          json['product'] != null
              ? Product.fromJson(json['product'] as Map<String, dynamic>)
              : null,
      variant:
          json['variant'] != null
              ? Variant.fromJson(json['variant'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (product != null) {
      data['product'] = product!.toJson();
    }
    if (variant != null) {
      data['variant'] = variant!.toJson();
    }
    return data;
  }
}

class Product {
  int? id;
  String? name;

  Product({this.id, this.name});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: JsonParser.intValue(json['id']),
      name: JsonParser.string(json['name']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}

class Variant {
  int? id;
  String? sku;
  String? title;

  Variant({this.id, this.sku, this.title});

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: JsonParser.intValue(json['id']),
      sku: JsonParser.string(json['sku']),
      title: JsonParser.string(json['title']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sku'] = sku;
    data['title'] = title;
    return data;
  }
}

class Store {
  int? id;
  String? name;
  String? address;
  String? city;
  String? state;
  String? zipcode;
  String? country;
  String? latitude;
  String? longitude;

  Store({
    this.id,
    this.name,
    this.address,
    this.city,
    this.state,
    this.zipcode,
    this.country,
    this.latitude,
    this.longitude,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: JsonParser.intValue(json['id']),
      name: JsonParser.string(json['name']),
      address: JsonParser.string(json['address']),
      city: JsonParser.string(json['city']),
      state: JsonParser.string(json['state']),
      zipcode: JsonParser.string(json['zipcode']),
      country: JsonParser.string(json['country']),
      latitude: JsonParser.string(json['latitude']),
      longitude: JsonParser.string(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['address'] = address;
    data['city'] = city;
    data['state'] = state;
    data['zipcode'] = zipcode;
    data['country'] = country;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    return data;
  }
}

class User {
  int? id;
  String? name;
  String? phone;
  String? email;

  User({this.id, this.name, this.phone, this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: JsonParser.intValue(json['id']),
      name: JsonParser.string(json['name']),
      phone: JsonParser.string(json['phone']),
      email: JsonParser.string(json['email']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['phone'] = phone;
    data['email'] = email;
    return data;
  }
}
