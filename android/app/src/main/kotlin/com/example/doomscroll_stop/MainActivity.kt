package com.example.doomscroll_stop

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {

    private lateinit var notificationHelper: NotificationHelper
    private lateinit var usageStatsProvider: UsageStatsProvider

    companion object {
        private const val CHANNEL = "com.example.doomscroll_stop/doomscroll"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val appProvider = PackageManagerProvider(this)
        notificationHelper = NotificationHelper(this)
        usageStatsProvider = UsageStatsProvider(DefaultUsageStatsRepository(this))

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "startService" -> handleStartService(call, result)
                "stopService" -> handleStopService(result)
                "testNotification" -> handleTestNotification(result)
                "getAppUsageStats" -> handleGetUsageStats(call, result)
                "isServiceRunning" -> result.success(DoomscrollDetectionService.isRunning)
                "hasUsagePermission" -> result.success(hasUsagePermission())
                "openUsageSettings" -> handleOpenUsageSettings(result)
                "getInstalledApps" -> handleGetInstalledApps(call, result, appProvider)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleStartService(
            call: io.flutter.plugin.common.MethodCall,
            result: MethodChannel.Result
    ) {
        if (DoomscrollDetectionService.isRunning) {
            result.error(
                    "SERVICE_ALREADY_RUNNING",
                    "Service already created, stop current service and try starting again",
                    null
            )
            return
        }

        val appTimeLimits = call.argument<Map<String, Int>>("appTimeLimits") ?: emptyMap()
        val appJumpThresholdMs = call.argument<Long>("appJumpThreshold") ?: 30000L

        val intent =
                Intent(this, DoomscrollDetectionService::class.java).apply {
                    putExtra(
                            DoomscrollDetectionService.APP_TIME_LIMITS_PARAM,
                            HashMap(appTimeLimits)
                    )
                    putExtra(
                            DoomscrollDetectionService.APP_JUMP_THRESHOLD_PARAM,
                            appJumpThresholdMs
                    )
                }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }

        result.success(null)
    }

    private fun handleStopService(result: MethodChannel.Result) {
        stopService(Intent(this, DoomscrollDetectionService::class.java))
        result.success(null)
    }

    private fun handleTestNotification(result: MethodChannel.Result) {
        notificationHelper.sendDoomscrollAlert(packageName)
        result.success(null)
    }

    private fun handleGetUsageStats(
            call: io.flutter.plugin.common.MethodCall,
            result: MethodChannel.Result
    ) {
        val beginTime = call.argument<Long>("beginTime") ?: 0L
        val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
        val filteredAppPackages =
                call.argument<List<String>>("filteredAppPackages")?.toSet() ?: null

        thread {
            try {
                Log.d("MainActivity", "getUsageData: startTime=$beginTime, endTime=$endTime")
                val usageData =
                        usageStatsProvider.getUsageData(beginTime, endTime, filteredAppPackages)

                // Convert UsageData to List<Map<String, Any>>
                val resultList =
                        usageData.map { (pkg, sessions) ->
                            mapOf("packageName" to pkg, "sessions" to sessions.map { it.toMap() })
                        }

                runOnUiThread { result.success(resultList) }
            } catch (e: Exception) {
                runOnUiThread { result.error("ERROR", e.message, null) }
            }
        }
    }

    private fun handleGetInstalledApps(
            call: io.flutter.plugin.common.MethodCall,
            result: MethodChannel.Result,
            appProvider: PackageManagerProvider
    ) {
        val includeSystemApps = call.argument<Boolean>("includeSystemApps") ?: false
        thread {
            try {
                val apps = appProvider.getInstalledApps(includeSystemApps)
                runOnUiThread { result.success(apps) }
            } catch (e: Exception) {
                runOnUiThread { result.error("ERROR", e.message, null) }
            }
        }
    }

    private fun handleOpenUsageSettings(result: MethodChannel.Result) {
        val intent = Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
        result.success(null)
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    appOps.unsafeCheckOpNoThrow(
                            AppOpsManager.OPSTR_GET_USAGE_STATS,
                            Process.myUid(),
                            packageName
                    )
                } else {
                    @Suppress("DEPRECATION")
                    appOps.checkOpNoThrow(
                            AppOpsManager.OPSTR_GET_USAGE_STATS,
                            Process.myUid(),
                            packageName
                    )
                }
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
