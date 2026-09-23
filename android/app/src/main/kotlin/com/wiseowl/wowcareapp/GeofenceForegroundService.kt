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
import android.util.Log
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
        // startForegroundService() creates a contract: this service MUST reach
        // the foreground within a few seconds, or the OS kills the whole app
        // with ForegroundServiceDidNotStartInTimeException. stopSelf() does NOT
        // discharge it — so startForeground() is attempted first, before any
        // decision about whether we should be running at all.
        //
        // Deliberately NOT guarded by a permission check: below API 34 a
        // `location`-type startForeground() does not require the grant, so
        // skipping the call there would break a case that works and leave the
        // contract unsatisfied. On API 34+ a missing grant throws
        // SecurityException, which the catch below absorbs.
        try {
            startForeground(NOTIFICATION_ID, buildNotification())
        } catch (t: Throwable) {
            Log.e(TAG, "startForeground failed: $t")
            stopSelf(startId)
            return START_NOT_STICKY
        }

        // Now that the contract is satisfied, it is safe to stand down. Without
        // background location the geofence never fires while backgrounded, so
        // the keep-alive has nothing to keep alive for.
        if (!hasBackgroundLocationPermission(this)) {
            Log.w(TAG, "No background location permission; stopping service")
            stopSelf(startId)
            return START_NOT_STICKY
        }

        // START_STICKY: if the OS kills the service, restart it automatically
        // (without re-delivering the last intent, which is fine — we don't use
        // the intent for anything).
        return START_STICKY
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
        private const val TAG = "GeofenceFgService"
        const val NOTIFICATION_ID = 9001

        /**
         * Android 14+ (API 34) rejects a `location`-type foreground service
         * unless ACCESS_FINE_LOCATION or ACCESS_COARSE_LOCATION is granted at
         * runtime, and it signals that by throwing SecurityException from
         * startForeground() — i.e. by crashing the app. Callers reached before
         * the user has granted anything (notably ACTION_MY_PACKAGE_REPLACED,
         * which fires on every install/update) must check this first.
         */
        fun hasLocationPermission(context: Context): Boolean {
            fun granted(permission: String) =
                ContextCompat.checkSelfPermission(context, permission) ==
                    PackageManager.PERMISSION_GRANTED
            return granted(Manifest.permission.ACCESS_FINE_LOCATION) ||
                granted(Manifest.permission.ACCESS_COARSE_LOCATION)
        }

        /** What makes the keep-alive worth running: geofence delivery while backgrounded. */
        fun hasBackgroundLocationPermission(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return true
            return ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED
        }

        fun start(context: Context) {
            // Never open a contract we cannot honour: without the grant,
            // startForeground() throws inside the service and the app is killed
            // for not reaching the foreground in time. Checking here means
            // startForegroundService() is simply never called.
            if (!hasLocationPermission(context)) {
                Log.w(TAG, "Skipping start: location permission not granted")
                return
            }
            val intent = Intent(context, GeofenceForegroundService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (t: Throwable) {
                // ForegroundServiceStartNotAllowedException (API 31+) when
                // started from the background. BOOT_COMPLETED and
                // MY_PACKAGE_REPLACED are exempt, but GeofencePlugin also calls
                // this from Dart, which is not. A keep-alive that fails to start
                // must never be fatal.
                Log.e(TAG, "start failed: $t")
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, GeofenceForegroundService::class.java))
        }
    }
}
