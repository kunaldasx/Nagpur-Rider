/// The documented available-orders response, without alternate API fields.
const Map<String, dynamic> availableOrdersSample = {
  "success": true,
  "message": "Orders fetched successfully",
  "data": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 10,
    "total": 1,
    "from": 1,
    "to": 1,
    "orders": [
      {
        "id": 8801,
        "order_number": "NM-20260930-AB3XK9ZM",
        "order_mode": "regular",
        "status": "pending",
        "created_at": "2026-09-30T10:00:00.000000Z",
        "customer": {
          "name": "Customer Name",
          "phone": "+911234567890",
          "address": "12 Example Road, Nagpur, Maharashtra, 440001",
        },
        "payment_method": "cod",
        "total": 499.0,
        "delivery_route": null,
        "items": [
          {
            "id": 9901,
            "product_id": 440,
            "product_name": "Example Product",
            "variant_name": "500 g",
            "status": "preparing",
            "quantity": 2,
            "subtotal": 499.0,
            "store": {
              "id": 10,
              "name": "Store One",
              "contact_number": "+919876543210",
            },
          },
        ],
        "seller_orders": [
          {
            "id": 701,
            "seller": {
              "id": 22,
              "name": "Seller Name",
              "phone": "+919999999999",
            },
            "bag": {
              "id": 33,
              "barcode": "BAG-000033",
              "pickup_status": "assigned",
              "picked_up_at": null,
              "picked_up_by_delivery_boy_id": null,
            },
          },
        ],
      },
    ],
  },
};
