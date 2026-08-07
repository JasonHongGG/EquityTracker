package com.jasonhong.equity_tracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FlutterVoiceCommandReceiver.setFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        super.onDestroy()
        flutterEngine?.let { FlutterVoiceCommandReceiver.clearFlutterEngine(it) }
    }
}
