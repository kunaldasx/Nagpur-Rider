package com.nagpurmart.rider

import android.content.Context
import android.content.Intent
import com.nagpurmart.rider.orderalert.OrderAlertChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {
    companion object {
        private const val DUTY_ENGINE = "rider_main_engine"
    }

    // Geolocator's foreground service needs the main Dart isolate after the
    // task is swiped away. Reuse that engine when the rider opens the app again.
    override fun provideFlutterEngine(context: Context): FlutterEngine? =
        FlutterEngineCache.getInstance().get(DUTY_ENGINE)

    override fun shouldDestroyEngineWithHost(): Boolean = false

    private var orderAlertChannel: OrderAlertChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FlutterEngineCache.getInstance().put(DUTY_ENGINE, flutterEngine)
        orderAlertChannel = OrderAlertChannel(this, flutterEngine.dartExecutor.binaryMessenger)
            .also { it.handleIntent(intent) }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        orderAlertChannel?.dispose()
        orderAlertChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        orderAlertChannel?.handleIntent(intent)
    }
}
