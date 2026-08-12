package com.wiseowl.wowcareapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_GEOFENCE_EVENT) return

        // Wrap everything so a crash never silently swallows the event.
        // Without this, an exception before setLastInside() means the state
        // is never persisted and Flutter never learns about the transition.
        try {
            val config = GeofencePrefs.readConfig(context)
            if (config == null || !config.gpsSignInEnabled) return

            val event = GeofencingEvent.fromIntent(intent) ?: return
            if (event.hasError()) {
                Log.e("GeofenceBroadcastReceiver",
                    "Geofence error: ${GeofenceStatusCodes.getStatusCodeString(event.errorCode)} (${event.errorCode})")
                return
            }

            val isInside = when (event.geofenceTransition) {
                Geofence.GEOFENCE_TRANSITION_ENTER -> true
                Geofence.GEOFENCE_TRANSITION_EXIT -> false
                else -> return
            }

            // Persist state and show notification ONLY when the status actually
            // changes. The OS can fire repeated ENTER events (e.g. INITIAL_TRIGGER
            // on every geofence re-registration), and showing a notification every
            // time causes system throttling that drops the important first one.
            val stateChanged = GeofencePrefs.shouldNotify(context, isInside)
            if (stateChanged) {
                GeofencePrefs.setLastInside(context, isInside)
                // "You can now Sign In or Sign Out" is meaningless when staff/admin
                // is already signed in or a guardian's children are all already
                // signed in — Flutter pushes this flag whenever sign-in status
                // changes so the background/killed-app path (which has no other
                // visibility into sign-in status) can also skip it.
                val nothingToDo = GeofencePrefs.getNothingToDo(context)
                if (isInside && nothingToDo) {
                    Log.d("GeofenceBroadcastReceiver", "Skipping enter notification — nothing to sign in/out")
                } else {
                    // Native notification — the SOLE notification authority.
                    // This perfectly handles background, terminated, and foreground states.
                    GeofenceNotifications.ensureChannel(context)
                    GeofenceNotifications.show(context, isInside)
                }
            }

            // Always relay to Flutter so the cubit updates button state immediately.
            GeofenceEventStreamHandler.emit(isInside)
        } catch (_: Exception) {
            // Silently absorb — a crashed receiver prevents state from being saved
            // and blocks the Flutter event, which is worse than ignoring the error.
        }
    }

    companion object {
        const val ACTION_GEOFENCE_EVENT = "com.wowcare.geofencing.GEOFENCE_EVENT"
    }
}
