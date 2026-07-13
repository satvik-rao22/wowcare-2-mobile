package com.wiseowl.wowcareapp.security

import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Handles security-related method channel calls from Flutter.
 * This includes screenshot prevention on sensitive screens.
 */
class SecurityMethodChannel {
    companion object {
        private const val CHANNEL_NAME = "com.wiseowl.wowcareapp/security"
    }

    /**
     * Initializes the method channel with the Flutter engine.
     * Call this from MainActivity.configureFlutterEngine()
     */
    fun setupMethodChannel(
        flutterEngine: FlutterEngine,
        onScreenshotPreventRequested: () -> Unit,
        onScreenshotAllowRequested: () -> Unit,
        onCheckScreenshotStatus: () -> Boolean
    ) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "preventScreenshots" -> {
                        try {
                            onScreenshotPreventRequested()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SCREENSHOT_ERROR", e.message, null)
                        }
                    }

                    "allowScreenshots" -> {
                        try {
                            onScreenshotAllowRequested()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SCREENSHOT_ERROR", e.message, null)
                        }
                    }

                    "isScreenshotPrevented" -> {
                        try {
                            val isPrevented = onCheckScreenshotStatus()
                            result.success(isPrevented)
                        } catch (e: Exception) {
                            result.error("SCREENSHOT_ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Apply FLAG_SECURE to prevent screenshots and screen recording
     */
    fun preventScreenshots(window: android.view.Window) {
        try {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        } catch (e: Exception) {
            // Log error but don't crash
        }
    }

    /**
     * Remove FLAG_SECURE to allow screenshots again
     */
    fun allowScreenshots(window: android.view.Window) {
        try {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } catch (e: Exception) {
            // Log error but don't crash
        }
    }

    /**
     * Check if FLAG_SECURE is currently set
     */
    fun isScreenshotPrevented(window: android.view.Window): Boolean {
        return try {
            (window.attributes.flags and WindowManager.LayoutParams.FLAG_SECURE) != 0
        } catch (e: Exception) {
            false
        }
    }
}
