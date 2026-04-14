package com.example.doomscroll_stop

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.NotificationCompat

class NotificationHelper(private val context: Context) {

    private val packageManagerProvider = PackageManagerProvider(context)

    companion object {
        const val TAG = "NotificationHelper"
        const val FOREGROUND_CHANNEL_ID = "doomscrolldetector_foreground"
        const val ALERT_CHANNEL_ID = "doomscrolldetector_alert"
        const val FOREGROUND_NOTIF_ID = 1
        const val ALERT_NOTIF_BASE_ID = 1000
    }

    fun createNotificationChannels() {
        val nm = context.getSystemService(NotificationManager::class.java)

        // Silent foreground channel
        val fgChannel =
                NotificationChannel(
                                FOREGROUND_CHANNEL_ID,
                                "Doomscroll Tracker",
                                NotificationManager.IMPORTANCE_MIN
                        )
                        .apply {
                            description = "Keeps the doomscroll tracker running in the background"
                            setShowBadge(false)
                        }

        // High-importance alert channel
        val alertChannel =
                NotificationChannel(
                                ALERT_CHANNEL_ID,
                                "Doomscroll Alerts",
                                NotificationManager.IMPORTANCE_HIGH
                        )
                        .apply {
                            description = "Alerts you when you've been doomscrolling too long"
                            enableVibration(true)
                        }

        nm.createNotificationChannel(fgChannel)
        nm.createNotificationChannel(alertChannel)
    }

    fun buildForegroundNotification(): Notification {
        return NotificationCompat.Builder(context, FOREGROUND_CHANNEL_ID)
                .setContentTitle("Doomscroll Tracker")
                .setContentText("Watching your screen time…")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setOngoing(true)
                .setSilent(true)
                .build()
    }

    fun sendDoomscrollAlert(pkg: String) {
        createNotificationChannels() // Ensure channels exist before notifying
        val appName = packageManagerProvider.getAppName(pkg)
        val nm = context.getSystemService(NotificationManager::class.java)
        val notification =
                NotificationCompat.Builder(context, ALERT_CHANNEL_ID)
                        .setContentTitle("Hey! Enough doomscrolling! \uD83D\uDCF5")
                        .setContentText("Hey! Stop doomscrolling in $appName")
                        .setStyle(
                                NotificationCompat.BigTextStyle()
                                        .bigText("Hey! Stop doomscrolling in $appName")
                        )
                        .setSmallIcon(android.R.drawable.ic_dialog_alert)
                        .setAutoCancel(true)
                        .setPriority(NotificationCompat.PRIORITY_HIGH)
                        .build()

        // Use a unique ID per package so multiple apps can notify independently
        val notifId = ALERT_NOTIF_BASE_ID + pkg.hashCode()
        nm.notify(notifId, notification)
        Log.d(TAG, "Alert fired for $appName ($pkg)")
    }
}
