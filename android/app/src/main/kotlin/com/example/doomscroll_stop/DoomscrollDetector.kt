package com.example.doomscroll_stop

import android.app.usage.UsageEvents
import android.util.Log

/**
 * Pure business logic for doomscroll detection. No Android Service dependencies.
 *
 * Maintains session state per tracked app and determines when a user has exceeded their configured
 * time limit. Uses an "app-jump threshold" to distinguish brief app switches (e.g. checking a
 * notification) from genuine session breaks.
 *
 * Usage:
 * 1. Call [updateTimeLimits] when configuration changes.
 * 2. On each polling tick, call [processEvents] with new events, then
 * ```
 *    [performLiveCheck] with the current timestamp.
 * ```
 * 3. Read [alerts] to get packages that just triggered an alert.
 */
class DoomscrollDetector(
        /** Package → time limit in seconds. */
        private val timeLimits: Map<String, Long>,
        /** Max gap (ms) to consider the same session (e.g. brief notification check). */
        private val appJumpThresholdMs: Long,
) {

    companion object {
        private const val TAG = "DoomscrollDetector"
    }

    /** Accumulated foreground time (ms) per app in the current session. */
    private val accumulatedActiveSessionTime = mutableMapOf<String, Long>()

    /** Timestamp of the last ACTIVITY_RESUMED event per app. */
    private val lastSessionStartEvent = mutableMapOf<String, Long>()

    /** Timestamp of the last ACTIVITY_PAUSED event per app. */
    private val lastSessionStopEvent = mutableMapOf<String, Long>()

    /** Packages that have already been alerted in their current session. */
    private val notifiedPackages = mutableSetOf<String>()

    /** The set of package names currently being tracked. */
    val trackedPackages: Set<String>
        get() = timeLimits.keys

    private fun totalSessionTime(pkg: String, now: Long): Long {
        val activeSession =
                if (lastSessionStartEvent[pkg] != null) now - lastSessionStartEvent[pkg]!! else 0L
        return (accumulatedActiveSessionTime[pkg] ?: 0L) + activeSession
    }

    /** Restarts the session and saves last activity start time. */
    fun restartSession(pkg: String, timestamp: Long) {
        notifiedPackages.remove(pkg)
        accumulatedActiveSessionTime[pkg] = 0L
        lastSessionStartEvent[pkg] = timestamp
        lastSessionStopEvent[pkg] = 0L
    }

    /** Processes usage events chronologically to build session state. */
    fun processEvents(events: List<UsageStatsProvider.AppEvent>, now: Long) {
        for (event in events) {
            val pkg = event.packageName

            // Only process events for apps we're tracking
            if (pkg !in timeLimits) continue

            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    val lastStopEvent = lastSessionStopEvent[pkg]

                    if (lastStopEvent == null ||
                                    (event.timestamp - lastStopEvent) > appJumpThresholdMs
                    ) {
                        // New session — resets accumulated time
                        accumulatedActiveSessionTime[pkg] = now - event.timestamp
                        lastSessionStopEvent[pkg] = 0L
                        notifiedPackages.remove(pkg)
                        Log.d(TAG, "[$pkg] New session detected")
                    }

                    lastSessionStartEvent[pkg] = event.timestamp
                }
                // When the app is paused, it accumulates that time to the total time
                UsageEvents.Event.ACTIVITY_PAUSED -> {
                    val start = lastSessionStartEvent.remove(pkg)
                    if (start != null) {
                        val duration = event.timestamp - start
                        accumulatedActiveSessionTime[pkg] =
                                (accumulatedActiveSessionTime[pkg] ?: 0L) + duration
                        Log.d(
                                TAG,
                                "[$pkg] Added ${duration}ms, total=${accumulatedActiveSessionTime[pkg]}ms"
                        )
                    }
                    lastSessionStopEvent[pkg] = event.timestamp
                }
            }
        }
    }

    /**
     * Checks all tracked apps to see if any have exceeded their time limit. Returns the package
     * name of the app that triggered an alert, or null if none.
     */
    fun performCheck(now: Long): String? {
        for (pkg in timeLimits.keys) {
            val limitMs = (timeLimits[pkg] ?: continue) * 1000L
            val accumulated = totalSessionTime(pkg, now)
            Log.d(TAG, "[$pkg] accumulated=$accumulated, limit=$limitMs")

            if (accumulated >= limitMs && pkg !in notifiedPackages) {
                Log.d(
                        TAG,
                        "ALARM: Doomscroll detected in $pkg! total=${accumulated}ms limit=${limitMs}ms"
                )
                notifiedPackages.add(pkg)
                return pkg
            }
        }
        return null
    }

    /**
     * Computes the optimal delay (ms) until the next polling check.
     *
     * Iterates all tracked apps and computes `(limit - accumulated)` for each. Returns the smallest
     * remaining time, clamped to at least [MIN_CHECK_INTERVAL_MS]. If no accumulated time exists
     * for an app, it defaults to 0.
     */
    fun computeNextCheckDelay(now: Long): Long {

        var criticalMinRemaining: Long? = null

        for ((pkg, limitSec) in timeLimits) {
            val limitMs = limitSec * 1000L
            if (criticalMinRemaining == null || limitMs < criticalMinRemaining) {
                criticalMinRemaining = limitMs
            }
            val sessionTime = totalSessionTime(pkg, now)

            // limit should always be greater than accumulated
            val remaining = limitMs - sessionTime

            Log.d(
                    TAG,
                    "[$pkg] next check in ${remaining}ms (limit=${limitMs}ms, session=${sessionTime}ms)"
            )

            if (remaining < criticalMinRemaining) {
                criticalMinRemaining = remaining
            }
        }

        return criticalMinRemaining!!
    }
}
