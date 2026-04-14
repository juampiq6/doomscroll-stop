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

class DoomscrollDetectionService : Service() {

    companion object {
        const val TAG = "DoomscrollDetectionService"
        var isRunning = false

        // Intent actions
        const val ACTION_STOP_SERVICE = "com.example.doomscroll_stop.ACTION_STOP_SERVICE"

        // Intent extras keys
        const val EXTRA_APP_TIME_LIMITS = "app_time_limits"
    }

    // --- Service state (updated dynamically via onStartCommand) ---
    @Volatile private var appTimeLimits: Map<String, Long> = emptyMap()
    @Volatile private var lastQueryTime: Long = 0L
    @Volatile private var activeSessions: Map<String, Long> = emptyMap()

    private var pollingJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.Default)

    private val usageStatsProvider by lazy { UsageStatsProvider(DefaultUsageStatsRepository(this)) }
    private val notificationHelper by lazy { NotificationHelper(this) }

    // Track which packages have already been notified so we don't spam
    private val notifiedPackages = mutableSetOf<String>()

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

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
                    intent.getSerializableExtra(EXTRA_APP_TIME_LIMITS) as?
                            java.util.HashMap<String, Int>

            if (newAppTimeLimitsMap == null) {
                Log.e(TAG, "Failed to parse app_time_limits intent arguments. Stopping service.")
                stopSelf()
                return START_NOT_STICKY
            }

            appTimeLimits = newAppTimeLimitsMap.mapValues { it.value.toLong() }

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

    // -------------------------------------------------------------------------
    // Adaptive polling loop
    // -------------------------------------------------------------------------

    private fun restartPollingLoop() {
        pollingJob?.cancel()
        pollingJob =
                serviceScope.launch {
                    while (true) {
                        val now = System.currentTimeMillis()
                        val usageData =
                                usageStatsProvider.getUsageData(
                                        lastQueryTime,
                                        now,
                                        appTimeLimits.keys,
                                        activeSessions
                                )
                        lastQueryTime = now
                        activeSessions = usageData.sessionStart

                        performCheck(usageData)
                        val delayMs = calculateNextDelay(usageData)

                        Log.d(TAG, "Next poll in ${delayMs}ms")
                        delay(delayMs)
                    }
                }
    }

    /**
     * Computes time-in-app & tap detection for each tracked package, fires notifications where
     * needed.
     */
    private fun performCheck(usageData: UsageStatsProvider.UsageData) {
        val totalUsage = usageData.totalUsage
        val hasInteraction = usageData.hasInteraction
        val sessionStart = usageData.sessionStart

        // Evaluate each tracked package
        for ((pkg, timeLimit) in appTimeLimits) {
            val appLimitMs = timeLimit * 1000L
            val usageMs = totalUsage[pkg] ?: 0L

            val tapped = hasInteraction[pkg] == true
            val overThreshold = usageMs >= appLimitMs

            Log.d(
                    TAG,
                    "[$pkg] usage=${usageMs}ms tapped=$tapped overThreshold=$overThreshold limit=$appLimitMs"
            )

            if (overThreshold && tapped && pkg !in notifiedPackages) {
                notificationHelper.sendDoomscrollAlert(pkg)
                notifiedPackages.add(pkg)
            }

            // Reset notification suppression if user has left the app (no session start)
            if (pkg !in sessionStart && usageMs == 0L) {
                notifiedPackages.remove(pkg)
            }
        }
    }

    /**
     * Returns the next polling delay in milliseconds using adaptive logic:
     *
     * - Base delay = minimum limit / 2
     * - If any app has usage > its limit/2:
     * ```
     *       nextDelay = (limit - usage) / 2   (clamped to ≥1s)
     * ```
     */
    private fun calculateNextDelay(usageData: UsageStatsProvider.UsageData): Long {
        val totalUsage = usageData.totalUsage
        var nextDelayMs = Long.MAX_VALUE

        // Evaluate each tracked package
        for ((pkg, minTimeElapsed) in appTimeLimits) {
            val minMs = minTimeElapsed * 1000L
            val halfMinMs = minMs / 2L

            val usageMs = totalUsage[pkg] ?: 0L

            // Adaptive delay logic for this app
            val appDelay =
                    if (usageMs >= halfMinMs) {
                        val remaining = minMs - usageMs
                        (remaining / 2L).coerceAtLeast(1_000L) // minimum 1 second
                    } else {
                        halfMinMs.coerceAtLeast(5_000L) // minimum 5 seconds
                    }

            if (appDelay < nextDelayMs) {
                nextDelayMs = appDelay
            }
        }

        if (nextDelayMs == Long.MAX_VALUE) {
            nextDelayMs = 5_000L
        }

        return nextDelayMs
    }
}
