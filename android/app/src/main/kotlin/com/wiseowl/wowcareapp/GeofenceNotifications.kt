package com.wiseowl.wowcareapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object GeofenceNotifications {
    private const val CHANNEL_ID = "geofence_channel"
    private const val CHANNEL_NAME = "School Sign-In Zone Alerts"

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = nm.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH,
            ),
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

        val notification =
            NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()

        NotificationManagerCompat.from(context).notify(id, notification)
    }
}

