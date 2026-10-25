package com.nagpurmart.rider.orderalert

import android.app.Activity
import android.app.NotificationManager
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `com.nagpurmart.rider/order_alert`, between MainActivity and
 * `OrderAlertBridge` in Dart.
 *
 * Dart → native: setLoggedIn, stopAlert, pendingAlerts, takePendingAccept,
 * canUseFullScreenIntent, openFullScreenIntentSettings, isAlarmMuted.
 * Native → Dart: acceptRequested, alertsChanged.
 */
class OrderAlertChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, OrderAlertEvents.Listener {

    companion object {
        private const val TAG = "OrderAlertChannel"
        const val NAME = "com.nagpurmart.rider/order_alert"
    }

    private val channel = MethodChannel(messenger, NAME)

    /** The order the rider tapped Accept on, until Dart takes it. */
    private var pendingAcceptId: String? = null

    init {
        channel.setMethodCallHandler(this)
        OrderAlertEvents.add(this)
    }

    fun dispose() {
        OrderAlertEvents.remove(this)
        channel.setMethodCallHandler(null)
    }

    /** Called with the launch intent and every new intent of MainActivity. */
    fun handleIntent(intent: Intent?) {
        if (intent?.action != OrderAlertIntents.ACTION_ACCEPT_ORDER) return
        val orderId = intent.getStringExtra(OrderAlertIntents.EXTRA_ORDER_ID)?.trim()
        // Handled once, even if the activity is later recreated with this intent.
        intent.action = null
        if (orderId.isNullOrEmpty()) return
        Log.i(TAG, "Rider tapped accept for order $orderId")
        pendingAcceptId = orderId
        // Dart may not be listening yet on a cold start; it then asks with
        // takePendingAccept once the app is up.
        channel.invokeMethod("acceptRequested", null)
    }

    override fun onAlertsChanged(pending: List<OrderAlert>) {
        channel.invokeMethod("alertsChanged", pending.map { it.orderId })
    }

    override fun onAlertCancelled(orderId: String, reason: String) {
        channel.invokeMethod("alertCancelled", mapOf("orderId" to orderId, "reason" to reason))
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = activity.applicationContext
        when (call.method) {
            "setLoggedIn" -> {
                val loggedIn = call.argument<Boolean>("loggedIn") == true
                OrderAlertStore.setLoggedIn(context, loggedIn)
                if (!loggedIn) OrderAlertService.dismissAll(context)
                result.success(null)
            }
            "stopAlert" -> {
                val orderId = call.argument<Any>("orderId")?.toString()?.trim()
                if (orderId.isNullOrEmpty()) {
                    result.error("bad_args", "orderId is required", null)
                    return
                }
                OrderAlertService.dismiss(context, orderId)
                result.success(null)
            }
            "pendingAlerts" -> result.success(OrderAlertStore.pending(context).map { it.orderId })
            "takePendingCancellations" -> result.success(OrderAlertStore.takeCancellations(context))
            "takePendingAccept" -> {
                result.success(pendingAcceptId)
                pendingAcceptId = null
            }
            "canUseFullScreenIntent" -> result.success(
                Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE ||
                    context.getSystemService(NotificationManager::class.java).canUseFullScreenIntent(),
            )
            "openFullScreenIntentSettings" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    try {
                        activity.startActivity(
                            Intent(
                                Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                                Uri.parse("package:${context.packageName}"),
                            ),
                        )
                    } catch (e: Exception) {
                        Log.w(TAG, "Full-screen intent settings unavailable", e)
                    }
                }
                result.success(null)
            }
            "isAlarmMuted" -> {
                val audio = context.getSystemService(AudioManager::class.java)
                result.success(audio.getStreamVolume(AudioManager.STREAM_ALARM) == 0)
            }
            else -> result.notImplemented()
        }
    }
}
