# Rider order popup and location tracking — implementation report

Branch: `codex/rider-popup-location`. Changes are committed locally by section. **Nothing was pushed.** Both input documents were read fully before code changes and were left untouched, including their original untracked status.

## 1. Files changed, added and deleted

The small analyzer-only cleanup is isolated in commit `7c70b37`: it removes existing unused code/imports and excludes generated build output. It changes no active feature behavior. Map location subscriptions, native OrderAlertService, delivery, bag scan, COD and return flows were not rewritten.

- **Changed** `analysis_options.yaml` — Exclude generated build/dependency examples; keep all application lints enabled.
- **Changed** `android/app/src/main/AndroidManifest.xml` — Remove the obsolete flutter_background_service location service; retain permissions and order-alert service.
- **Changed** `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` — Regenerate registration after removing flutter_background_service.
- **Changed** `android/app/src/main/kotlin/com/nagpurmart/rider/MainActivity.kt` — Retain/reuse the main Flutter engine so activity removal does not destroy duty tracking.
- **Changed** `android/app/src/main/kotlin/com/nagpurmart/rider/orderalert/OrderAlertChannel.kt` — Forward cancellation events and expose persisted cancellation delivery to Dart.
- **Changed** `android/app/src/main/kotlin/com/nagpurmart/rider/orderalert/OrderAlertEvents.kt` — Notify listeners of cancellation order ID and reason on the main thread.
- **Changed** `android/app/src/main/kotlin/com/nagpurmart/rider/orderalert/OrderAlertStore.kt` — Persist cancellations while Dart is absent and clear them on logout.
- **Changed** `android/app/src/main/kotlin/com/nagpurmart/rider/orderalert/RiderMessagingService.kt` — Persist/forward reassigned and cancelled pushes after dismissing the ring.
- **Changed** `docs/incoming_order_alert.md` — Document one reserved offer, 409, immediate withdrawal, no Skip, and current dispatch rules.
- **Added** `docs/location_tracking.md` — Document duty gating, filtering, cadence, background lifecycle, retries, health and manual commands.
- **Added** `docs/rider_order_popup_implementation_report.md` — Record the requested section 9 report and device checklist.
- **Changed** `ios/Podfile` — Enable permission_handler location permission support for the background-access flow.
- **Changed** `ios/Runner/GeneratedPluginRegistrant.m` — Regenerate registration after removing flutter_background_service.
- **Changed** `lib/config/api_base_helper.dart` — Preserve HTTP error status metadata and support cancellable location request deadlines; retain existing session expiry.
- **Changed** `lib/l10n/app_ar.arb` — Add English location messages and typed status placeholders.
- **Changed** `lib/l10n/app_en.arb` — Add English location messages and typed status placeholders.
- **Changed** `lib/l10n/app_fr.arb` — Add English location messages and typed status placeholders.
- **Changed** `lib/l10n/app_gu.arb` — Add English location messages and typed status placeholders.
- **Changed** `lib/l10n/app_hi.arb` — Add English location messages and typed status placeholders.
- **Changed** `lib/l10n/app_localizations.dart` — Regenerate localized location accessors and messages.
- **Changed** `lib/l10n/app_localizations_ar.dart` — Regenerate localized location accessors and messages.
- **Changed** `lib/l10n/app_localizations_en.dart` — Regenerate localized location accessors and messages.
- **Changed** `lib/l10n/app_localizations_fr.dart` — Regenerate localized location accessors and messages.
- **Changed** `lib/l10n/app_localizations_gu.dart` — Regenerate localized location accessors and messages.
- **Changed** `lib/l10n/app_localizations_hi.dart` — Regenerate localized location accessors and messages.
- **Changed** `lib/l10n/app_localizations_te.dart` — Regenerate localized location accessors and messages.
- **Changed** `lib/l10n/app_te.arb` — Add English location messages and typed status placeholders.
- **Changed** `lib/main.dart` — Remove conflicting background-service setup and reset the shared tracker before startup.
- **Changed** `lib/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart` — Gate active duty on real GPS, reuse the prepared stream, post inactive before stopping, and retain tracking on bloc disposal.
- **Changed** `lib/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart` — Carry the background-permission explanation callback for explicit online taps.
- **Changed** `lib/screens/feed_page/bloc/deliveryboy_status_update_bloc/deliveryboy_status_state.dart` — Expose blocked-location reasons for the matching home settings action.
- **Changed** `lib/screens/feed_page/repo/update_current_location.dart` — Upload numeric coordinates with a 15-second cancellable deadline and preserve response/error metadata.
- **Changed** `lib/screens/feed_page/rider_popup/cubit/rider_popup_cubit.dart` — Remove local skipping; handle refusals/withdrawals and late responses; serialize accepted-order persistence.
- **Changed** `lib/screens/feed_page/rider_popup/cubit/rider_popup_state.dart` — Describe reserved offers that wait for acceptance or backend withdrawal.
- **Changed** `lib/screens/feed_page/rider_popup/repo/rider_popup_repo.dart` — Classify 409/404/422 as unavailable and 5xx/network as retry; filter documented eligible offers.
- **Changed** `lib/screens/feed_page/rider_popup/view/rider_order_overlay.dart` — Show one full-width Accept action and retain withdrawal/refusal messages after card removal.
- **Changed** `lib/screens/feed_page/rider_popup/view/rider_popup_controller.dart` — Subscribe to cancellations, drain persisted events and remove refused native-alert offers.
- **Changed** `lib/screens/feed_page/services/dialog_service.dart` — Remove already-unreferenced private earnings helpers; active dialogs remain unchanged.
- **Changed** `lib/screens/feed_page/view/home_page.dart` — Show online location health and offline gate errors with settings actions and background explanation.
- **Changed** `lib/screens/feed_page/view/map/store_pickup_route/map_delivery_page.dart` — Make an existing never-reassigned field final to clear its pre-existing lint; location flow unchanged.
- **Changed** `lib/screens/feed_page/view/order_detail/order_details_page.dart` — Remove pre-existing unused imports/field; active order actions unchanged.
- **Changed** `lib/screens/feed_page/widgets/available_orders/available_order_card.dart` — Remove a pre-existing unused import only.
- **Changed** `lib/screens/feed_page/widgets/my_orders/my_order_card.dart` — Remove pre-existing unused imports only.
- **Changed** `lib/screens/feed_page/widgets/orderdetails_widgets/statistics_row.dart` — Remove a pre-existing unused import only.
- **Changed** `lib/screens/inactive_delievryboy/view/statistics_page.dart` — Remove pre-existing unreachable private render helpers and their unused imports/state; active dashboard remains unchanged.
- **Changed** `lib/screens/pockets/view/pockets_page.dart` — Remove pre-existing unreachable private earnings/date helpers and their unused imports; active pockets UI unchanged.
- **Changed** `lib/screens/settings/view/my_orders.dart` — Remove a pre-existing unused import only.
- **Changed** `lib/utils/location_handler.dart` — Remove automatic startup permission prompts/duplicate monitoring while retaining explicit map/dialog entry points.
- **Changed** `lib/utils/location_monitor_widget.dart` — Restore logged-in online duty after the first frame and send/check access on resume.
- **Changed** `lib/utils/location_tracker.dart` — Replace isolates with one injectable Geolocator duty stream, filters, health, heartbeat, coalescing, bounded retry and lifecycle guards.
- **Changed** `lib/utils/notification_manager.dart` — Avoid generic foreground notifications for native order-alert message types.
- **Deleted** `lib/utils/periodic_location_service.dart` — Delete the unused duplicate location uploader after verifying no imports.
- **Changed** `lib/utils/services/json_parser.dart` — Add braces for a pre-existing lint without changing parsing behavior.
- **Changed** `lib/utils/services/order_alert_bridge.dart` — Expose cancellation events and drain native pending cancellations after subscription.
- **Changed** `lib/utils/services/session_service.dart` — Await full tracking shutdown before clearing the session.
- **Added** `lib/utils/widgets/location_status_banner.dart` — Add themed localized health/status banners, fix buttons and permission explanation.
- **Changed** `pubspec.yaml` — Remove flutter_background_service and add fake_async as a direct test dependency.
- **Added** `test/deliveryboy_status_bloc_test.dart` — Cover all section 6 duty cases plus background explanation/refusal and duplicate taps.
- **Added** `test/location_tracker_test.dart` — Cover all section 6 tracker cases plus stale health, recovery, delayed callbacks, platform settings and map-listener coexistence.
- **Added** `test/rider_order_overlay_test.dart` — Verify order/customer/bag details and Accept with no Skip.
- **Added** `test/rider_popup_cubit_test.dart` — Cover persistence across fetches, refusals, retry, cancellation, assignment revalidation and late-fetch races.
- **Added** `test/rider_popup_repo_test.dart` — Use a local HTTP server for 409/404/422, 500, missing success, scan errors and the documented available-order sample.
- **Added** `test/support/fake_location.dart` — Provide fake GPS, service/permission state, uploads and duty API for deterministic fake-time tests.
- **Added** `test/support/fake_rider_popup_repo.dart` — Provide controlled offers, accept outcomes and detail assignment changes.
- **Added** `test/support/rider_popup_sample.dart` — Keep the API document’s available-order sample as a shared test fixture.
- **Changed** `test/widget_test.dart` — Replace the obsolete counter-template test with six real location-banner widget checks.

## 2. Dependencies

- Added `fake_async: ^1.3.3` to dev_dependencies (resolved 1.3.3; previously transitive).
- Removed `flutter_background_service`; pub also removed its Android, iOS and platform-interface transitive packages.
- Kept `location` for existing maps, plus existing Geolocator, connectivity_plus and permission_handler dependencies.
- `pubspec.lock` remains governed by the repository’s existing `*.lock` ignore rule; it was updated locally by pub get and was not force-added.

## 3. Section 7 command results

Every required command completed successfully on the final implementation:

| Command | Result / output summary |
|---|---|
| `flutter pub get` | Exit 0 — `Got dependencies!` |
| `flutter gen-l10n` | Exit 0 — generated using existing `l10n.yaml` |
| `flutter analyze` | Exit 0 — `No issues found!` |
| `flutter test` | Exit 0 — `+112: All tests passed!` |
| `flutter build apk --debug` | Exit 0 — `Built build/app/outputs/flutter-apk/app-debug.apk` |

APK: `build/app/outputs/flutter-apk/app-debug.apk`.
Build warnings about future Flutter support for the existing Gradle/AGP versions remain warnings; no build configuration upgrade was mixed into this task.

## 4. Anything not done or done differently

- The Android 12/13/14/15 and Xiaomi/Oppo/Vivo physical-device matrix, authenticated full delivery/COD flow, real push delivery, and iOS runtime behavior were not run. They require the manual checklist below. Only an Android 17 emulator was available; the debug build succeeded.
- Map stream coexistence was checked in the installed Geolocator broadcast-stream implementation and with a live fake-stream listener test. Actual map screens still need the device checks below. The only map-page source change is a pre-existing final-field lint fix.
- MainActivity retains/reuses the main Flutter engine. This addition is necessary because a foreground notification alone does not keep a Dart isolate alive when its owning activity destroys the engine. No replacement background isolate/service package was introduced.
- The existing counter-template widget test expected a nonexistent counter and failed while trying to load uninitialized Hive. It was replaced with real banner tests; other existing tests were kept and passed.
- No unused Skip localization keys existed, so none needed deletion. All six ARB files received English fallbacks for the new messages and localization code was regenerated.
- The first full analysis found generated iOS dependency-example errors and existing source lints. Build output is now excluded explicitly; unreachable private helpers/unused imports and trivial lints were removed without weakening application lint rules.

## 5. Spec ambiguities and decisions

- The API document prefers balanced-power location; the task gives explicit Android high-accuracy/iOS best settings and strict precision thresholds. Used those explicit settings: the API’s balanced preference is advisory, and no weak fixes are uploaded. Battery impact needs device validation.
- The order-detail example omits `delivery_boy_id`, although the acceptance contract documents it. On withdrawal, the cubit re-reads detail and compares assignment when present; an authoritative withdrawal removes the stale popup when assignment cannot be confirmed. No undocumented response field was introduced.
- The task asks for null-coordinate rejection, but Geolocator `Position.latitude`/`longitude` are non-nullable doubles. The filter rejects non-finite values, invalid ranges, 0/0 and old timestamps instead.
- Stationary reports require a fresh device fix at the 60-second tick when no usable fix arrived in that window. Cached/rejected or weak coordinates are never used to manufacture a fresh report.

## 6. Known risks

- High accuracy and the wake lock use battery; measure a full shift on target hardware.
- The retained engine/foreground location service supports task swiping while the process survives. Android force-stop, process death, reboot and OEM battery/autostart restrictions still require explicit validation; no implementation can promise uninterrupted execution under those conditions.
- Background/Always permission and iOS scheduling remain OS-controlled. Permission refusal is visible, and explicit duty remains active during GPS/network outages as the API requires.
- The native order-alert and location foreground notifications may both appear, intentionally.

## 8. Manual device checklist

Run on **Android 12, 13, 14 and 15**, and **one Xiaomi/Oppo/Vivo phone**. Use:

```bash
adb logcat | grep -E "LocationTracker|update-current-location"
adb shell dumpsys activity services com.nagpurmart.rider
adb shell dumpsys location
```

- [ ] GPS off → tap online → blocked with “Turn on location”; button opens location settings.
- [ ] Permission denied → blocked with access message; button opens app settings.
- [ ] Weak GPS indoors → online waits up to 15 s, then weak-signal error, or succeeds with a fix ≤100 m.
- [ ] Go online → “You’re online” foreground notification; one immediate POST, then about one every 60 s while stationary.
- [ ] Walk ≥50 m → extra POST; outdoor accuracy around 50 m or better.
- [ ] Background the app for 10 minutes → POSTs continue every ≤60 s.
- [ ] Lock the screen for 10 minutes → POSTs continue every ≤60 s.
- [ ] Swipe from recents for 10 minutes → POSTs continue; reopen without duplicate engines/subscriptions/POSTs.
- [ ] Airplane mode for three minutes → stale banner; reconnect → newest point, no upload burst.
- [ ] Turn GPS off online → red banner and one notification; back on → immediate POST.
- [ ] Revoke All the time → amber background warning on resume.
- [ ] Fake GPS in a release build → mock warning and no mocked-coordinate uploads.
- [ ] Go offline → inactive POST first, foreground notification disappears, no more location POSTs; failed inactive request keeps tracking.
- [ ] Logout/session expiry → tracking and notifications stop, expired session opens login.
- [ ] Pickup route, return pickup and store-route map pages still show live positions while online; closing them leaves duty POSTs running.
- [ ] Incoming order → Accept only, no Skip; ringtone/native lock-screen behavior unchanged.
- [ ] `order_alert_cancel` with `reassigned` → ring stops, card disappears immediately, “Order reassigned”. Repeat with `cancelled`.
- [ ] Cancel/reassign while Flutter is absent → reopen → persisted cancellation removes the card.
- [ ] Accept an already reassigned order → exact 409 server message; card removed, ringing stops.
- [ ] Full flow: accept → wrong bag error → correct bag “Bag picked up” → collected → COD → delivered. Rider remains online and location POSTs continue.
