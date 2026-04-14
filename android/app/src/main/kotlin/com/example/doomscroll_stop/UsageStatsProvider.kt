package com.example.doomscroll_stop

import android.app.usage.UsageEvents
import android.util.Log

class UsageStatsProvider(private val repository: UsageStatsRepository) {

    data class UsageData(
            val totalUsage: Map<String, Long>,
            val hasInteraction: Map<String, Boolean>,
            val sessionStart: Map<String, Long>
    )

    fun getUsageData(
            startTime: Long,
            endTime: Long,
            filteredAppPackages: Set<String>? = null,
            previousSessionStart: Map<String, Long> = emptyMap()
    ): UsageData {
        val events = repository.queryEvents(startTime, endTime)

        val sessionStart = previousSessionStart.toMutableMap()
        val totalUsage = mutableMapOf<String, Long>()
        val hasInteraction = mutableMapOf<String, Boolean>()

        for (event in events) {
            Log.d("UsageStatsProvider", "Event: ${event.eventType}, Package: ${event.packageName}")
            val pkg = event.packageName
            // if appTimeLimits is provided and pkg is not in it, skip
            if (filteredAppPackages != null && !filteredAppPackages.contains(pkg)) continue

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
                    hasInteraction[pkg] = true
                }
            }
        }

        // Accumulate still-open sessions only if endTime is 'now' or close to 'now'
        // For historical queries, we might not want to project 'now' into the past.
        // But for simplicity, we'll use endTime as the reference.
        for ((pkg, start) in sessionStart) {
            if (start < endTime) {
                totalUsage[pkg] = (totalUsage[pkg] ?: 0L) + (endTime - start)
            }
        }

        return UsageData(totalUsage, hasInteraction, sessionStart)
    }
}
