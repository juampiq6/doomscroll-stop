package com.example.doomscroll_stop

import android.app.usage.UsageEvents

interface UsageStatsRepository {
    /**
     * Queries usage events for the given time range. Returns an Iterable of [UsageEvents.Event].
     */
    fun queryEvents(
            beginTime: Long,
            endTime: Long,
            filteredAppPackages: Set<String>? = null
    ): Iterable<UsageEvents.Event>
}
