# Rider duty and location tracking

The authenticated main Dart isolate owns one Geolocator subscription for the
whole duty session. Order completion and widget/bloc disposal never stop it.
`LocationTracker()` is the shared instance; its dependency constructor supports
fake device sources, uploads, connectivity, clock, timers and release mode.

## Going online and offline

An online tap checks that GPS is enabled, requests foreground permission if
needed, then explains background access before requesting it:
“To get orders while your phone is locked, allow location all the time.”
Background refusal still allows duty and shows the amber warning.

The gate opens the precise subscription and waits at most 15 seconds. It uses
the first fix at ±50 m or better, or the most accurate usable fix (up to ±100 m)
at the deadline. GPS off, denied permission, or no usable fix keeps the rider
offline with the matching message and settings action. Profile coordinates,
delivery-zone centers and last-known cached positions are never fallbacks.

Only then is `status/update` sent with `active` and numeric latitude/longitude.
Success reuses that subscription and sends the first heartbeat immediately.
Failure cancels the prepared subscription. Going offline posts `inactive` first;
failure keeps tracking, success stops it. Logout/session expiry stops it too.

Cold starts restore saved online duty after the first frame only when logged in,
without permission prompts. The existing `LocationMonitor` sends immediately on
resume and checks permission again. Start/stop operations are serialized and
callbacks carry a session generation so old callbacks cannot revive tracking.

## Precision and cadence

All tuning constants live at the top of `lib/utils/location_tracker.dart`.

- Android: fused provider, high accuracy, 10 m filter, 10 s interval, ongoing
  “You're online” notification, “Sharing your location so you get nearby orders”,
  and wake lock. Geolocator supplies the foreground location service.
- iOS: best accuracy, 10 m filter, navigation activity, background updates and
  indicator enabled, automatic pauses disabled. The Podfile enables
  permission_handler's location support; location usage descriptions and
  background mode already exist in Info.plist.
- Drop non-finite/out-of-range coordinates, 0/0, negative/non-finite accuracy,
  and fixes older than 30 s when received. Position fields are non-nullable.
- Release builds drop mocked positions and show `mockLocation`; debug emulators
  can use them. Accuracy above 100 m is retained only as the last weak fix.
- Good means accuracy ≤50 m; usable means ≤100 m. Prefer the newest good fix in
  the send window, otherwise the newest usable fix. A good fix implying more
  than 40 m/s is held until the next fix confirms an area within 100 m.
- Send on activation, resume, restored GPS/permission, and movement ≥50 m from
  the last successful upload. Send at least every 60 s while duty stays active.
  A stationary rider still reports. When there has been no usable fix for 60 s,
  request one high-accuracy fix with a 10 s timeout. Never upload a weak fix.
- The tracker keeps one upload in flight and only the newest pending coordinate.
  Each request has a 15 s timeout that cancels the Dio request. Network failures
  and 5xx retry after 2, 4, 8, 16, 32, 60, 60… seconds. Success resets backoff.
  Reconnection retries immediately. Old pending fixes are refreshed instead of
  making stale GPS appear current; no offline backlog is uploaded.
- 401/Unauthenticated stops everything. ApiBaseHelper already owns session expiry
  and login navigation, so the tracker does not expire it a second time.
  422 drops that coordinate permanently; a new valid fix may upload. 403 also
  drops the coordinate and uses existing inactive-account/session handling.

## Home screen health

Only online duty shows the live “Location sent · 12s ago · ±18 m” status and
health banner. The tracker also exposes server `recorded_at` and the successful
send time. The health states are `ok`, `backgroundDenied`, `permissionDenied`,
`serviceOff`, `weakSignal`, `mockLocation` and `stale` (no success for two minutes).

GPS off and denied foreground permission have red banners and settings buttons.
Mock GPS has a red warning. Missing background permission has an amber
“Allow all the time” action. Weak GPS and stale uploads have amber guidance.
Turning GPS off while online leaves explicit duty active and shows one local
notification per outage: “GPS is off. You won't get orders until you turn it on.”
GPS recovery sends immediately.

Android MainActivity retains the main Flutter engine and reuses it on reopening
so swiping the task does not destroy the isolate that owns heartbeats. This is
not a guarantee against process death, force-stop, reboot, or OEM battery limits.
Validate on devices before relying on background delivery. Geolocator's cached
broadcast stream allows map listeners alongside the duty listener; map disposal
cancels its own subscription, never the tracker's. The maps' `location` dependency
and native order-alert mediaPlayback service are retained.

## Automated validation

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
```

Targeted suites: `test/location_tracker_test.dart`,
`test/deliveryboy_status_bloc_test.dart`, `test/rider_popup_cubit_test.dart`,
`test/rider_popup_repo_test.dart`, `test/rider_order_overlay_test.dart`.

## Manual device validation

Run on Android 12, 13, 14 and 15 plus a Xiaomi/Oppo/Vivo device. Use:

```bash
adb logcat | grep -E "LocationTracker|update-current-location"
adb shell dumpsys activity services com.nagpurmart.rider
adb shell dumpsys location
flutter run -d <device-id>
flutter run --release -d <device-id>
```

- GPS off → online blocked; Turn on location opens settings.
- Permission denied → online blocked; Open settings opens app settings.
- Weak GPS indoors → wait up to 15 s, then weak-signal error unless a usable fix arrives.
- Go online → ongoing notification and one immediate POST, then one about every 60 s while stationary.
- Walk ≥50 m → extra POST; check outdoor accuracy around 50 m or better.
- Background, lock screen and swipe from recents for 10 minutes each → POSTs every ≤60 s. Reopen after swiping: one engine/subscription, no duplicate posts.
- Airplane mode for three minutes → stale banner; reconnect → newest point, no burst.
- Switch GPS off online → red banner and one notification; back on → immediate POST.
- Revoke All the time → amber background banner after resume.
- Release build with fake GPS → mock banner and no mocked-coordinate POSTs.
- Go offline → inactive POST first, ongoing notification gone, no more heartbeats. Logout → tracking also stops.
- Pickup, return pickup and store-route maps still receive live positions online; closing maps leaves duty heartbeats running.
- Incoming order → Accept only, ringing unchanged.
- Push `order_alert_cancel` with each reason → ring stops, card disappears immediately and reason displays; repeat while app closed and reopen.
- Accept reassigned order → server's 409 message, card and ringing removed.
- Full flow: accept → wrong bag error → correct bag “Bag picked up” → collected → COD → delivered. Duty and heartbeats continue.
