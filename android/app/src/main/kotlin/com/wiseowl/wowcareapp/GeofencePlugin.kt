package com.wiseowl.wowcareapp

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class GeofencePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var appContext: Context
    private var channel: MethodChannel? = null
    private var events: EventChannel? = null
    private var geofencingClient: GeofencingClient? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        geofencingClient = LocationServices.getGeofencingClient(appContext)

        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
        events = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME).also {
            it.setStreamHandler(GeofenceEventStreamHandler)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        events?.setStreamHandler(null)
        events = null
        geofencingClient = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "updateSchoolLocation" -> handleUpdateSchoolLocation(call, result)
            "getGeofenceStatus" -> handleGetGeofenceStatus(result)
            else -> result.notImplemented()
        }
    }

    private fun handleGetGeofenceStatus(result: MethodChannel.Result) {
        val config = GeofencePrefs.readConfig(appContext)
        val isInside = GeofencePrefs.getLastInside(appContext)
        result.success(mapOf(
            "isInside" to isInside,
            "schoolCode" to (config?.schoolCode ?: ""),
            "latitude" to (config?.latitude ?: 0.0),
            "longitude" to (config?.longitude ?: 0.0),
            "radiusMeters" to (config?.radiusMeters ?: 0.0),
            "gpsSignInEnabled" to (config?.gpsSignInEnabled ?: false),
        ))
    }

    private fun handleUpdateSchoolLocation(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            result.error("bad_args", "Missing args", null)
            return
        }
        val latitude = (args["latitude"] as? Number)?.toDouble() ?: 0.0
        val longitude = (args["longitude"] as? Number)?.toDouble() ?: 0.0
        val radiusMeters = (args["radiusMeters"] as? Number)?.toDouble() ?: 250.0
        val schoolCode = (args["schoolCode"] as? String) ?: "school"
        val gpsEnabled = (args["gpsSignInEnabled"] as? Boolean) ?: true

        if (latitude == 0.0 || longitude == 0.0 || radiusMeters <= 0.0) {
            result.error("bad_location", "Invalid school coordinates", null)
            return
        }

        GeofencePrefs.persistConfig(
            context = appContext,
            schoolCode = schoolCode,
            latitude = latitude,
            longitude = longitude,
            radiusMeters = radiusMeters,
            gpsSignInEnabled = gpsEnabled,
        )

        if (!gpsEnabled) {
            GeofenceRegistrar.clear(appContext)
            GeofenceForegroundService.stop(appContext)
            result.success(true)
            return
        }

        // The foreground service exists solely to keep the process alive for
        // background/terminated geofence delivery — only start it when the user
        // has actually granted background location ("Allow All the Time"). For
        // "While Using the App" only, GeofencingClient registration below still
        // proceeds (delivers events while foregrounded/recently backgrounded),
        // but the persistent keep-alive service and its notification stay off.
        if (hasBackgroundLocationPermission()) {
            GeofenceForegroundService.start(appContext)
        } else {
            GeofenceForegroundService.stop(appContext)
        }

        GeofenceRegistrar.register(
            context = appContext,
            client = geofencingClient ?: LocationServices.getGeofencingClient(appContext),
            schoolCode = schoolCode,
            latitude = latitude,
            longitude = longitude,
            radiusMeters = radiusMeters,
            pendingIntent = geofencePendingIntent(appContext),
            onSuccess = { result.success(true) },
            onError = { code, message -> result.error(code, message, null) },
        )
    }

    /**
     * True only when the user granted "Allow All the Time" (background
     * location). Pre-Android 10 has no separate background permission —
     * foreground grant implies background access, so checkSelfPermission
     * against the declared ACCESS_BACKGROUND_LOCATION already returns
     * granted there without any extra branching.
     */
    private fun hasBackgroundLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            appContext,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun geofencePendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java).apply {
            action = GeofenceBroadcastReceiver.ACTION_GEOFENCE_EVENT
        }
        // GeofencingClient.addGeofences() requires FLAG_MUTABLE to add geofence transition data
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        return PendingIntent.getBroadcast(context, 0, intent, flags)
    }

    companion object {
        const val CHANNEL_NAME = "com.wowcare.geofencing/native"
        const val EVENT_CHANNEL_NAME = "com.wowcare.geofencing/events"
    }
}

object GeofenceEventStreamHandler : EventChannel.StreamHandler {
    @Volatile private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    fun emit(isInside: Boolean) {
        sink?.success(mapOf("isInside" to isInside))
    }
}

private object GeofenceRegistrar {
    private const val REQUEST_ID_PREFIX = "wowcare_geofence_"

    fun register(
        context: Context,
        client: GeofencingClient,
        schoolCode: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        pendingIntent: PendingIntent,
        onSuccess: () -> Unit,
        onError: (String, String) -> Unit,
    ) {
        // Replace previous geofences registered under our PendingIntent.
        client.removeGeofences(pendingIntent)
            .addOnCompleteListener {
                val geofence = Geofence.Builder()
                    .setRequestId("$REQUEST_ID_PREFIX$schoolCode")
                    .setCircularRegion(latitude, longitude, radiusMeters.toFloat())
                    .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
                    .setExpirationDuration(Geofence.NEVER_EXPIRE)
                    .setNotificationResponsiveness(5_000) // ~near-real-time without high battery drain
                    .build()

                val request = GeofencingRequest.Builder()
                    .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER or GeofencingRequest.INITIAL_TRIGGER_EXIT)
                    .addGeofence(geofence)
                    .build()

                try {
                    client.addGeofences(request, pendingIntent)
                        .addOnSuccessListener { onSuccess() }
                        .addOnFailureListener { e ->
                            onError("geofence_register_failed", e.message ?: "Failed to register geofence")
                        }
                } catch (se: SecurityException) {
                    onError("permission_denied", "Missing location permission: ${se.message ?: "SecurityException"}")
                }
            }
    }

    fun clear(context: Context) {
        val client = LocationServices.getGeofencingClient(context)
        try {
            client.removeGeofences(geofencePendingIntent(context))
        } catch (_: Throwable) {}
    }

    private fun geofencePendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java).apply {
            action = GeofenceBroadcastReceiver.ACTION_GEOFENCE_EVENT
        }
        // GeofencingClient.addGeofences() requires FLAG_MUTABLE to add geofence transition data
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        return PendingIntent.getBroadcast(context, 0, intent, flags)
    }
}

