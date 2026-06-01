package com.wiseowl.wowcareapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_GEOFENCE_EVENT) return

        val event = GeofencingEvent.fromIntent(intent) ?: return
        if (event.hasError()) {
            val statusMessage = GeofenceStatusCodes.getStatusCodeString(event.errorCode)
            return
        }

        val transition = event.geofenceTransition
        val isInside = when (transition) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> true
            Geofence.GEOFENCE_TRANSITION_EXIT -> false
            else -> return
        }

        // Persist new state (de-dupe so we only act when status actually changes).
        val stateChanged = GeofencePrefs.shouldNotify(context, isInside)
        if (stateChanged) {
            GeofencePrefs.setLastInside(context, isInside)
        }

        // Show the notification from native layer every time.
        // This is the ONLY path that works when the app is backgrounded or killed
        // because the Flutter EventChannel sink is null in those cases.
        // When the app IS foreground Flutter will also call showEnteredZoneNotification()
        // via the EventChannel, which replaces this one (same notification ID) — no duplicate.
        GeofenceNotifications.ensureChannel(context)
        GeofenceNotifications.show(context, isInside)

        // Relay to Flutter so the cubit updates its state and button immediately.
        GeofenceEventStreamHandler.emit(isInside)
    }

    companion object {
        const val ACTION_GEOFENCE_EVENT = "com.wowcare.geofencing.GEOFENCE_EVENT"
    }
}
