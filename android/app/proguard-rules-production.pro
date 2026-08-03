# ============================================================================
# Production ProGuard/R8 Rules for WowCare Flutter App
# ============================================================================
# This file contains rules to protect critical app functionality while
# enabling aggressive optimization and obfuscation for security.
# ============================================================================

# ========== FLUTTER & DART RUNTIME ========================================
# Keep Flutter and Dart runtime classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep interface io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep Dart generated code
-keep class **.BuildConfig { *; }
-keep class **.R$* { *; }

# ========== FIREBASE & GOOGLE SERVICES ===================================
# Firebase Core
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.common.GoogleApiAvailability { *; }

# Keep Firebase annotations
-keepclasseswithmembernames class com.google.firebase.** { *; }
-keepclasseswithmembernames interface com.google.firebase.** { *; }

# Google Play Services
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.location.** { *; }

# Gson (used by Firebase)
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }

# ========== APP MODELS & ENTITIES ========================================
# Keep all model classes for serialization/deserialization
-keep class com.wiseowl.wowcareapp.models.** { *; }
-keep class com.wiseowl.wowcareapp.entities.** { *; }
-keep class com.wiseowl.wowcareapp.data.** { *; }
-keep class com.wiseowl.wowcareapp.domain.** { *; }

# Keep JSON serialization
-keepclassmembers class com.wiseowl.wowcareapp.models.** {
    <init>(...);
}

# ========== REFLECTION & NATIVE METHODS ==================================
# Keep native method names
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom application classes
-keep class com.wiseowl.wowcareapp.MainActivity { *; }
-keep class com.wiseowl.wowcareapp.Application { *; }

# Keep service classes
-keep class * extends android.app.Service { *; }
-keep class * extends android.content.BroadcastReceiver { *; }
-keep class * extends android.content.ContentProvider { *; }

# ========== ANDROID FRAMEWORK ============================================
# Android core
-keep class android.app.Activity { *; }
-keep class android.app.Service { *; }
-keep class android.content.Context { *; }
-keep class android.content.Intent { *; }
-keep class android.os.** { *; }
-keep class android.view.** { *; }
-keep class androidx.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keep interface androidx.annotation.** { *; }
-keep interface java.lang.annotation.** { *; }

# ========== THIRD-PARTY LIBRARIES =======================================
# Keep library classes that use reflection
-keep class com.google.gson.** { *; }
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Dio (HTTP client used in Flutter)
-keep class dio.** { *; }
-keep class io.flutter.plugins.** { *; }

# ffmpeg_kit
-keep class com.arthenica.ffmpegkit.** { *; }
-keep interface com.arthenica.ffmpegkit.** { *; }

# Isar (local database)
-keep class com.isar.** { *; }
-keep interface com.isar.** { *; }

# ========== REMOVE DEBUG CODE (SECURITY) =================================
# Remove logging statements in release build
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** isLoggable(...);
}

-assumenosideeffects class java.lang.String {
    public static *** format(...);
}

# Remove debug printStackTrace
-assumenosideeffects class java.lang.Throwable {
    public void printStackTrace(...);
}

# Remove assertions
-assumenosideeffects class * {
    void assert*(...);
}

# ========== OBFUSCATION CONFIGURATION ====================================
# Keep source file names for crash reporting (but obfuscate class names)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep stack trace information
-keepattributes Exception
-keepattributes InnerClasses

# Generic type information (for reflection)
-keepattributes Signature

# Annotation metadata
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations

# ========== PERFORMANCE OPTIMIZATIONS ====================================
# Enable aggressive inlining
-optimizationpasses 5

# Remove unused code
-repackageclasses 'com.wiseowl.wowcareapp.obf'

# ========== KOTLIN SUPPORT ==============================================
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keep class kotlin.reflect.** { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ========== SPECIFIC PLUGIN CONFIGURATIONS ==============================

# Mobile Scanner
-keep class dev.steenbakker.mobile_scanner.** { *; }

# Image Picker
-keep class com.example.imagepicker.** { *; }

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Local Auth
-keep class com.google.android.gms.internal.** { *; }

# QR Code
-keep class com.google.zxing.** { *; }
-keep class com.journeyapps.barcodescanner.** { *; }

# ========== EXCEPTIONS & WARNINGS =======================================
# Suppress warnings for unavoidable library issues
-dontwarn android.**
-dontwarn androidx.**
-dontwarn com.google.**
-dontwarn java.awt.**
-dontwarn java.lang.invoke.**
-dontwarn com.squareup.**
-dontwarn org.apache.**
-dontwarn retrofit2.**
-dontwarn okhttp3.**

# ========== PRODUCTION SECURITY RULES ====================================
# Prevent tampering detection bypass
-keep class com.wiseowl.wowcareapp.core.security.** { *; }
-keep class * implements com.wiseowl.wowcareapp.core.security.** { *; }

# Keep API endpoint definitions
-keep class com.wiseowl.wowcareapp.core.network.** { *; }

# Keep authentication logic
-keep class com.wiseowl.wowcareapp.presentation.features.auth.** { *; }

# ============================================================================
# NOTE: These rules balance between app functionality and security.
# Regular testing on physical devices is CRITICAL to ensure the release build
# works correctly with all features.
# ============================================================================
