package com.example.doomscroll_stop

import android.app.usage.UsageEvents

class UsageStatsProvider(private val repository: UsageStatsRepository) {

    // -------------------------------------------------------------------------
    // Data classes
    // -------------------------------------------------------------------------

    /** Raw event for the service's real-time session tracking. */
    data class AppEvent(
            val packageName: String,
            val eventType: Int,
            val timestamp: Long
    )

    /** Computed usage summary for on-demand queries (e.g. MainActivity). */
    data class UsageData(
            val totalUsage: Map<String, Long>,
            val hasInteraction: Map<String, Boolean>
    )

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    /**
     * Returns raw app lifecycle events for the given time window. Used by
     * [DoomscrollDetectionService] to drive its own session state machine.
     *
     * Only ACTIVITY_RESUMED/MOVE_TO_FOREGROUND, ACTIVITY_PAUSED/MOVE_TO_BACKGROUND,
     * and USER_INTERACTION events are included.
     */
    fun getEvents(
            startTime: Long,
            endTime: Long,
            filteredPackages: Set<String>? = null
    ): List<AppEvent> {
        val events = repository.queryEvents(startTime, endTime, filteredPackages)
        val result = mutableListOf<AppEvent>()

        for (event in events) {
            val pkg = event.packageName
            if (filteredPackages != null && pkg !in filteredPackages) continue

            val type =
                    when (event.eventType) {
                        UsageEvents.Event.ACTIVITY_RESUMED,
                        UsageEvents.Event.MOVE_TO_FOREGROUND ->
                                UsageEvents.Event.ACTIVITY_RESUMED
                        UsageEvents.Event.ACTIVITY_PAUSED,
                        UsageEvents.Event.MOVE_TO_BACKGROUND ->
                                UsageEvents.Event.ACTIVITY_PAUSED
                        UsageEvents.Event.USER_INTERACTION ->
                                UsageEvents.Event.USER_INTERACTION
                        else -> continue
                    }

            result.add(AppEvent(pkg, type, event.timeStamp))
        }

        return result
    }

    /**
     * Computes total foreground time and interaction flags per package for the
     * given time window. Self-contained — pairs RESUMED/PAUSED events internally
     * and projects still-open sessions up to [endTime].
     *
     * Used by [MainActivity.handleGetUsageStats] for on-demand usage queries.
     */
    fun getUsageData(
            startTime: Long,
            endTime: Long,
            filteredPackages: Set<String>? = null
    ): UsageData {
        val events = getEvents(startTime, endTime, filteredPackages)

        val sessionStart = mutableMapOf<String, Long>()
        val totalUsage = mutableMapOf<String, Long>()
        val hasInteraction = mutableMapOf<String, Boolean>()

        for (event in events) {
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    sessionStart[event.packageName] = event.timestamp
                }
                UsageEvents.Event.ACTIVITY_PAUSED -> {
                    val start = sessionStart.remove(event.packageName)
                    if (start != null) {
                        val duration = event.timestamp - start
                        if (duration > 0) {
                            totalUsage[event.packageName] =
                                    (totalUsage[event.packageName] ?: 0L) + duration
                        }
                    }
                }
                UsageEvents.Event.USER_INTERACTION -> {
                    hasInteraction[event.packageName] = true
                }
            }
        }

        // Project still-open sessions up to endTime
        for ((pkg, start) in sessionStart) {
            val duration = endTime - start
            if (duration > 0) {
                totalUsage[pkg] = (totalUsage[pkg] ?: 0L) + duration
            }
        }

        return UsageData(totalUsage, hasInteraction)
    }
}
