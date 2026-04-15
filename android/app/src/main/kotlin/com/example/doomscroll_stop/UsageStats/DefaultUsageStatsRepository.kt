package com.example.doomscroll_stop

import android.app.usage.UsageEvents
import android.app.usage.UsageEventsQuery
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build

class DefaultUsageStatsRepository(private val context: Context) : UsageStatsRepository {
    override fun queryEvents(
            beginTime: Long,
            endTime: Long,
            filteredAppPackages: Set<String>?
    ): Iterable<UsageEvents.Event> {
        val usageStatsManager =
                context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val usageEvents =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM &&
                                filteredAppPackages != null
                ) {
                    val query =
                            UsageEventsQuery.Builder(beginTime, endTime)
                                    .setPackageNames(*filteredAppPackages.toTypedArray())
                                    .build()
                    usageStatsManager.queryEvents(query)
                } else {
                    usageStatsManager.queryEvents(beginTime, endTime)
                }

        if (usageEvents == null) return emptyList()

        return object : Iterable<UsageEvents.Event> {
            override fun iterator(): Iterator<UsageEvents.Event> {
                return object : Iterator<UsageEvents.Event> {
                    override fun hasNext(): Boolean {
                        return usageEvents.hasNextEvent()
                    }

                    override fun next(): UsageEvents.Event {
                        val event = UsageEvents.Event()
                        usageEvents.getNextEvent(event)
                        return event
                    }
                }
            }
        }
    }
}
