package com.nagpurmart.rider.orderalert

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.nagpurmart.rider.R

/**
 * Rings like an incoming call while assigned orders wait to be accepted.
 *
 * A `mediaPlayback` foreground service: it plays the phone's ringtone on the
 * alarm stream (so it is heard on silent and vibrate) and keeps the process
 * alive after the app is swiped away. It runs only while an alert is
 * pending and stops itself when the last one is accepted or cancelled.
 *
 * Started from a high-priority FCM message, which is what allows a
 * foreground service to start from the background on Android 12+. If
 * Android refuses anyway, [postFallback] shows an insistent notification.
 */
class OrderAlertService : Service() {

    companion object {
        private const val TAG = "OrderAlertService"

        private const val ACTION_REFRESH = "com.nagpurmart.rider.orderalert.REFRESH"

        private const val NOTIFICATION_ID = 4201
        private const val FALLBACK_NOTIFICATION_ID = 4202

        private const val CHANNEL_ID = "incoming_order_alert_v1"
        private const val FALLBACK_CHANNEL_ID = "incoming_order_alert_fallback_v1"

        private val VIBRATION_PATTERN = longArrayOf(0, 800, 700)

        @Volatile
        private var instance: OrderAlertService? = null

        /** Rings for the order in an FCM `new_order` message. */
        fun alert(context: Context, data: Map<String, String>) {
            if (!OrderAlertStore.isLoggedIn(context)) {
                Log.w(TAG, "New order ${data["order_id"]} ignored: no rider logged in")
                return
            }
            val alert = OrderAlert.fromMessage(data, System.currentTimeMillis())
            if (alert == null) {
                Log.w(TAG, "New order message without order_id: $data")
                return
            }
            if (!OrderAlertStore.add(context, alert)) {
                Log.i(TAG, "Order ${alert.orderId} already ringing or handled, ignoring duplicate")
                return
            }
            Log.i(TAG, "Ringing for order ${alert.orderId}")
            start(context)
            openIncomingScreen(context)
        }

        /**
         * Opens the order screen over whatever the rider is doing. Android 10+
         * blocks this from the background unless the rider granted "Display
         * over other apps"; without it the locked-screen full-screen intent
         * and the heads-up notification still show the order.
         */
        private fun openIncomingScreen(context: Context) {
            if (!Settings.canDrawOverlays(context)) {
                Log.i(TAG, "No \"Display over other apps\" permission, notification only")
                return
            }
            try {
                context.startActivity(
                    Intent(context, IncomingOrderActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                )
            } catch (e: Exception) {
                Log.w(TAG, "Couldn't open the order screen", e)
            }
        }

        /**
         * Stops ringing for [orderId]: accepted (confirmed by the backend),
         * cancelled, or no longer this rider's.
         */
        fun dismiss(context: Context, orderId: String) {
            OrderAlertStore.markHandled(context, orderId)
            refreshOrCleanUp(context)
        }

        /** On logout. */
        fun dismissAll(context: Context) {
            OrderAlertStore.clearPending(context)
            refreshOrCleanUp(context)
        }

        private fun start(context: Context) {
            val intent = Intent(context, OrderAlertService::class.java).setAction(ACTION_REFRESH)
            try {
                ContextCompat.startForegroundService(context, intent)
            } catch (e: Exception) {
                // ForegroundServiceStartNotAllowedException (Android 12+) when the
                // message wasn't delivered as high priority, or the app is restricted.
                Log.e(TAG, "Couldn't start alert service, showing fallback notification", e)
                postFallback(context)
            }
        }

        private fun refreshOrCleanUp(context: Context) {
            val running = instance
            if (running != null) {
                Handler(Looper.getMainLooper()).post { running.refresh() }
            } else {
                NotificationManagerCompat.from(context).cancel(FALLBACK_NOTIFICATION_ID)
                OrderAlertEvents.notifyChanged(OrderAlertStore.pending(context))
            }
        }

        fun createChannels(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(NotificationManager::class.java)
            // The service plays the sound and vibration itself, so the channel is silent.
            val main = NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.order_alert_channel_name),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = context.getString(R.string.order_alert_channel_description)
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            // Used only when the service can't start: Android plays this sound,
            // repeated by FLAG_INSISTENT until the rider opens the shade.
            val fallback = NotificationChannel(
                FALLBACK_CHANNEL_ID,
                context.getString(R.string.order_alert_fallback_channel_name),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = context.getString(R.string.order_alert_channel_description)
                setSound(defaultRingtone(context), alarmAudioAttributes())
                enableVibration(true)
                vibrationPattern = VIBRATION_PATTERN
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannels(listOf(main, fallback))
        }

        private fun postFallback(context: Context) {
            val pending = OrderAlertStore.pending(context)
            val next = pending.firstOrNull() ?: return
            createChannels(context)
            @Suppress("DEPRECATION")
            val notification = baseNotification(context, FALLBACK_CHANNEL_ID, next, pending.size)
                // Below Android 8 there are no channels: set on the notification.
                .setSound(defaultRingtone(context), AudioManager.STREAM_ALARM)
                .setVibrate(VIBRATION_PATTERN)
                .build()
                .apply { flags = flags or Notification.FLAG_INSISTENT }
            try {
                NotificationManagerCompat.from(context).notify(FALLBACK_NOTIFICATION_ID, notification)
            } catch (e: SecurityException) {
                Log.e(TAG, "Notification permission missing, the rider won't see order ${next.orderId}", e)
            }
        }

        private fun baseNotification(
            context: Context,
            channelId: String,
            order: OrderAlert,
            pendingCount: Int,
        ): NotificationCompat.Builder {
            val requestCode = order.orderId.hashCode()
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val accept = PendingIntent.getActivity(
                context, requestCode, OrderAlertIntents.accept(context, order.orderId), flags,
            )
            val screen = PendingIntent.getActivity(
                context,
                requestCode + 1,
                Intent(context, IncomingOrderActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                flags,
            )
            val more = pendingCount - 1
            return NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.drawable.ic_order_alert)
                .setColor(ContextCompat.getColor(context, R.color.order_alert_accent))
                .setContentTitle(context.getString(R.string.order_alert_title, order.orderId))
                .setContentText(order.summary)
                .setStyle(NotificationCompat.BigTextStyle().bigText(order.summary))
                .setSubText(
                    if (more > 0) context.resources.getQuantityString(R.plurals.order_alert_more, more, more)
                    else null,
                )
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setAutoCancel(false)
                .setContentIntent(screen)
                // Shows IncomingOrderActivity when the phone is locked or the screen
                // is off; otherwise Android shows a heads-up notification instead.
                .setFullScreenIntent(screen, true)
                .addAction(0, context.getString(R.string.order_alert_accept), accept)
        }

        private fun alarmAudioAttributes(): AudioAttributes =
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

        private fun defaultRingtone(context: Context): Uri =
            RingtoneManager.getActualDefaultRingtoneUri(context, RingtoneManager.TYPE_RINGTONE)
                ?: Settings.System.DEFAULT_RINGTONE_URI
    }

    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var focusRequest: AudioFocusRequest? = null
    private var pausedForFocusLoss = false
    private var alertedOrderId: String? = null

    private val audioManager by lazy { getSystemService(AudioManager::class.java) }

    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        when (change) {
            // A phone call or similar: pause, and pick up again afterwards.
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                player?.takeIf { it.isPlaying }?.let {
                    it.pause()
                    pausedForFocusLoss = true
                }
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                if (pausedForFocusLoss) player?.start()
                pausedForFocusLoss = false
            }
            // Ducking and a permanent loss (another app starting music) don't stop
            // the alert: the order still has to be accepted.
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        createChannels(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // startForegroundService() requires startForeground() within a few
        // seconds even when there turns out to be nothing left to ring for.
        if (!goForeground(OrderAlertStore.pending(this))) {
            stopSelf()
            return START_NOT_STICKY
        }
        refresh()
        // Android restarts the service if it kills it; the alerts are on disk.
        return START_STICKY
    }

    override fun onDestroy() {
        stopRinging()
        instance = null
        OrderAlertEvents.notifyChanged(OrderAlertStore.pending(this))
        super.onDestroy()
    }

    /** Re-reads the pending alerts: updates the notification, or stops. */
    fun refresh() {
        val pending = OrderAlertStore.pending(this)
        OrderAlertEvents.notifyChanged(pending)
        NotificationManagerCompat.from(this).cancel(FALLBACK_NOTIFICATION_ID)
        if (pending.isEmpty()) {
            Log.i(TAG, "No orders waiting, stopping alert")
            stopRinging()
            ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
            stopSelf()
            return
        }
        if (!goForeground(pending)) {
            stopSelf()
            return
        }
        startRinging()
    }

    private fun goForeground(pending: List<OrderAlert>): Boolean {
        val notification = buildNotification(pending)
        return try {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                } else {
                    0
                },
            )
            true
        } catch (e: Exception) {
            Log.e(TAG, "startForeground refused, showing fallback notification", e)
            postFallback(this)
            false
        }
    }

    private fun buildNotification(pending: List<OrderAlert>): Notification {
        // The order that has waited longest is offered first.
        val next = pending.firstOrNull()
            ?: return NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_order_alert)
                .setContentTitle(getString(R.string.order_alert_checking))
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
        // Android 14+ lets the rider swipe even this away: show it again.
        val reshow = PendingIntent.getService(
            this,
            0,
            Intent(this, OrderAlertService::class.java).setAction(ACTION_REFRESH),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = baseNotification(this, CHANNEL_ID, next, pending.size)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setDeleteIntent(reshow)
            // Pop up again only for a new order, not on every refresh.
            .setOnlyAlertOnce(alertedOrderId == next.orderId)
        alertedOrderId = next.orderId
        return builder.build().apply {
            // Swiping the notification away must not hide a pending order.
            flags = flags or Notification.FLAG_NO_CLEAR or Notification.FLAG_ONGOING_EVENT
        }
    }

    private fun startRinging() {
        if (player == null) {
            requestAudioFocus()
            player = createPlayer()
            if (player == null) Log.e(TAG, "No ringtone could be played, vibrating only")
        }
        if (vibrator == null) startVibration()
    }

    private fun stopRinging() {
        player?.let {
            try {
                it.stop()
            } catch (_: IllegalStateException) {
            }
            it.release()
        }
        player = null
        pausedForFocusLoss = false
        vibrator?.cancel()
        vibrator = null
        abandonAudioFocus()
    }

    /** The phone's ringtone, falling back to the alarm sound, then the app's own sound. */
    private fun createPlayer(): MediaPlayer? {
        val candidates = listOfNotNull(
            RingtoneManager.getActualDefaultRingtoneUri(this, RingtoneManager.TYPE_RINGTONE),
            Settings.System.DEFAULT_RINGTONE_URI,
            Settings.System.DEFAULT_ALARM_ALERT_URI,
            Uri.parse("android.resource://$packageName/${R.raw.notification}"),
        )
        for (uri in candidates) {
            val mediaPlayer = MediaPlayer()
            try {
                mediaPlayer.setAudioAttributes(alarmAudioAttributes())
                mediaPlayer.setDataSource(this, uri)
                mediaPlayer.isLooping = true
                mediaPlayer.setWakeMode(this, PowerManager.PARTIAL_WAKE_LOCK)
                mediaPlayer.prepare()
                mediaPlayer.start()
                return mediaPlayer
            } catch (e: Exception) {
                Log.w(TAG, "Couldn't play $uri", e)
                mediaPlayer.release()
            }
        }
        return null
    }

    private fun startVibration() {
        val vib = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Vibrator::class.java)
        } ?: return
        if (!vib.hasVibrator()) return
        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> vib.vibrate(
                VibrationEffect.createWaveform(VIBRATION_PATTERN, 0),
                VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM),
            )
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O -> @Suppress("DEPRECATION") vib.vibrate(
                VibrationEffect.createWaveform(VIBRATION_PATTERN, 0),
                alarmAudioAttributes(),
            )
            else -> @Suppress("DEPRECATION") vib.vibrate(VIBRATION_PATTERN, 0, alarmAudioAttributes())
        }
        vibrator = vib
    }

    /** Rings even if focus is refused: the order still needs an answer. */
    private fun requestAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(alarmAudioAttributes())
                .setOnAudioFocusChangeListener(focusListener)
                .build()
            focusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                focusListener, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            )
        }
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(focusListener)
        }
    }
}
