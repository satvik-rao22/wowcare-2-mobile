import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Flutter's default shrinker rules (keeps classes that implement FlutterPlugin). If release
// `proguardFiles` is overridden with only the Android default + app file, those rules are
// dropped and R8 can strip plugin / Pigeon code — runtime errors like
// PlatformException(channel-error, ... SharedPreferencesApi.getAll).
val flutterProguardRules: java.io.File =
    run {
        val props = Properties()
        val local = rootProject.file("local.properties")
        check(local.exists()) { "local.properties not found" }
        local.inputStream().use { props.load(it) }
        val sdk = props.getProperty("flutter.sdk") ?: error("flutter.sdk not set in local.properties")
        rootProject.file("$sdk/packages/flutter_tools/gradle/flutter_proguard_rules.pro")
    }

android {
    namespace = "com.wiseowl.wowcareapp"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.wiseowl.wowcareapp"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ IMPORTANT: Reduce native size
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    buildTypes {
        release {
            // ⚠️ Replace with your release keystore later
            signingConfig = signingConfigs.getByName("debug")

            // ✅ Enable shrinking
            isMinifyEnabled = true
            isShrinkResources = true

            val appProguard = layout.projectDirectory.file("proguard-rules.pro").asFile
            if (appProguard.exists()) {
                proguardFiles(
                    getDefaultProguardFile("proguard-android-optimize.txt"),
                    flutterProguardRules,
                    appProguard,
                )
            } else {
                proguardFiles(
                    getDefaultProguardFile("proguard-android-optimize.txt"),
                    flutterProguardRules,
                )
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Kotlin DSL requires parentheses
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
