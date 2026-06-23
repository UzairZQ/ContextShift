package com.example.context_shift

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "context_shift/device_storage"
        ).setMethodCallHandler { call, result ->
            if (call.method != "getStorageInfo") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val stat = StatFs(filesDir.absolutePath)
            val availableBytes = stat.availableBytes
            val totalBytes = stat.totalBytes
            result.success(
                mapOf(
                    "availableBytes" to availableBytes,
                    "totalBytes" to totalBytes,
                )
            )
        }
    }
}
