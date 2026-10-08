import com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension
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
    val encoded = ((project.findProperty("dart-defines") ?: project.findProperty("dart.defines")) as? String) ?: ""
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

// ---------------------------------------------------------------------------
// Crashlytics mapping-file upload
//
// `uploadCrashlyticsMappingFile<Variant>` gzips the R8 mapping file (~91 MB
// uncompressed here) and PUTs it to Firebase as one non-resumable fixed-length
// body — verified in firebase-crashlytics-buildtools 3.0.2: RestfulWebApi.sendFile
// builds a FileEntity on an HttpClients.createDefault() client, so it gets at
// most Apache's 3 transport-level attempts, with no socket timeout and no resume.
// When all three lose the connection the whole build fails with
// `java.net.SocketException: Broken pipe` — after the APK is built and signed.
//
// This cannot be repaired after the fact: when the upload is disabled the plugin
// also sets InjectMappingFileIdTask.useBlankMappingFileId, so the APK ships a
// BLANK com_crashlytics_android_build_id. Re-running the upload task later mints
// a new id that matches nothing in that APK. Symbols must be uploaded by the
// same build that produces the artifact you ship, or that artifact's Java/Kotlin
// crash reports stay obfuscated forever.
//
// So: upload for anything anyone else will run — prod, and every CI build — and
// skip it for throwaway local release builds, where it only adds a flaky
// multi-megabyte upload to each iteration. Override explicitly with:
//
//   flutter build apk --release --dart-define=ENVIRONMENT=UAT -Pcrashlytics.mappingUpload=true
//
// A `Broken pipe` here is usually NOT flaky wifi and re-running will not help:
// Java sorts IPv4 ahead of IPv6, and some NATs (an iPhone Personal Hotspot,
// 172.20.10.0/28) reset sustained IPv4 uploads after ~128-256 KB, failing every
// attempt at the same point. The root Makefile exports
// JAVA_TOOL_OPTIONS=-Djava.net.preferIPv6Addresses=true to route around it; if you
// invoke `flutter build` directly rather than through `make`, export it yourself.
// To confirm the network is the cause, PUT the cached gzip by hand -- curl picks
// IPv6 via Happy Eyeballs and succeeds where the JVM does not:
//
//   curl -X PUT --data-binary @build/app/crashlytics/release/.crashlytics-mappings-tmp/<id>.gz \
//     https://firebasecrashlyticssymbols.googleapis.com/v1/project/-/app/<appId>/upload/java/<id>
// ---------------------------------------------------------------------------
val crashlyticsMappingUploadEnabled: Boolean by lazy {
    val override = (project.findProperty("crashlytics.mappingUpload") as String?)?.takeIf { it.isNotBlank() }
    val isCi = !System.getenv("CI").isNullOrBlank()
    val enabled = override?.toBooleanStrictOrNull() ?: (dartEnvironment == "prod" || isCi)
    println("[crashlytics] mapping file upload=$enabled (env=$dartEnvironment, ci=$isCi)")
    enabled
}

// Copy the environment-specific google-services.json into the position the
// google-services plugin expects before it runs. Implemented as an ad-hoc
// `copy {}` action (not a `Copy` task with `into(projectDir)`) so the project
// directory is not registered as a tracked task output — otherwise Gradle 8.12
// reports implicit-dependency validation errors for every task that reads from
// android/app (mergeAssets, mergeShaders, compileFlutterBuild, ...).
val copyGoogleServices by tasks.registering {
    // Use the per-environment Firebase project when one exists, else fall back
    // to UAT. Environments that share a backend but have no Firebase project of
    // their own (DEV) then build without needing a config checked in; drop a
    // real firebase/<env>/google-services.json in and it is picked up
    // automatically.
    val firebaseConfigEnvironment =
        if (file("firebase/$dartEnvironment/google-services.json").exists()) {
            dartEnvironment
        } else {
            "uat"
        }
    println("[firebase] build env=$dartEnvironment → using firebase/$firebaseConfigEnvironment config")
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


    // Android App Link host, injected into AndroidManifest.xml as
    // ${appLinkHost}. The manifest previously hardcoded this and had no
    // debug/release split, so a local ngrok tunnel used for testing shipped to
    // release and broke autoVerify for every real deep link.
    //
    // Picked from the same `dartEnvironment` (decoded from
    // --dart-define=ENVIRONMENT=…) that already drives the Firebase config
    // selection above — PROD gets the production host, everything else
    // (UAT/local) gets the UAT host, matching ApiConstantsProd/ApiConstantsUat.
    //
    // Override locally WITHOUT editing a tracked file:
    //   flutter run --dart-define=… -PappLinkHost=your-tunnel.ngrok-free.dev
    // or add `appLinkHost=your-tunnel.ngrok-free.dev` to android/local.properties.
    val defaultAppLinkHost =
        if (dartEnvironment == "prod") "wowcare.childcarewow.app" else "wowcare-uat.childcarewow.app"
    val overriddenAppLinkHost =
        (project.findProperty("appLinkHost") as String?)?.takeIf { it.isNotBlank() }

    buildTypes {
        release {
            // Release ALWAYS uses the real host — a local override must never
            // reach a shipped build, which is the defect this replaces.
            manifestPlaceholders["appLinkHost"] = defaultAppLinkHost

            // ⚠️ Replace with your release keystore later
            signingConfig = signingConfigs.getByName("release")

            configure<CrashlyticsExtension> {
                mappingFileUploadEnabled = crashlyticsMappingUploadEnabled
            }
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

        debug {
            // Debug may point at a local tunnel via -PappLinkHost=…; defaults to
            // the same UAT host so a plain `flutter run` behaves like release.
            manifestPlaceholders["appLinkHost"] =
                overriddenAppLinkHost ?: defaultAppLinkHost
        }

        // Flutter's own build type behind `flutter run --profile` and
        // `flutter build apk --profile`. The Flutter plugin creates it as a
        // copy of debug when it is applied, which is before this block runs,
        // so it never received the placeholder and every profile build failed
        // in the manifest merger. Without it the app cannot be profiled.
        maybeCreate("profile").apply {
            manifestPlaceholders["appLinkHost"] =
                overriddenAppLinkHost ?: defaultAppLinkHost
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
