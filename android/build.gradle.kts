allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// AGP 8+ requires `android.namespace` on every Android module.
// Some older third-party plugins (e.g. isar_flutter_libs 3.1.0+1) still omit it.
subprojects {
    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android") ?: return@withId
        val extensionClass = androidExt.javaClass

        // Ensure all Android library modules compile against a modern SDK.
        // Fixes AAPT errors like: `android:attr/lStar not found` when a plugin
        // is compiled with an older compileSdk than the app.
        run {
            val setCompileSdk =
                extensionClass.methods.firstOrNull { it.name == "setCompileSdk" && it.parameterTypes.size == 1 }
            val setCompileSdkVersion =
                extensionClass.methods.firstOrNull {
                    it.name == "setCompileSdkVersion" && it.parameterTypes.size == 1
                }
            // Prefer `setCompileSdk(Int)` on AGP 8+, fallback to older API.
            when {
                setCompileSdk != null -> setCompileSdk.invoke(androidExt, 36)
                setCompileSdkVersion != null -> setCompileSdkVersion.invoke(androidExt, 36)
                else -> {}
            }
        }

        val getNamespace = extensionClass.methods.firstOrNull { it.name == "getNamespace" }
        val setNamespace = extensionClass.methods.firstOrNull {
            it.name == "setNamespace" && it.parameterTypes.size == 1
        }
        if (getNamespace == null || setNamespace == null) return@withId

        val current = getNamespace.invoke(androidExt) as? String
        if (current.isNullOrBlank()) {
            val fallbackNamespace =
                "autogen.${project.name.replace('-', '_').replace('.', '_')}"
            setNamespace.invoke(androidExt, fallbackNamespace)
        }
    }
}

// AGP 8.9 also rejects `package="..."` in source AndroidManifest for libraries.
// Patch known outdated dependency manifest (isar_flutter_libs 3.1.0+1) before
// manifest processing, so local builds succeed without editing pub cache manually.
subprojects {
    if (name != "isar_flutter_libs") return@subprojects

    val patchIsarManifest = tasks.register("patchIsarManifestPackageAttribute") {
        doLast {
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (!manifestFile.exists()) return@doLast
            val original = manifestFile.readText()
            val patched =
                original.replace(Regex("""\s+package="[^"]*"""", RegexOption.IGNORE_CASE), "")
            if (patched != original) {
                manifestFile.writeText(patched)
            }
        }
    }

    tasks.configureEach {
        if (name.contains("process", ignoreCase = true) &&
            name.contains("manifest", ignoreCase = true)
        ) {
            dependsOn(patchIsarManifest)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
