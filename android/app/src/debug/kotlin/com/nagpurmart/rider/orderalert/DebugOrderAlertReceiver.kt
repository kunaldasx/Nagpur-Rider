package com.nagpurmart.rider.orderalert

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Debug builds only: fakes the FCM messages from adb, to test the alert
 * without the backend.
 *
 *   adb shell am broadcast -n com.nagpurmart.rider/.orderalert.DebugOrderAlertReceiver \
 *     -a new_order --es order_id 48213 --es pickup "Sharma Kirana" --es drop Dharampeth
 *   adb shell am broadcast -n com.nagpurmart.rider/.orderalert.DebugOrderAlertReceiver \
 *     -a order_alert_cancel --es order_id 48213
 *
 * Add `--ez logged_in true` to ring without logging in first.
 */
class DebugOrderAlertReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.getBooleanExtra("logged_in", false)) OrderAlertStore.setLoggedIn(context, true)
        val data = intent.extras?.keySet().orEmpty()
            .mapNotNull { key -> intent.getStringExtra(key)?.let { key to it } }
            .toMap()
        when (intent.action) {
            RiderMessagingService.TYPE_NEW_ORDER -> OrderAlertService.alert(context, data)
            RiderMessagingService.TYPE_ORDER_ALERT_CANCEL ->
                data["order_id"]?.let { OrderAlertService.dismiss(context, it) }
        }
    }
}
