package com.example.image_flow

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "batch_background"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForeground" -> {
                        val total = call.argument<Int>("total") ?: 0
                        val completed = call.argument<Int>("completed") ?: 0
                        BatchForegroundService.start(this, total, completed)
                        result.success(null)
                    }
                    "updateForeground" -> {
                        val total = call.argument<Int>("total") ?: 0
                        val completed = call.argument<Int>("completed") ?: 0
                        BatchForegroundService.update(this, total, completed)
                        result.success(null)
                    }
                    "stopForeground" -> {
                        BatchForegroundService.stop(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
