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

        // Update persisted state to track last known geofence status
        val stateChanged = GeofencePrefs.shouldNotify(context, isInside)
        if (stateChanged) {
            GeofencePrefs.setLastInside(context, isInside)
        }

        // Always emit to Flutter event stream (will trigger notification from Flutter layer)
        GeofenceEventStreamHandler.emit(isInside)
    }

    companion object {
        const val ACTION_GEOFENCE_EVENT = "com.wowcare.geofencing.GEOFENCE_EVENT"
    }
}
