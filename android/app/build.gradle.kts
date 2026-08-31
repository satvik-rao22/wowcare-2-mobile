import java.util.Base64
import java.util.Properties


plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("com.google.firebase.crashlytics")
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
// Android Release Signing
// ---------------------------------------------------------------------------
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use {
        keystoreProperties.load(it)
    }
}

// ---------------------------------------------------------------------------
// Firebase multi-environment: decode --dart-define=ENVIRONMENT passed by Flutter.
// Flutter encodes each dart-define as a base64 string, comma-separated, in the
// "dart.defines" Gradle property. We decode and extract ENVIRONMENT, defaulting
// to "local" so a bare `./gradlew` still builds a valid variant.
// ---------------------------------------------------------------------------
val dartEnvironment: String by lazy {
    val encoded = (project.findProperty("dart.defines") as? String) ?: ""
    if (encoded.isBlank()) return@lazy "local"
    val decoded: List<String> = encoded.split(",")
        .filter { it.isNotBlank() }
        .mapNotNull { entry ->
            try {
                String(Base64.getDecoder().decode(entry.trim()))
            } catch (_: Exception) {
                null
            }
        }
    val env: String = decoded
        .firstOrNull { it.startsWith("ENVIRONMENT=") }
        ?.removePrefix("ENVIRONMENT=")
        ?: "local"
    env.lowercase()
}

// Copy the environment-specific google-services.json into the position the
// google-services plugin expects before it runs. Implemented as an ad-hoc
// `copy {}` action (not a `Copy` task with `into(projectDir)`) so the project
// directory is not registered as a tracked task output — otherwise Gradle 8.12
// reports implicit-dependency validation errors for every task that reads from
// android/app (mergeAssets, mergeShaders, compileFlutterBuild, ...).
val copyGoogleServices by tasks.registering {
    // Firebase is intentionally pinned to the UAT project (wowcare2-uat) for ALL
    // build environments. `dartEnvironment` still drives the rest of the build;
    // only the google-services.json is forced to the uat folder. To restore
    // per-environment Firebase projects, change this back to
    // "firebase/$dartEnvironment/google-services.json".
    val firebaseConfigEnvironment = "uat"
    println("[firebase] build env=$dartEnvironment → using firebase/$firebaseConfigEnvironment config (wowcare2-uat)")
    val srcPath = "firebase/$firebaseConfigEnvironment/google-services.json"
    doLast {
        val src = file(srcPath)
        require(src.exists()) {
            "Missing android/app/$srcPath\n" +
                "Download it from the Firebase console for the '$firebaseConfigEnvironment' project and place it there."
        }
        copy {
            from(src)
            into(layout.projectDirectory)
            rename { "google-services.json" }
        }
    }
}

afterEvaluate {
    // Ensure the file is in place before anything builds, and before the
    // google-services plugin's own processing task runs.
    tasks.named("preBuild").configure { dependsOn(copyGoogleServices) }
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

     // -----------------------------------------------------------------------
    // Release Signing
    // -----------------------------------------------------------------------
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")

                val keystorePath =
                    keystoreProperties.getProperty("storeFile")

                if (!keystorePath.isNullOrBlank()) {
                    storeFile = file(keystorePath)
                }
            }
        }
    }


    buildTypes {
        release {
            // ⚠️ Replace with your release keystore later
            signingConfig = signingConfigs.getByName("release")
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
