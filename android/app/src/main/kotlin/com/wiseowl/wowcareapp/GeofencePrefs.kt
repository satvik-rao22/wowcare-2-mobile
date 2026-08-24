package com.wiseowl.wowcareapp

import android.content.Context

object GeofencePrefs {
    private const val PREFS = "wowcare_geofence_prefs"

    private const val KEY_LAT = "geofence_school_lat"
    private const val KEY_LON = "geofence_school_lon"
    private const val KEY_RADIUS = "geofence_school_radius_m"
    private const val KEY_GPS_ENABLED = "geofence_gps_sign_in_enabled"
    private const val KEY_LAST_INSIDE = "geofence_last_notified_inside"
    private const val KEY_LAST_STATUS = "geofence_last_status"
    private const val KEY_SCHOOL_CODE = "geofence_school_code"
    private const val KEY_NOTHING_TO_DO = "geofence_nothing_to_do"
    private const val KEY_NOTHING_TO_DO_TIMESTAMP = "geofence_nothing_to_do_timestamp"

    fun persistConfig(
        context: Context,
        schoolCode: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        gpsSignInEnabled: Boolean,
    ) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_SCHOOL_CODE, schoolCode)
            .putFloat(KEY_LAT, latitude.toFloat())
            .putFloat(KEY_LON, longitude.toFloat())
            .putFloat(KEY_RADIUS, radiusMeters.toFloat())
            .putBoolean(KEY_GPS_ENABLED, gpsSignInEnabled)
            .apply()
    }

    fun persistSchoolCode(context: Context, schoolCode: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY_SCHOOL_CODE, schoolCode)
            .apply()
    }

    fun readConfig(context: Context): Config? {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val lat = prefs.getFloat(KEY_LAT, 0f).toDouble()
        val lon = prefs.getFloat(KEY_LON, 0f).toDouble()
        val radius = prefs.getFloat(KEY_RADIUS, 0f).toDouble()
        val gps = prefs.getBoolean(KEY_GPS_ENABLED, true)
        val schoolCode = prefs.getString(KEY_SCHOOL_CODE, "") ?: ""
        if (lat == 0.0 || lon == 0.0 || radius <= 0.0) return null
        return Config(
            schoolCode = schoolCode,
            latitude = lat,
            longitude = lon,
            radiusMeters = radius,
            gpsSignInEnabled = gps,
        )
    }

    fun shouldNotify(context: Context, isInside: Boolean): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val lastInside = prefs.getBoolean(KEY_LAST_INSIDE, false)
        return lastInside != isInside
    }

    fun setLastInside(context: Context, isInside: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_LAST_INSIDE, isInside)
            .putString(KEY_LAST_STATUS, if (isInside) "within" else "outside")
            .apply()
    }

    fun getLastInside(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_LAST_INSIDE, false)
    }

    fun clearLastInside(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .remove(KEY_LAST_INSIDE)
            .remove(KEY_LAST_STATUS)
            .apply()
    }

    /// Set by Flutter (GeofenceCubit) whenever staff/admin/guardian sign-in
    /// status changes, so the background/killed-app notification path — which
    /// has no other visibility into sign-in state — can skip notifying when
    /// there is nothing left to sign in/out.
    fun setNothingToDo(context: Context, nothingToDo: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_NOTHING_TO_DO, nothingToDo)
            .putLong(KEY_NOTHING_TO_DO_TIMESTAMP, System.currentTimeMillis())
            .apply()
    }

    fun getNothingToDo(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val nothingToDo = prefs.getBoolean(KEY_NOTHING_TO_DO, false)
        if (!nothingToDo) return false

        // If it was set to true, verify it was set today. A stale true value
        // from a previous day (e.g. app killed after sign-out failed to sync)
        // must not permanently suppress notifications.
        val timestamp = prefs.getLong(KEY_NOTHING_TO_DO_TIMESTAMP, 0)
        val calSet = java.util.Calendar.getInstance().apply { timeInMillis = timestamp }
        val calNow = java.util.Calendar.getInstance()
        
        val isSameDay = calSet.get(java.util.Calendar.YEAR) == calNow.get(java.util.Calendar.YEAR) &&
                        calSet.get(java.util.Calendar.DAY_OF_YEAR) == calNow.get(java.util.Calendar.DAY_OF_YEAR)
                        
        if (!isSameDay) {
            return false // Expired, assume we need to notify
        }
        return true
    }

    data class Config(
        val schoolCode: String,
        val latitude: Double,
        val longitude: Double,
        val radiusMeters: Double,
        val gpsSignInEnabled: Boolean,
    )
}

