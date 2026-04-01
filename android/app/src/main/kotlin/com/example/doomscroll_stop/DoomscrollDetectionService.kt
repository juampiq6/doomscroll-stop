package com.example.doomscroll_stop

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class DoomscrollDetectionService : Service() {

    companion object {
        const val TAG = "DoomscrollDetectionService"

        // Intent extras keys
        const val EXTRA_PACKAGES_NAMES = "packages_names"
        const val EXTRA_MIN_TIME_ELAPSED = "min_time_elapsed"
        const val EXTRA_INITIAL_TIME = "query_initial_time"

        // Notification channels
        const val FOREGROUND_CHANNEL_ID = "doomscrolldetector_foreground"
        const val ALERT_CHANNEL_ID = "doomscrolldetector_alert"
        const val FOREGROUND_NOTIF_ID = 1
        const val ALERT_NOTIF_BASE_ID = 1000
    }

    // --- Service state (updated dynamically via onStartCommand) ---
    @Volatile private var packageNames: List<String> = emptyList()
    @Volatile private var minimumTimeElapsed: Long = 60L   // seconds
    @Volatile private var lastQueryTime: Long = 0L

    private var pollingJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.Default)

    // Track which packages have already been notified so we don't spam
    private val notifiedPackages = mutableSetOf<String>()

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
        startForeground(FOREGROUND_NOTIF_ID, buildForegroundNotification())
        Log.d(TAG, "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null) {
            // Parse arguments from intent
            val newPackages = intent.getStringArrayListExtra(EXTRA_PACKAGE_NAMES) ?: arrayListOf()
            val newMinTime = intent.getLongExtra(EXTRA_MIN_TIME_ELAPSED, minimumTimeElapsed)
            val newInitialTime = intent.getLongExtra(EXTRA_INITIAL_TIME, lastQueryTime)

            val paramsChanged = newPackages != packageNames || newMinTime != minimumTimeElapsed

            packageNames = newPackages
            minimumTimeElapsed = newMinTime

            // Only reset lastQueryTime if an explicit initial time was provided (i.e. first start)
            if (lastQueryTime == 0L || paramsChanged) {
                lastQueryTime = newInitialTime
                notifiedPackages.clear()
                Log.d(TAG, "Params updated — packages=$packageNames, minTime=${minimumTimeElapsed}s, lastQueryTime=$lastQueryTime")
            }

            restartPollingLoop()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        pollingJob?.cancel()
        Log.d(TAG, "Service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // -------------------------------------------------------------------------
    // Adaptive polling loop
    // -------------------------------------------------------------------------

    private fun restartPollingLoop() {
        pollingJob?.cancel()
        pollingJob = serviceScope.launch {
            while (true) {
                val delayMs = performCheck()
                Log.d(TAG, "Next poll in ${delayMs}ms")
                delay(delayMs)
            }
        }
    }

    /**
     * Queries usage events since [lastQueryTime], computes time-in-app & tap 
     * detection for each tracked package, fires notifications where needed,
     * then returns the next polling delay in milliseconds using adaptive logic:
     *
     *   - Base delay = minimumTimeElapsed / 2
     *   - If any app has usage > minimumTimeElapsed/2:
     *       nextDelay = (minimumTimeElapsed - maxUsage) / 2   (clamped to ≥1s)
     */
    private fun performCheck(): Long {
        val now = System.currentTimeMillis()
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val events = usageStatsManager.queryEvents(lastQueryTime, now)

        // Per-package accumulators
        val sessionStart = mutableMapOf<String, Long>()          // pkg -> resume timestamp
        val totalUsage = mutableMapOf<String, Long>()            // pkg -> ms in foreground
        val hasTap = mutableMapOf<String, Boolean>()             // pkg -> had USER_INTERACTION

        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName
            if (pkg !in packageNames) continue

            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    sessionStart[pkg] = event.timeStamp
                }
                UsageEvents.Event.ACTIVITY_PAUSED -> {
                    val start = sessionStart.remove(pkg)
                    if (start != null) {
                        totalUsage[pkg] = (totalUsage[pkg] ?: 0L) + (event.timeStamp - start)
                    }
                }
                UsageEvents.Event.USER_INTERACTION -> {
                    if (pkg in packageNames) hasTap[pkg] = true
                }
            }
        }

        // Accumulate any still-open sessions (app was resumed but not paused yet)
        for ((pkg, start) in sessionStart) {
            totalUsage[pkg] = (totalUsage[pkg] ?: 0L) + (now - start)
        }

        // Update lastQueryTime for next cycle
        lastQueryTime = now

        val minMs = minimumTimeElapsed * 1000L
        val halfMinMs = minMs / 2L

        var maxUsageMs = 0L

        // Evaluate each tracked package
        for (pkg in packageNames) {
            val usageMs = totalUsage[pkg] ?: 0L
            if (usageMs > maxUsageMs) maxUsageMs = usageMs

            val tapped = hasTap[pkg] == true
            val overThreshold = usageMs >= minMs

            Log.d(TAG, "[$pkg] usage=${usageMs}ms tapped=$tapped overThreshold=$overThreshold")

            if (overThreshold && tapped && pkg !in notifiedPackages) {
                val appName = getAppName(pkg)
                sendDoomscrollAlert(pkg, appName)
                notifiedPackages.add(pkg)
            }

            // Reset notification suppression if user has left the app (no session start)
            if (pkg !in sessionStart && usageMs == 0L) {
                notifiedPackages.remove(pkg)
            }
        }

        // Adaptive delay calculation
        return if (maxUsageMs >= halfMinMs) {
            // Closing in on the threshold — shrink the interval
            val remaining = minMs - maxUsageMs
            val nextDelay = remaining / 2L
            nextDelay.coerceAtLeast(1_000L)   // minimum 1 second
        } else {
            // Safe — use the default half-minimum interval
            halfMinMs.coerceAtLeast(5_000L)   // minimum 5 seconds when still far away
        }
    }

    // -------------------------------------------------------------------------
    // Notification helpers
    // -------------------------------------------------------------------------

    private fun createNotificationChannels() {
        val nm = getSystemService(NotificationManager::class.java)

        // Silent foreground channel
        val fgChannel = NotificationChannel(
            FOREGROUND_CHANNEL_ID,
            "Doomscroll Tracker",
            NotificationManager.IMPORTANCE_MIN
        ).apply {
            description = "Keeps the doomscroll tracker running in the background"
            setShowBadge(false)
        }

        // High-importance alert channel
        val alertChannel = NotificationChannel(
            ALERT_CHANNEL_ID,
            "Doomscroll Alerts",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Alerts you when you've been doomscrolling too long"
            enableVibration(true)
        }

        nm.createNotificationChannel(fgChannel)
        nm.createNotificationChannel(alertChannel)
    }

    private fun buildForegroundNotification(): Notification {
        return NotificationCompat.Builder(this, FOREGROUND_CHANNEL_ID)
            .setContentTitle("Doomscroll Tracker")
            .setContentText("Watching your screen time…")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun sendDoomscrollAlert(pkg: String, appName: String) {
        val nm = getSystemService(NotificationManager::class.java)
        val notification = NotificationCompat.Builder(this, ALERT_CHANNEL_ID)
            .setContentTitle("Hey! Enough doomscrolling! 📵")
            .setContentText("Hey! Stop doomscrolling in $appName")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("Hey! Stop doomscrolling in $appName"))
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        // Use a unique ID per package so multiple apps can notify independently
        val notifId = ALERT_NOTIF_BASE_ID + pkg.hashCode()
        nm.notify(notifId, notification)
        Log.d(TAG, "Alert fired for $appName ($pkg)")
    }

    private fun getAppName(packageName: String): String {
        return try {
            val pm = applicationContext.packageManager
            val info = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(info).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }
}
