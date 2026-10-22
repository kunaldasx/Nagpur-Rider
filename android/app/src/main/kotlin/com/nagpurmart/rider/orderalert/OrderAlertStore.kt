package com.nagpurmart.rider.orderalert

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject

/** An order assigned to this rider that is waiting to be accepted. */
data class OrderAlert(
    val orderId: String,
    val pickup: String,
    val drop: String,
    val distanceKm: String,
    val amount: String,
    val paymentMethod: String,
    val receivedAt: Long,
) {
    /** One line for the notification: "Pickup → Drop · 3.2 km · COD ₹420". */
    val summary: String
        get() {
            val route = listOf(pickup, drop).filter { it.isNotEmpty() }.joinToString(" → ")
            val distance = if (distanceKm.isNotEmpty()) "$distanceKm km" else ""
            val payment = listOf(paymentMethod.uppercase(), if (amount.isNotEmpty()) "₹$amount" else "")
                .filter { it.isNotEmpty() }
                .joinToString(" ")
            return listOf(route, distance, payment).filter { it.isNotEmpty() }.joinToString(" · ")
        }

    fun toJson(): JSONObject = JSONObject()
        .put(KEY_ORDER_ID, orderId)
        .put(KEY_PICKUP, pickup)
        .put(KEY_DROP, drop)
        .put(KEY_DISTANCE, distanceKm)
        .put(KEY_AMOUNT, amount)
        .put(KEY_PAYMENT, paymentMethod)
        .put(KEY_RECEIVED_AT, receivedAt)

    companion object {
        private const val KEY_ORDER_ID = "order_id"
        private const val KEY_PICKUP = "pickup"
        private const val KEY_DROP = "drop"
        private const val KEY_DISTANCE = "distance_km"
        private const val KEY_AMOUNT = "amount"
        private const val KEY_PAYMENT = "payment_method"
        private const val KEY_RECEIVED_AT = "received_at"

        /** Reads the FCM data payload. Null when it carries no order id. */
        fun fromMessage(data: Map<String, String>, now: Long): OrderAlert? {
            val orderId = data[KEY_ORDER_ID]?.trim().orEmpty()
            if (orderId.isEmpty()) return null
            return OrderAlert(
                orderId = orderId,
                pickup = data[KEY_PICKUP]?.trim().orEmpty(),
                drop = data[KEY_DROP]?.trim().orEmpty(),
                distanceKm = data[KEY_DISTANCE]?.trim().orEmpty(),
                amount = data[KEY_AMOUNT]?.trim().orEmpty(),
                paymentMethod = data[KEY_PAYMENT]?.trim().orEmpty(),
                receivedAt = now,
            )
        }

        fun fromJson(json: JSONObject): OrderAlert? {
            val orderId = json.optString(KEY_ORDER_ID).trim()
            if (orderId.isEmpty()) return null
            return OrderAlert(
                orderId = orderId,
                pickup = json.optString(KEY_PICKUP),
                drop = json.optString(KEY_DROP),
                distanceKm = json.optString(KEY_DISTANCE),
                amount = json.optString(KEY_AMOUNT),
                paymentMethod = json.optString(KEY_PAYMENT),
                receivedAt = json.optLong(KEY_RECEIVED_AT),
            )
        }
    }
}

/**
 * The alerts waiting for the rider, kept on disk so they survive the process
 * being killed and the alert service being restarted by Android.
 *
 * Also remembers orders that were recently accepted or cancelled, so a
 * duplicate or late FCM message for them doesn't ring again.
 */
object OrderAlertStore {
    private const val PREFS = "order_alert"
    private const val KEY_LOGGED_IN = "logged_in"
    private const val KEY_PENDING = "pending"
    private const val KEY_HANDLED = "handled"

    /** How long a handled order is ignored when FCM sends it again. */
    private const val HANDLED_TTL_MS = 6 * 60 * 60 * 1000L

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Set by Flutter on login and logout. Alerts only ring while logged in. */
    fun isLoggedIn(context: Context): Boolean = prefs(context).getBoolean(KEY_LOGGED_IN, false)

    fun setLoggedIn(context: Context, loggedIn: Boolean) {
        prefs(context).edit().putBoolean(KEY_LOGGED_IN, loggedIn).commit()
    }

    /** Oldest first. */
    @Synchronized
    fun pending(context: Context): List<OrderAlert> {
        val json = readObject(prefs(context), KEY_PENDING)
        return json.keys().asSequence()
            .mapNotNull { key -> json.optJSONObject(key)?.let(OrderAlert::fromJson) }
            .sortedBy { it.receivedAt }
            .toList()
    }

    /**
     * Adds [alert]. Returns false when it's a duplicate: the order is already
     * ringing, or was accepted or cancelled within [HANDLED_TTL_MS].
     */
    @Synchronized
    fun add(context: Context, alert: OrderAlert): Boolean {
        val prefs = prefs(context)
        val pending = readObject(prefs, KEY_PENDING)
        val handled = pruned(readObject(prefs, KEY_HANDLED), alert.receivedAt)
        if (pending.has(alert.orderId) || handled.has(alert.orderId)) return false
        pending.put(alert.orderId, alert.toJson())
        prefs.edit()
            .putString(KEY_PENDING, pending.toString())
            .putString(KEY_HANDLED, handled.toString())
            .commit()
        return true
    }

    /** Stops ringing for [orderId] and ignores later messages for it. */
    @Synchronized
    fun markHandled(context: Context, orderId: String) {
        val prefs = prefs(context)
        val now = System.currentTimeMillis()
        val pending = readObject(prefs, KEY_PENDING).apply { remove(orderId) }
        val handled = pruned(readObject(prefs, KEY_HANDLED), now).put(orderId, now)
        prefs.edit()
            .putString(KEY_PENDING, pending.toString())
            .putString(KEY_HANDLED, handled.toString())
            .commit()
    }

    /** On logout: nothing rings for the next rider who logs in here. */
    @Synchronized
    fun clearPending(context: Context) {
        prefs(context).edit().remove(KEY_PENDING).commit()
    }

    private fun readObject(prefs: SharedPreferences, key: String): JSONObject =
        try {
            JSONObject(prefs.getString(key, null) ?: "{}")
        } catch (e: Exception) {
            JSONObject()
        }

    private fun pruned(handled: JSONObject, now: Long): JSONObject {
        val expired = handled.keys().asSequence()
            .filter { now - handled.optLong(it) > HANDLED_TTL_MS }
            .toList()
        expired.forEach(handled::remove)
        return handled
    }
}
