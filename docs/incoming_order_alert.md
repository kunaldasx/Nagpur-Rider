# Incoming order alert (Android)

When an order is assigned to a rider, the phone rings like an incoming call until the rider accepts it, including when the app is closed or swiped away from recents.

## How it works

```
Backend ──FCM data-only, high priority──▶ RiderMessagingService (Kotlin)
                                            │ dedupe by order_id
                                            ▼
                                     OrderAlertService (foreground service, mediaPlayback)
                                       • phone's ringtone, looping, alarm stream (rings on silent)
                                       • vibration, audio focus (pauses during phone calls)
                                       • notification with one action: ACCEPT ORDER
                                       • full-screen IncomingOrderActivity when locked / screen off
                                            │ rider taps Accept
                                            ▼
                                     MainActivity → MethodChannel → Flutter
                                       AlertAcceptCubit: POST /orders/{id}/accept
                                         success      → stop ringing, open bag scan / order details
                                         refused      → stop ringing, show server message
                                         no network   → keep ringing, "Try again"
                                         401          → stop ringing, log out
```

| Piece | File |
|---|---|
| FCM entry point | `android/.../orderalert/RiderMessagingService.kt` |
| Ringing + notification | `android/.../orderalert/OrderAlertService.kt` |
| Lock-screen screen | `android/.../orderalert/IncomingOrderActivity.kt` |
| Pending alerts, dedupe | `android/.../orderalert/OrderAlertStore.kt` |
| Flutter bridge | `android/.../orderalert/OrderAlertChannel.kt`, `lib/utils/services/order_alert_bridge.dart` |
| Accept flow | `lib/screens/feed_page/rider_popup/cubit/alert_accept_cubit.dart`, `view/alert_accept_layer.dart` |
| Permission check on going online | `lib/utils/services/order_alert_permissions.dart` |

## Backend contract

### New order → the assigned rider's FCM token

Must be **data-only** (no `notification` block) and **high priority**. With a `notification` block Android shows it by itself when the app is in the background, and no app code runs, so nothing rings.

```json
{
  "message": {
    "token": "<rider fcm token>",
    "android": { "priority": "high" },
    "data": {
      "type": "new_order",
      "order_id": "48213",
      "pickup": "Sharma Kirana",
      "drop": "Dharampeth",
      "distance_km": "3.2",
      "amount": "420",
      "payment_method": "cod"
    }
  }
}
```

Only `type` and `order_id` are required. FCM data values must be strings.

Sending the same `order_id` again is safe: it doesn't ring twice, and it is ignored for 6 hours after the order was accepted or cancelled.

### Stop ringing → the same rider

```json
{
  "message": {
    "token": "<rider fcm token>",
    "android": { "priority": "high" },
    "data": { "type": "order_alert_cancel", "order_id": "48213", "reason": "cancelled" }
  }
}
```

Send it when the order is cancelled (or, later, reassigned). Without it, a cancelled order keeps ringing until the rider taps Accept and the backend refuses.

### Accept: `POST /orders/{id}/accept`

- `success: true` only if the order is still assigned to this rider. The ringing stops after this.
- `success: false` with a clear `message` when it isn't ("This order was cancelled"). The ringing stops and the rider sees the message.
- 5xx or no response: the app keeps ringing and lets the rider retry.
- Accepting twice should return `success: true` (or a clear message), not a 500.

### Gaps on the backend today

There is no timeout or reassignment, so the app rings until the rider accepts. If the rider's phone is off, has no internet, or the app was force-stopped, the order stays with that rider and nobody is told. Recommended next step: if an order isn't accepted within N minutes, alert a dispatcher, and send `order_alert_cancel` before reassigning it.

## What Android allows

| Situation | Rings? |
|---|---|
| App open | Yes |
| App in background | Yes |
| App swiped from recents | Yes: high-priority FCM may start the alert service |
| Screen off / locked | Yes; full-screen order screen shows (if the full-screen permission is on) |
| Phone on silent / vibrate | Yes, at alarm volume |
| Alarm volume at 0 | No sound, vibration only (the app warns when going online) |
| Do Not Disturb | Usually yes: alarms are allowed in DND by default, but the rider can turn that off |
| During a phone call | Pauses, resumes after the call |
| Doze / long idle | Yes for high-priority FCM; Android may downgrade priority if many high-priority messages don't show a notification |
| Xiaomi / Oppo / Vivo / Realme / OnePlus with battery saver | Conditional: needs Autostart on and battery "No restrictions" |
| App never opened since this update | No: the app tells the native side the rider is logged in on start |
| App force-stopped (Settings → Force stop) | **No.** Android delivers no FCM until the app is opened again |
| Phone off / no internet | **No**, until it reconnects (FCM keeps the message up to 4 weeks) |
| Rider logged out | No, by design |
| Phone rebooted while ringing | No, until the app is opened (Android 15 forbids starting this service at boot) |

If Android refuses to start the foreground service (Android 12+ when the message wasn't delivered as high priority, or the app is restricted), a backup notification rings with `FLAG_INSISTENT`. That repeats until the rider opens the notification shade, not until accept.

### Full-screen screen on Android 14+

`USE_FULL_SCREEN_INTENT` is granted by default to calling and alarm apps; others may have it off. The app checks `canUseFullScreenIntent()` when the rider goes online and offers the settings page. Without it, the rider gets a heads-up notification with Accept instead.

## Testing checklist

Test on at least Android 10, 12, 13, 14 and 15/16, plus one Xiaomi or Oppo/Vivo phone.

For each of these app states: **open**, **background**, **swiped from recents**, **screen off**, **locked with PIN**, **phone on silent**, **Do Not Disturb**:

- [ ] Rings within a few seconds of sending `new_order`
- [ ] Notification shows the order and only an ACCEPT ORDER action
- [ ] Locked / screen off: full-screen order screen appears; Accept asks for the PIN, then opens the app
- [ ] Accept → "Accepting order…" → ringing stops only after the backend says success → bag scan or order details opens
- [ ] Swiping the notification away brings it back; ringing continues

Edge cases:

- [ ] Send the same `new_order` twice → rings once
- [ ] Send `new_order` for two orders → rings once, "1 more order waiting", the oldest is offered first; accepting it offers the next
- [ ] Airplane mode, tap Accept → "Couldn't accept", still ringing; reconnect, Try again → accepted
- [ ] Backend returns `success: false` → ringing stops, message shown
- [ ] `order_alert_cancel` while ringing → ringing stops, screen closes
- [ ] Double-tap Accept → one API call
- [ ] Incoming phone call while ringing → pauses, resumes after
- [ ] Log out while ringing → stops; `new_order` while logged out → nothing rings
- [ ] Force stop the app, send `new_order` → nothing (expected); open app → works again
- [ ] Android 13+: notifications denied → the going-online dialog asks for them
- [ ] Android 14+: full-screen permission off → dialog offers it; heads-up still shows
- [ ] Alarm volume 0 → going-online dialog warns
- [ ] Battery optimization: "Allow" shows the system dialog
- [ ] Message sent with a `notification` block (wrong format) → confirm it does NOT ring, so the backend format is verified

Useful commands:

```bash
adb logcat -s OrderAlertService RiderMessagingService OrderAlertChannel
adb shell dumpsys activity services com.nagpurmart.rider
adb shell am force-stop com.nagpurmart.rider
adb shell dumpsys deviceidle force-idle
```
