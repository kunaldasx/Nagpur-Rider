# Return pickup flow (rider)

Return orders only. Normal delivery orders keep using `PickupRouteMapPage` and are not affected.

```
Swipe to accept ──▶ ReturnPickupMapPage (opens by itself)
                      Step 1: route to customer · Start (in-app nav) · Steps · Call
                        arrive (GPS within ~60 m, nav arrival, or "I've reached customer")
                        → POST return-pickups/{id}/arrived   (customer gets "rider is here")
                        → swipe "Package collected"          (PUT status picked_up)
                      Step 2: route to seller · Start · Steps · Call seller
                        arrive → swipe "Delivered to seller" (PUT status delivered_to_seller)
                      Return completed → Back to orders
```

Reopening a pickup (My Pickups → details → Go to customer / seller location) opens the same map on the step that matches `pickup_status`. Arrival is remembered on the phone, so reopening doesn't notify the customer twice.

| Piece | File |
|---|---|
| Map page | `lib/screens/feed_page/view/map/return_pickup/return_pickup_map_page.dart` |
| Bottom card, items list, completed card | `.../return_pickup/return_pickup_sheet.dart` |
| Step / destination / phone logic | `.../return_pickup/return_pickup_flow.dart` |
| API calls | `lib/screens/feed_page/repo/return_order_repo.dart` |

## Backend contract

### New: rider reached the customer

```
POST /api/delivery-boy/return-pickups/{id}/arrived
→ 200 {"success": true, "message": "Customer notified"}
```

The backend should push a notification to the customer of that return, e.g. *"Your rider is here to pick up your return"*. If the call fails or returns `success: false`, the rider sees "Couldn't notify the customer. Please call them." with a **Notify again** button, and can still continue with the pickup.

### Existing, unchanged

- `PUT /api/delivery-boy/return-pickups/{id}/status` with `{"status": "picked_up"}` or `{"status": "delivered_to_seller"}`.

### Data the map uses

- Customer location: `order.shipping_latitude` / `order.shipping_longitude`, else the first `delivery_route.route_details` stop.
- Seller location: `store.latitude` / `store.longitude`, else the last route stop.
- Customer phone: `order.shipping_phone`, else `user.phone`.
- Seller phone: `store.phone`. **Not sent today.** Add it to the store object so "Call seller" works.
