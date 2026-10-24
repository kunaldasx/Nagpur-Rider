import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nagpur_rider/screens/feed_page/model/return_orders_list_model.dart';
import 'package:nagpur_rider/screens/feed_page/view/map/return_pickup/return_pickup_flow.dart';

Pickups _pickup(Map<String, dynamic> overrides) => Pickups.fromJson({
  'id': 1042,
  'pickup_status': 'pending',
  'reason': 'Damaged product',
  'order': {
    'shipping_name': 'Rahul Verma',
    'shipping_phone': '+91 98765-43210',
    'shipping_address_1': 'Plot 12',
    'shipping_city': 'Nagpur',
    'shipping_latitude': '21.1500',
    'shipping_longitude': '79.0800',
  },
  'store': {
    'name': 'Sharma Kirana',
    'address': 'Dharampeth',
    'city': 'Nagpur',
    'latitude': '21.1350',
    'longitude': '79.0600',
  },
  'order_item': {
    'product': {'name': 'Dettol Handwash'},
    'variant': {'title': '750 ml'},
  },
  ...overrides,
});

void main() {
  group('legFor', () {
    test('maps pickup status to the trip the rider is on', () {
      expect(ReturnPickupFlow.legFor('pending'), ReturnPickupLeg.toCustomer);
      expect(ReturnPickupFlow.legFor('assigned'), ReturnPickupLeg.toCustomer);
      expect(ReturnPickupFlow.legFor(null), ReturnPickupLeg.toCustomer);
      expect(ReturnPickupFlow.legFor('picked_up'), ReturnPickupLeg.toSeller);
      expect(
        ReturnPickupFlow.legFor('delivered_to_seller'),
        ReturnPickupLeg.completed,
      );
    });
  });

  group('destinations', () {
    test('customer comes from the order, seller from the store', () {
      final pickup = _pickup({});
      expect(
        ReturnPickupFlow.customerLocation(pickup),
        const LatLng(21.15, 79.08),
      );
      expect(
        ReturnPickupFlow.sellerLocation(pickup),
        const LatLng(21.135, 79.06),
      );
      expect(
        ReturnPickupFlow.destinationFor(pickup, ReturnPickupLeg.toSeller),
        const LatLng(21.135, 79.06),
      );
    });

    test('falls back to the route stops when coordinates are missing', () {
      final pickup = _pickup({
        'order': {'shipping_name': 'Rahul'},
        'store': {'name': 'Sharma Kirana'},
        'delivery_route': {
          'route_details': [
            {'latitude': 21.2, 'longitude': 79.1},
            {'latitude': 21.3, 'longitude': 79.2, 'store_name': 'Stop'},
          ],
        },
      });
      expect(
        ReturnPickupFlow.customerLocation(pickup),
        const LatLng(21.2, 79.1),
      );
      expect(ReturnPickupFlow.sellerLocation(pickup), const LatLng(21.3, 79.2));
    });

    test('treats 0,0 and garbage as no location', () {
      final pickup = _pickup({
        'order': {'shipping_latitude': '0', 'shipping_longitude': '0'},
        'store': {'latitude': 'abc', 'longitude': ''},
        'delivery_route': {
          'route_details': [
            {'latitude': null, 'longitude': null},
          ],
        },
      });
      expect(ReturnPickupFlow.customerLocation(pickup), isNull);
      expect(ReturnPickupFlow.sellerLocation(pickup), isNull);
    });

    test('rejects non-finite and out-of-range coordinates', () {
      for (final coordinates in [
        ['NaN', '79'],
        ['21', 'Infinity'],
        ['91', '79'],
        ['21', '-181'],
      ]) {
        final pickup = _pickup({
          'order': {
            'shipping_latitude': coordinates[0],
            'shipping_longitude': coordinates[1],
          },
          'store': {'latitude': coordinates[0], 'longitude': coordinates[1]},
        });
        expect(ReturnPickupFlow.customerLocation(pickup), isNull);
        expect(ReturnPickupFlow.sellerLocation(pickup), isNull);
      }
    });

    test('uses the last route stop even when there is only one', () {
      final pickup = _pickup({
        'store': <String, dynamic>{},
        'delivery_route': {
          'route_details': [
            {'latitude': 21.3, 'longitude': 79.2},
          ],
        },
      });
      expect(ReturnPickupFlow.sellerLocation(pickup), const LatLng(21.3, 79.2));
    });
  });

  group('contact details', () {
    test('cleans the customer phone and falls back to the user', () {
      expect(ReturnPickupFlow.customerPhone(_pickup({})), '+919876543210');
      final fromUser = _pickup({
        'order': {'shipping_phone': ''},
        'user': {'name': 'Rahul', 'phone': '9000000001'},
      });
      expect(ReturnPickupFlow.customerPhone(fromUser), '9000000001');
    });

    test('customer phone is null when neither number was sent', () {
      final noPhone = _pickup({
        'order': {'shipping_phone': ''},
        'user': {'name': 'Rahul'},
      });
      expect(ReturnPickupFlow.customerPhone(noPhone), isNull);
    });

    test('names and addresses', () {
      final pickup = _pickup({});
      expect(ReturnPickupFlow.customerName(pickup), 'Rahul Verma');
      expect(ReturnPickupFlow.customerAddress(pickup), 'Plot 12, Nagpur');
      expect(ReturnPickupFlow.sellerName(pickup), 'Sharma Kirana');
      expect(ReturnPickupFlow.sellerAddress(pickup), 'Dharampeth, Nagpur');
    });
  });

  test('item title joins product and variant', () {
    expect(ReturnPickupFlow.itemTitle(_pickup({})), 'Dettol Handwash · 750 ml');
    final noVariant = _pickup({
      'order_item': {
        'product': {'name': 'Soap'},
      },
    });
    expect(ReturnPickupFlow.itemTitle(noVariant), 'Soap');
  });
}
