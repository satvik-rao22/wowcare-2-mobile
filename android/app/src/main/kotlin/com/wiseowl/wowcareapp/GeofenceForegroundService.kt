package com.wiseowl.wowcareapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

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
        // Defence in depth: [start] already refuses to launch us without the
        // permissions below, so reaching this branch means they were revoked
        // in the window between that check and now. stopSelf() rather than
        // stopSelfResult(startId), which is a no-op unless startId happens to
        // be the most recent start request.
        if (!canRun(this)) {
            android.util.Log.w("GeofenceService", "Location permission missing, stopping service")
            stopSelf()
            return START_NOT_STICKY
        }

        try {
            startForeground(NOTIFICATION_ID, buildNotification())
        } catch (e: Exception) {
            // Every reason the OS can refuse the promotion is terminal for
            // this service, and there is nothing the user can do about it
            // here: keeping the process alive is an optimisation, not a
            // feature. Rethrowing would take the whole app down over it.
            //
            //   SecurityException                        - FGS type `location`
            //                                              refused (missing or
            //                                              revoked runtime grant)
            //   ForegroundServiceStartNotAllowedException - started from the
            //                                              background on S+
            //
            // Either way we must stop, or the unpromoted service is killed
            // with ForegroundServiceDidNotStartInTimeException.
            val terminal = e is SecurityException ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    e is android.app.ForegroundServiceStartNotAllowedException)
            if (terminal) {
                android.util.Log.e(
                    "GeofenceService",
                    "startForeground refused (${e.javaClass.simpleName}): ${e.message}",
                )
                stopSelf()
                return START_NOT_STICKY
            }
            throw e
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
        const val NOTIFICATION_ID = 9001

        /**
         * Whether this service can legally hold a `location`-typed foreground
         * notification right now.
         *
         * Android requires FOREGROUND_SERVICE_LOCATION (a normal permission,
         * granted at install) *and* a runtime grant of fine or coarse
         * location. On Q+ the geofence feature additionally needs background
         * location, which is what the service has always enforced.
         *
         * [start] and [onStartCommand] must agree on this predicate. When
         * they disagree the process dies: startForegroundService() commits the
         * system to a 5-second deadline for startForeground(), and a service
         * that returns without promoting itself is killed with
         * ForegroundServiceDidNotStartInTimeException.
         */
        fun canRun(context: Context): Boolean {
            fun granted(permission: String): Boolean =
                androidx.core.content.ContextCompat.checkSelfPermission(context, permission) ==
                    android.content.pm.PackageManager.PERMISSION_GRANTED

            val hasForegroundLocation =
                granted(android.Manifest.permission.ACCESS_FINE_LOCATION) ||
                    granted(android.Manifest.permission.ACCESS_COARSE_LOCATION)
            if (!hasForegroundLocation) return false

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                !granted(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION)
            ) {
                return false
            }
            return true
        }

        fun start(context: Context) {
            // Do not even ask for a foreground service we are not allowed to
            // promote. This is the whole fix for the repeated
            // ForegroundServiceDidNotStartInTimeException crash: the previous
            // code called startForegroundService() unconditionally, and
            // onStartCommand then bailed out on the permission check without
            // ever calling startForeground().
            if (!canRun(context)) {
                android.util.Log.i(
                    "GeofenceService",
                    "Skipping foreground service start: location permission not granted",
                )
                return
            }

            val intent = Intent(context, GeofenceForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try {
                    context.startForegroundService(intent)
                } catch (e: Exception) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                        e is android.app.ForegroundServiceStartNotAllowedException
                    ) {
                        android.util.Log.e("GeofenceService", "ForegroundServiceStartNotAllowedException on start: ${e.message}")
                    } else {
                        throw e
                    }
                }
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, GeofenceForegroundService::class.java))
        }
    }
}
