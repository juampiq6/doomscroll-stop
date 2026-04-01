package com.example.doomscroll_stop

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.example.doomscroll_stop/doomscroll"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val packageNames = call.argument<List<String>>("packageNames") ?: emptyList()
                        val minTimeElapsed = call.argument<Int>("minimumTimeElapsed") ?: 60
                        val initialTime = call.argument<Long>("initialTime") ?: System.currentTimeMillis()

                        val intent = Intent(this, DoomscrollService::class.java).apply {
                            putStringArrayListExtra(
                                DoomscrollService.EXTRA_PACKAGE_NAMES,
                                ArrayList(packageNames)
                            )
                            putExtra(DoomscrollService.EXTRA_MIN_TIME_ELAPSED, minTimeElapsed.toLong())
                            putExtra(DoomscrollService.EXTRA_INITIAL_TIME, initialTime)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }

                        result.success(null)
                    }

                    "stopService" -> {
                        stopService(Intent(this, DoomscrollService::class.java))
                        result.success(null)
                    }

                    "updateService" -> {
                        // Re-send intent to running service with new args — onStartCommand updates state
                        val packageNames = call.argument<List<String>>("packageNames") ?: emptyList()
                        val minTimeElapsed = call.argument<Int>("minimumTimeElapsed") ?: 60
                        val initialTime = call.argument<Long>("initialTime") ?: System.currentTimeMillis()

                        val intent = Intent(this, DoomscrollService::class.java).apply {
                            putStringArrayListExtra(
                                DoomscrollService.EXTRA_PACKAGE_NAMES,
                                ArrayList(packageNames)
                            )
                            putExtra(DoomscrollService.EXTRA_MIN_TIME_ELAPSED, minTimeElapsed.toLong())
                            putExtra(DoomscrollService.EXTRA_INITIAL_TIME, initialTime)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }

                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
