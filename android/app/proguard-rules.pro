# Keep Flutter plugin implementations in release builds.
# Some AGP/R8 combinations can still strip plugin glue classes,
# which causes PlatformException(channel-error, ...) at runtime.
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep shared_preferences Android plugin + generated Pigeon bindings.
# The legacy Messages$SharedPreferencesApi interface hosts the
# `dev.flutter.pigeon.shared_preferences_android.SharedPreferencesApi.getAll`
# channel — if R8 strips it, SharedPreferences.getInstance() throws
# PlatformException(channel-error) at app start.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep interface io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }

# Pigeon-generated message codecs/handlers across plugins.
-keep class **.Messages$* { *; }
-keepclassmembers class **.Messages { *; }
