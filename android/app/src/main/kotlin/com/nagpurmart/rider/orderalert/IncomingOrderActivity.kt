package com.nagpurmart.rider.orderalert

import android.app.Activity
import android.app.KeyguardManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.format.DateUtils
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import com.nagpurmart.rider.R

/**
 * The incoming-order screen, shown over the lock screen by the alert
 * notification's full-screen intent (or when the notification is tapped).
 *
 * Native, so it appears at once without waiting for Flutter to start. The
 * only action is Accept, which unlocks the phone and opens the app to
 * accept the order with the backend. Ringing goes on until then.
 */
class IncomingOrderActivity : Activity(), OrderAlertEvents.Listener {

    private lateinit var orderTitle: TextView
    private lateinit var waiting: TextView
    private lateinit var pickup: TextView
    private lateinit var drop: TextView
    private lateinit var distance: TextView
    private lateinit var payment: TextView
    private lateinit var more: TextView
    private lateinit var accept: Button

    private var current: OrderAlert? = null
    private val ticker = Handler(Looper.getMainLooper())
    private val tick = object : Runnable {
        override fun run() {
            renderWaiting()
            ticker.postDelayed(this, 1000)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showOverLockScreen()
        setContentView(R.layout.activity_incoming_order)
        orderTitle = findViewById(R.id.order_title)
        waiting = findViewById(R.id.order_waiting)
        pickup = findViewById(R.id.order_pickup)
        drop = findViewById(R.id.order_drop)
        distance = findViewById(R.id.order_distance)
        payment = findViewById(R.id.order_payment)
        more = findViewById(R.id.order_more)
        accept = findViewById(R.id.order_accept)
        accept.setOnClickListener { onAccept() }
    }

    override fun onStart() {
        super.onStart()
        OrderAlertEvents.add(this)
        onAlertsChanged(OrderAlertStore.pending(this))
        ticker.post(tick)
    }

    override fun onStop() {
        OrderAlertEvents.remove(this)
        ticker.removeCallbacks(tick)
        super.onStop()
    }

    override fun onAlertsChanged(pending: List<OrderAlert>) {
        val next = pending.firstOrNull()
        if (next == null) {
            finish()
            return
        }
        if (next.orderId != current?.orderId) accept.isEnabled = true
        current = next
        orderTitle.text = getString(R.string.order_alert_title, next.orderId)
        setRow(pickup, next.pickup)
        setRow(drop, next.drop)
        setRow(distance, if (next.distanceKm.isNotEmpty()) "${next.distanceKm} km" else "")
        setRow(
            payment,
            listOf(next.paymentMethod.uppercase(), if (next.amount.isNotEmpty()) "₹${next.amount}" else "")
                .filter { it.isNotEmpty() }
                .joinToString(" "),
        )
        val others = pending.size - 1
        more.visibility = if (others > 0) View.VISIBLE else View.GONE
        if (others > 0) more.text = resources.getQuantityString(R.plurals.order_alert_more, others, others)
        renderWaiting()
    }

    private fun setRow(value: TextView, text: String) {
        (value.parent as View).visibility = if (text.isEmpty()) View.GONE else View.VISIBLE
        value.text = text
    }

    private fun renderWaiting() {
        val receivedAt = current?.receivedAt ?: return
        val seconds = ((System.currentTimeMillis() - receivedAt) / 1000).coerceAtLeast(0)
        waiting.text = getString(R.string.order_alert_waiting, DateUtils.formatElapsedTime(seconds))
    }

    private fun onAccept() {
        val orderId = current?.orderId ?: return
        // One tap only, even if the rider taps again while the phone unlocks.
        accept.isEnabled = false
        val keyguard = getSystemService(KeyguardManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && keyguard?.isKeyguardLocked == true) {
            keyguard.requestDismissKeyguard(this, object : KeyguardManager.KeyguardDismissCallback() {
                override fun onDismissSucceeded() = openApp(orderId)
                override fun onDismissCancelled() {
                    accept.isEnabled = true
                }
                override fun onDismissError() {
                    accept.isEnabled = true
                }
            })
        } else {
            openApp(orderId)
        }
    }

    private fun openApp(orderId: String) {
        startActivity(OrderAlertIntents.accept(this, orderId))
        finish()
    }

    @Suppress("DEPRECATION")
    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
