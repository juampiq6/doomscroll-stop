package com.example.doomscroll_stop

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Android Foreground Service that polls for usage events and delegates doomscroll detection to
 * [DoomscrollDetector].
 *
 * This class handles only Android-specific concerns: lifecycle, foreground notification, intent
 * parsing, coroutine scheduling, and firing alerts.
 */
class DoomscrollDetectionService : Service() {

    companion object {
        const val TAG = "DoomscrollDetectionService"
        var isRunning = false

        // Intent actions
        const val ACTION_STOP_SERVICE = "com.example.doomscroll_stop.ACTION_STOP_SERVICE"

        // Intent extras keys
        const val APP_TIME_LIMITS_PARAM = "app_time_limits"
        const val APP_JUMP_THRESHOLD_PARAM = "app_jump_threshold"
    }

    /// Scheduled coroutine
    private var pollingJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.Default)

    private val usageStatsProvider by lazy { UsageStatsProvider(DefaultUsageStatsRepository(this)) }
    private val notificationHelper by lazy { NotificationHelper(this) }
    private var detector: DoomscrollDetector? = null

    /** Timestamp of the last event query. */
    @Volatile private var lastQueryTime: Long = 0L

    /// Lifecycle methods
    override fun onCreate() {
        super.onCreate()
        isRunning = true
        notificationHelper.createNotificationChannels()
        startForeground(
                NotificationHelper.FOREGROUND_NOTIF_ID,
                notificationHelper.buildForegroundNotification()
        )
        Log.d(TAG, "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null) {
            if (intent.action == ACTION_STOP_SERVICE) {
                Log.d(TAG, "Stop action received via intent")
                stopSelf()
                return START_NOT_STICKY
            }

            // Parse arguments from intent
            @Suppress("UNCHECKED_CAST")
            val newAppTimeLimitsMap =
                    intent.getSerializableExtra(APP_TIME_LIMITS_PARAM) as?
                            java.util.HashMap<String, Int>

            if (newAppTimeLimitsMap.isNullOrEmpty()) {
                Log.e(TAG, "Failed to parse app_time_limits intent arguments. Stopping service.")
                stopSelf()
                return START_NOT_STICKY
            }

            val appJumpThresholdMs =
                    intent.getLongExtra(APP_JUMP_THRESHOLD_PARAM, 30000L)

            detector =
                    DoomscrollDetector(
                            timeLimits = newAppTimeLimitsMap.mapValues { it.value.toLong() },
                            appJumpThresholdMs = appJumpThresholdMs,
                    )

            if (lastQueryTime == 0L) {
                lastQueryTime = System.currentTimeMillis()
            }

            restartPollingLoop()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        pollingJob?.cancel()
        Log.d(TAG, "Service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /// Polling loop
    private fun restartPollingLoop() {
        pollingJob?.cancel()
        pollingJob =
                serviceScope.launch {
                    while (true) {
                        val d = detector ?: break
                        val now = System.currentTimeMillis()

                        // 1. Query events since last check
                        val events =
                                usageStatsProvider.getEvents(
                                        lastQueryTime,
                                        now,
                                        d.trackedPackages
                                )
                        lastQueryTime = now

                        // 2. Process historical events (build session state)
                        d.processEvents(events)

                        // 3. Live watchdog check
                        val pkg = d.performCheck()

                        // 4. Fire notifications for any new alerts
                        if (pkg != null) {
                            notificationHelper.sendDoomscrollAlert(pkg)
                            d.restartSession(pkg, now)
                        }

                        delay(d.computeNextCheckDelay())
                    }
                }
    }
}
