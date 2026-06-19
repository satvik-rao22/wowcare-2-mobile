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

// ---------------------------------------------------------------------------
// Firebase multi-environment: decode --dart-define=ENVIRONMENT passed by Flutter.
// Flutter encodes each dart-define as a base64 string, comma-separated, in the
// "dart.defines" Gradle property. We decode and extract ENVIRONMENT, defaulting
// to "uat" so a bare `./gradlew` still builds a valid variant.
// ---------------------------------------------------------------------------
val dartEnvironment: String by lazy {
    val encoded = (project.findProperty("dart.defines") as? String) ?: ""
    if (encoded.isBlank()) return@lazy "uat"
    val env = encoded.split(",")
        .filter { it.isNotBlank() }
        .mapNotNull { entry ->
            try {
                String(java.util.Base64.getDecoder().decode(entry.trim()))
            } catch (_: Exception) {
                null
            }
        }
        .firstOrNull { it.startsWith("ENVIRONMENT=") }
        ?.removePrefix("ENVIRONMENT=")
        ?: "uat"
    env.lowercase()
}

// Copy the environment-specific google-services.json into the position the
// google-services plugin expects before it runs.
val copyGoogleServices by tasks.registering(Copy::class) {
    val src = file("firebase/$dartEnvironment/google-services.json")
    val dst = file("google-services.json")
    doFirst {
        require(src.exists()) {
            "Missing android/app/firebase/$dartEnvironment/google-services.json\n" +
                "Download it from the Firebase console for the '$dartEnvironment' project and place it there."
        }
    }
    from(src)
    into(dst.parentFile)
    rename { dst.name }
}

afterEvaluate {
    // Wire copyGoogleServices before any task whose name matches the google-services pattern.
    tasks.matching { t ->
        t.name.startsWith("process") && t.name.endsWith("GoogleServices")
    }.configureEach {
        dependsOn(copyGoogleServices)
    }
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

        // Commented out for split APK builds
        // When building split APKs with --split-per-abi, this conflicts with splits
        // Uncomment if building a single monolithic APK
        // ndk {
        //     abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        // }
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.gms:play-services-location:21.3.0")
    // Provides Theme.MaterialComponents.* used by LaunchTheme/NormalTheme — the
    // AppCompat host theme local_auth's BiometricPrompt requires.
    implementation("com.google.android.material:material:1.12.0")
}
