package com.nagpurmart.rider.orderalert

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import com.nagpurmart.rider.MainActivity
import java.util.concurrent.CopyOnWriteArraySet

/** Tells the incoming-order screen and Flutter when the ringing orders change. */
object OrderAlertEvents {
    fun interface Listener {
        fun onAlertsChanged(pending: List<OrderAlert>)
        fun onAlertCancelled(orderId: String, reason: String) {}
    }

    private val listeners = CopyOnWriteArraySet<Listener>()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun notifyCancelled(orderId: String, reason: String) {
        mainHandler.post { listeners.forEach { it.onAlertCancelled(orderId, reason) } }
    }

    fun add(listener: Listener) {
        listeners.add(listener)
    }

    fun remove(listener: Listener) {
        listeners.remove(listener)
    }

    /** Listeners are always called on the main thread. */
    fun notifyChanged(pending: List<OrderAlert>) {
        mainHandler.post { listeners.forEach { it.onAlertsChanged(pending) } }
    }
}

object OrderAlertIntents {
    const val ACTION_ACCEPT_ORDER = "com.nagpurmart.rider.ACCEPT_ORDER"
    const val EXTRA_ORDER_ID = "order_id"

    /**
     * Opens the Flutter app, which then accepts [orderId] with the backend.
     * Ringing goes on until the backend confirms.
     */
    fun accept(context: Context, orderId: String): Intent =
        Intent(context, MainActivity::class.java)
            .setAction(ACTION_ACCEPT_ORDER)
            .putExtra(EXTRA_ORDER_ID, orderId)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
}
