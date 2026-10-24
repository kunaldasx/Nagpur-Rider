# Return pickup flow (rider)

Return orders only. Normal deliveries keep using `PickupRouteMapPage`.

```text
Swipe to accept → POST return-pickups/{id}/accept
  Server assigns the rider and sends the customer a six-digit pickup OTP
  Open ReturnPickupMapPage with the returned data.pickup
    Step 1: route to customer · Start · Steps · Call customer
      Arrival: GPS, navigation arrival, or manual confirmation (local only)
      Swipe Package collected → enter customer's OTP → PUT status picked_up
        Server verifies the OTP, records pickup, sends a separate seller OTP
    Step 2: route to seller · Start · Steps · Call customer
      Arrival confirmation (local only)
      Swipe Delivered to seller → enter seller's OTP → PUT status delivered_to_seller
        Server verifies seller OTP and completes the return/refund
    Return completed → Back to orders
```

Both OTPs are mandatory. The app never receives OTPs or hashes from the backend and never stores entered OTPs in preferences or files. Leading zeros are preserved. Return status request bodies and OTP event contents are excluded from logs.

## API contract

All endpoints use the rider's Bearer token and JSON request/response headers.

| Action | Request |
|---|---|
| Available returns | `GET /api/delivery-boy/return-pickups/available?per_page=10&page=1` |
| Accept | `POST /api/delivery-boy/return-pickups/{id}/accept` |
| Collect | `PUT /api/delivery-boy/return-pickups/{id}/status` with `{"status":"picked_up","otp":"012345"}` |
| Hand over | Same status endpoint with `{"status":"delivered_to_seller","otp":"007890"}` |
| My returns | `GET /api/delivery-boy/return-pickups/my?per_page=10&page=1` |
| Details | `GET /api/delivery-boy/return-pickups/{id}` |

Accept, status, and detail responses use `{success, message, data: {pickup}}`. Lists contain pagination and `data.pickups`. Successful handoffs replace the displayed pickup with the server resource, rather than changing status optimistically.

There is no return-arrival notification endpoint in this backend contract. Arrival prompts and saved arrival flags are local; the UI does not claim to notify the customer. Saved arrival flags are cleared on completion. Reopening resumes from `pickup_status`.

## Errors and recovery

- Invalid/missing OTP (`422`, `invalid_otp`): keep the current leg and let the rider correct the code.
- Customer SMS failure during acceptance (`503`, `otp_delivery_failed`): do not open the map or remove the return as accepted.
- Seller SMS failure during pickup (`503`, `otp_delivery_failed`): pickup remains `assigned`; keep the OTP dialog open for retry. Do not switch to the seller leg.
- Invalid transition (`409`, `invalid_transition`): fetch return details and reconcile the map with the backend status. Never report the rejected request as verified. If refresh fails, retain the current leg and show the error.
- Network failures: show a retryable error in debug and release builds.
- Disable repeated submissions and dismissal while verification is in flight. Canceling an idle OTP dialog sends no status request.

The contract specifies no resend endpoint, expiry interval, or attempt limit. The app does not invent these or generate OTPs locally.

## Shared handoff UI

`return_handoff_dialog.dart` is the only UI that dispatches `UpdateReturnOrderStatus`. The map swipes, pickup-details Update Status button, and My Pickups card all open it. Each dialog owns its status BLoC, so an underlying page cannot double-toast or react to another return's verification. Success/conflict refreshes My Pickups; details refresh after the dialog closes.

## Map and contact data

- Customer pin: `order.shipping_latitude` / `shipping_longitude`, else the first backend route stop.
- Seller pin: `store.latitude` / `longitude`, else the last backend route stop.
- Road directions, alternatives, voice guidance, and arrival detection remain in the app.
- Every Call button calls `order.shipping_phone`, falling back to `user.phone`. Although the API can include `store.contact_number`, seller calling remains disabled by product choice.

## Verification

Automated tests cover helper logic, sheets, customer/seller OTP entry, leading zeros, invalid OTP, SMS failures, repeated submissions, stale-status reconciliation, returned pickup resources, network errors, and small-screen layouts in all six languages.

Device testing with the backend is still required for actual SMS delivery, valid/invalid customer and seller codes, live GPS/navigation, calls, and refund completion.
