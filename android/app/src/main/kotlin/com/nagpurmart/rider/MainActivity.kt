package com.nagpurmart.rider

import android.content.Intent
import com.nagpurmart.rider.orderalert.OrderAlertChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var orderAlertChannel: OrderAlertChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
