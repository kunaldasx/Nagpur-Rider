package com.nagpurmart.rider.orderalert

import android.util.Log
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService

/**
 * Takes the place of the FlutterFire service (see AndroidManifest.xml) so
 * order alerts are handled natively, without starting Flutter.
 *
 * FlutterFire delivers messages to Dart from its own broadcast receiver, so
 * `onMessage` / `onBackgroundMessage` keep working; this subclass keeps its
 * token refresh too.
 *
 * Only data-only messages reach [onMessageReceived] while the app is in the
 * background: with a `notification` block Android shows it itself and no
 * code runs. The backend must send order alerts as data-only, high priority.
 */
class RiderMessagingService : FlutterFirebaseMessagingService() {

    companion object {
        private const val TAG = "RiderMessagingService"
        const val TYPE_NEW_ORDER = "new_order"
        const val TYPE_ORDER_ALERT_CANCEL = "order_alert_cancel"
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        val data = remoteMessage.data
        when (data["type"]) {
            TYPE_NEW_ORDER -> {
                if (remoteMessage.priority != RemoteMessage.PRIORITY_HIGH) {
                    // Android may then refuse to start the alert service.
                    Log.w(TAG, "new_order ${data["order_id"]} arrived as normal priority")
                }
                OrderAlertService.alert(this, data)
            }
            TYPE_ORDER_ALERT_CANCEL -> {
                val orderId = data["order_id"]?.trim().orEmpty()
                if (orderId.isNotEmpty()) {
                    Log.i(TAG, "Alert for order $orderId cancelled: ${data["reason"]}")
                    val reason = data["reason"]?.takeIf { it == "reassigned" } ?: "cancelled"
                    OrderAlertStore.saveCancellation(this, orderId, reason)
                    OrderAlertService.dismiss(this, orderId)
                    OrderAlertEvents.notifyCancelled(orderId, reason)
                }
            }
        }
    }
}
