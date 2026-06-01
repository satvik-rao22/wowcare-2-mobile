package com.wiseowl.wowcareapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.google.android.gms.location.LocationServices

class GeofenceBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (
            action != Intent.ACTION_BOOT_COMPLETED &&
                action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }

        val config = GeofencePrefs.readConfig(context) ?: return
        if (!config.gpsSignInEnabled) return

        // Re-register geofence after reboot / app update.
        val client = LocationServices.getGeofencingClient(context)
        val pending = run {
            val i =
                Intent(context, GeofenceBroadcastReceiver::class.java).apply {
                    this.action = GeofenceBroadcastReceiver.ACTION_GEOFENCE_EVENT
                }
            // GeofencingClient.addGeofences() requires FLAG_MUTABLE to add geofence transition data
            val flags = android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_MUTABLE
            android.app.PendingIntent.getBroadcast(context, 0, i, flags)
        }

        // Best-effort: will fail silently without location permissions.
        try {
            val pluginRegistrar =
                javaClass.classLoader // no-op: just to avoid unused warnings
            GeofenceRegistrarBoot.register(context, client, config, pending)
        } catch (_: Throwable) {}
    }
}

private object GeofenceRegistrarBoot {
    fun register(
        context: Context,
        client: com.google.android.gms.location.GeofencingClient,
        config: GeofencePrefs.Config,
        pendingIntent: android.app.PendingIntent,
    ) {
        // Use the same helper implementation as plugin (duplicated small bit to keep files independent).
        val geofence =
            com.google.android.gms.location.Geofence.Builder()
                .setRequestId("wowcare_geofence_${config.schoolCode}")
                .setCircularRegion(
                    config.latitude,
                    config.longitude,
                    config.radiusMeters.toFloat(),
                )
                .setTransitionTypes(
                    com.google.android.gms.location.Geofence.GEOFENCE_TRANSITION_ENTER or
                        com.google.android.gms.location.Geofence.GEOFENCE_TRANSITION_EXIT,
                )
                .setExpirationDuration(com.google.android.gms.location.Geofence.NEVER_EXPIRE)
                .setNotificationResponsiveness(5_000)
                .build()

        val request =
            com.google.android.gms.location.GeofencingRequest.Builder()
                .setInitialTrigger(
                    com.google.android.gms.location.GeofencingRequest.INITIAL_TRIGGER_ENTER or
                        com.google.android.gms.location.GeofencingRequest.INITIAL_TRIGGER_EXIT,
                )
                .addGeofence(geofence)
                .build()

        client.addGeofences(request, pendingIntent)
    }
}

