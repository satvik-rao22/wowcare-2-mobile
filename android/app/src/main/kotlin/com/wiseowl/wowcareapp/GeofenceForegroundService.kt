package com.wiseowl.wowcareapp

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

/**
 * Minimal foreground service whose sole purpose is to keep the app process
 * alive on OEM devices (Samsung, Xiaomi, Oppo, Vivo, Huawei) that aggressively
 * kill backgrounded processes, which prevents GeofenceBroadcastReceiver from
 * being delivered.
 *
 * The service does NOT request location updates, poll GPS, run timers, or
 * perform any work. It simply holds a foreground notification so the OS treats
 * the process as foreground-priority and does not subject it to background
 * execution limits.
 *
 * Lifecycle:
 *   - Started by GeofencePlugin when gpsSignInEnabled == true.
 *   - Stopped by GeofencePlugin when gpsSignInEnabled == false.
 *   - Re-started by GeofenceBootReceiver after reboot (if gpsSignInEnabled).
 */
class GeofenceForegroundService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // This is a location-type FGS. On Android 14+ (and strictly on 16),
        // startForeground() throws SecurityException unless a location runtime
        // permission is granted at this moment. The service can be started at
        // app launch / boot before the user has granted location — in that case
        // stop gracefully instead of crashing the app. GeofencePlugin will
        // (re)start it once GPS sign-in is enabled and permission is granted.
        if (!hasLocationPermission()) {
            stopSelf()
            return START_NOT_STICKY
        }
        try {
            startForeground(NOTIFICATION_ID, buildNotification())
        } catch (e: Exception) {
            // Any OS rejection (eligibility, type) → don't crash the process.
            stopSelf()
            return START_NOT_STICKY
        }
        // START_STICKY: if the OS kills the service, restart it automatically
        // (without re-delivering the last intent, which is fine — we don't use
        // the intent for anything).
        return START_STICKY
    }

    private fun hasLocationPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }

    private fun buildNotification(): Notification {
        ensureChannel()
        val tapIntent = packageManager
            .getLaunchIntentForPackage(packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_SINGLE_TOP }
            ?: Intent()
        val tapPending = PendingIntent.getActivity(
            this,
            0,
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle("WowCare Attendance")
            .setContentText("GPS attendance monitoring is active")
            // LOW importance + no sound/vibration → silent, collapsed in tray.
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(tapPending)
            .build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "Attendance Monitoring",
                // IMPORTANCE_LOW: no sound, no vibration, shown only in the
                // notification shade (not as a heads-up banner).
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Keeps GPS attendance active in the background"
                setShowBadge(false)
            },
        )
    }

    companion object {
        private const val CHANNEL_ID = "geofence_monitoring_service"
        const val NOTIFICATION_ID = 9001

        fun start(context: Context) {
            // A location-type FGS started without location permission crashes on
            // Android 14+. Skip starting until permission is granted; callers
            // re-invoke this after the GPS permission flow.
            if (!hasLocationPermission(context)) return
            val intent = Intent(context, GeofenceForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        private fun hasLocationPermission(context: Context): Boolean {
            val fine = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED
            val coarse = ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED
            return fine || coarse
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, GeofenceForegroundService::class.java))
        }
    }
}
