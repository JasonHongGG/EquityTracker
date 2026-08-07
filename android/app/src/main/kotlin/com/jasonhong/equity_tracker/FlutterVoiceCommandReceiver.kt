package com.jasonhong.equity_tracker

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

object FlutterVoiceCommandReceiver {
    private const val CHANNEL = "com.equitytracker.voice/commands"
    private var backgroundFlutterEngine: FlutterEngine? = null

    fun processCommand(
        context: Context,
        amount: Double,
        category: String,
        description: String,
        date: String
    ) {
        Handler(Looper.getMainLooper()).post {
            val engine = getOrCreateFlutterEngine(context)
            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            
            val payload = mapOf(
                "amount" to amount,
                "category" to category,
                "description" to description,
                "date" to date
            )
            
            channel.invokeMethod("createTransaction", payload)
        }
    }

    fun setFlutterEngine(engine: FlutterEngine) {
        backgroundFlutterEngine = engine
    }

    fun clearFlutterEngine(engine: FlutterEngine) {
        if (backgroundFlutterEngine == engine) {
            backgroundFlutterEngine = null
        }
    }

    private fun getOrCreateFlutterEngine(context: Context): FlutterEngine {
        // If engine already exists (app is in foreground or already spun up in background)
        backgroundFlutterEngine?.let { return it }

        // Create a new headless FlutterEngine for background execution
        val engine = FlutterEngine(context.applicationContext)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        backgroundFlutterEngine = engine
        return engine
    }
}
