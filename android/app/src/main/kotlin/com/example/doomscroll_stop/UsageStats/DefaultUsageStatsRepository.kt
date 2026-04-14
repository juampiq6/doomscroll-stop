package com.example.doomscroll_stop

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context

class DefaultUsageStatsRepository(private val context: Context) : UsageStatsRepository {
    override fun queryEvents(beginTime: Long, endTime: Long): Iterable<UsageEvents.Event> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val usageEvents = usageStatsManager.queryEvents(beginTime, endTime)
        
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
