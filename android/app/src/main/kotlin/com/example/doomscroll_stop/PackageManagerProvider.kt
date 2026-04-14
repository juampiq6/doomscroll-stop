package com.example.doomscroll_stop

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import java.io.ByteArrayOutputStream

class PackageManagerProvider(private val context: Context) {

    fun getInstalledApps(includeSystemApps: Boolean = false): List<Map<String, Any>> {
        val packageManager = context.packageManager
        val intent =
                Intent(Intent.ACTION_MAIN, null).apply { addCategory(Intent.CATEGORY_LAUNCHER) }
        val resolveInfos = packageManager.queryIntentActivities(intent, 0)

        val apps = mutableListOf<Map<String, Any>>()

        for (resolveInfo in resolveInfos) {
            if (!includeSystemApps) {
                val appInfo = resolveInfo.activityInfo.applicationInfo
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                if (isSystemApp) continue
            }

            val packageName = resolveInfo.activityInfo.packageName
            // Skip our own app if needed, or allow it
            val appName = resolveInfo.loadLabel(packageManager).toString()
            val iconDrawable = resolveInfo.loadIcon(packageManager)
            val iconBytes = drawableToByteArray(iconDrawable)

            apps.add(
                    mapOf(
                            "appName" to appName,
                            "packageName" to packageName,
                            "icon" to iconBytes,
                    )
            )
        }

        return apps
    }

    fun getAppName(packageName: String): String {
        return try {
            val pm = context.packageManager
            val info = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(info).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    private fun drawableToByteArray(drawable: Drawable): ByteArray {
        val bitmap =
                if (drawable is BitmapDrawable && drawable.bitmap != null) {
                    drawable.bitmap
                } else {
                    val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 1
                    val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 1
                    val b = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(b)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    b
                }

        val outputStream = ByteArrayOutputStream()
        // Compress to PNG to preserve transparency
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        return outputStream.toByteArray()
    }
}
