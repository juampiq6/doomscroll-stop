package com.example.doomscroll_stop

import android.app.usage.UsageEvents

class UsageStatsProvider(private val repository: UsageStatsRepository) {

    // -------------------------------------------------------------------------
    // Data classes
    // -------------------------------------------------------------------------

    /** Raw event for the service's real-time session tracking. */
    data class AppEvent(val packageName: String, val eventType: Int, val timestamp: Long)

    /** Individual session of app usage. */
    data class AppSession(val startTime: Long, val stopTime: Long, val hasInteraction: Boolean) {
        fun toMap() =
                mapOf(
                        "startTime" to startTime,
                        "stopTime" to stopTime,
                        "hasInteraction" to hasInteraction
                )
    }

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    /**
     * Returns raw app lifecycle events for the given time window. Used by
     * [DoomscrollDetectionService] to drive its own session state machine.
     *
     * Only ACTIVITY_RESUMED/MOVE_TO_FOREGROUND, ACTIVITY_PAUSED/MOVE_TO_BACKGROUND, and
     * USER_INTERACTION events are included.
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
                        UsageEvents.Event.ACTIVITY_RESUMED, UsageEvents.Event.MOVE_TO_FOREGROUND ->
                                UsageEvents.Event.ACTIVITY_RESUMED
                        UsageEvents.Event.ACTIVITY_PAUSED, UsageEvents.Event.MOVE_TO_BACKGROUND ->
                                UsageEvents.Event.ACTIVITY_PAUSED
                        UsageEvents.Event.USER_INTERACTION -> UsageEvents.Event.USER_INTERACTION
                        else -> continue
                    }

            result.add(AppEvent(pkg, type, event.timeStamp))
        }

        return result
    }

    /**
     * Computes discrete usage sessions per package for the given time window.
     *
     * Used by [MainActivity.handleGetUsageStats] for on-demand usage queries.
     */
    fun getUsageData(
            startTime: Long,
            endTime: Long,
            filteredPackages: Set<String>? = null
    ): Map<String, List<AppSession>> {
        val events = getEvents(startTime, endTime, filteredPackages)

        val activeSessionStart = mutableMapOf<String, Long>()
        val activeSessionInteraction = mutableMapOf<String, Boolean>()
        val resultSessions = mutableMapOf<String, MutableList<AppSession>>()

        for (event in events) {
            val pkg = event.packageName
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    activeSessionStart[pkg] = event.timestamp
                    activeSessionInteraction[pkg] = false
                }
                UsageEvents.Event.ACTIVITY_PAUSED -> {
                    val start = activeSessionStart.remove(pkg)
                    val interaction = activeSessionInteraction.remove(pkg) ?: false
                    if (start != null) {
                        resultSessions
                                .getOrPut(pkg) { mutableListOf() }
                                .add(AppSession(start, event.timestamp, interaction))
                    }
                }
                UsageEvents.Event.USER_INTERACTION -> {
                    // Only flag interaction if we have an active session for this package
                    if (activeSessionStart.containsKey(pkg)) {
                        activeSessionInteraction[pkg] = true
                    }
                }
            }
        }

        // Add still-open sessions up to endTime
        for ((pkg, start) in activeSessionStart) {
            val interaction = activeSessionInteraction[pkg] ?: false
            resultSessions
                    .getOrPut(pkg) { mutableListOf() }
                    .add(AppSession(start, endTime, interaction))
        }

        return resultSessions
    }
}
