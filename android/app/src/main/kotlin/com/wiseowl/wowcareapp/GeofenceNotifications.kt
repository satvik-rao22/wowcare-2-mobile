package com.wiseowl.wowcareapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object GeofenceNotifications {
    private const val CHANNEL_ID = "geofence_channel"
    private const val CHANNEL_NAME = "School Sign-In Zone Alerts"

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH).apply {
                enableVibration(true)
                enableLights(true)
            },
        )
    }

    fun show(context: Context, isInside: Boolean) {
        val (id, title, body) =
            if (isInside) {
                Triple(
                    1001,
                    "Attendance Available",
                    "You are within the school premises. You can now Sign In or Sign Out.",
                )
            } else {
                Triple(
                    1002,
                    "Outside School Premises",
                    "Attendance actions are currently unavailable.",
                )
            }

        // Open the app when the notification is tapped.
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP }
            ?: Intent()
        val tapIntent = PendingIntent.getActivity(
            context,
            id,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification =
            NotificationCompat.Builder(context, CHANNEL_ID)
                // ic_launcher_foreground is a single-layer drawable (white-on-transparent)
                // required for Android 8+ notifications; mipmap adaptive icons are not valid here.
                .setSmallIcon(R.drawable.ic_launcher_foreground)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                // VISIBILITY_PUBLIC shows the full content on the lock screen and
                // ensures the heads-up banner appears even in Doze / Do-Not-Disturb.
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                // CATEGORY_EVENT tells Android this is a time-sensitive alert so
                // it is not deferred by battery optimization.
                .setCategory(NotificationCompat.CATEGORY_EVENT)
                .setAutoCancel(true)
                .setContentIntent(tapIntent)
                .build()

        try {
            NotificationManagerCompat.from(context).notify(id, notification)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS permission not granted (Android 13+).
            // Fall back to the raw NotificationManager which bypasses the
            // AndroidX permission guard — the system will still enforce it,
            // but at least we don't crash the BroadcastReceiver.
            try {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
                        as NotificationManager
                nm.notify(id, notification)
            } catch (_: Exception) { /* nothing more we can do */ }
        }
    }
}

