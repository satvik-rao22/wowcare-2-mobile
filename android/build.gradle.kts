import com.android.build.gradle.LibraryExtension
import org.gradle.kotlin.dsl.configure

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
    if (name == "isar_flutter_libs") {
        plugins.withId("com.android.library") {
            extensions.configure<LibraryExtension>("android") {
                compileSdk = 36
            }
        }
    }

    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android") ?: return@withId
        val extensionClass = androidExt.javaClass

        // Ensure all Android library modules compile against a modern SDK.
        // Fixes AAPT errors like: `android:attr/lStar not found` when a plugin
        // is compiled with an older compileSdk than the app.
        run {
            val candidates = extensionClass.methods.filter {
                (it.name == "setCompileSdk" || it.name == "setCompileSdkVersion") &&
                    it.parameterTypes.size == 1
            }

            for (m in candidates) {
                val paramType = m.parameterTypes.firstOrNull() ?: continue
                try {
                    when (paramType) {
                        Int::class.javaPrimitiveType,
                        java.lang.Integer::class.java,
                        Number::class.java,
                        java.lang.Number::class.java -> m.invoke(androidExt, 36)
                        String::class.java -> m.invoke(androidExt, "android-36")
                        else -> continue
                    }
                    break
                } catch (_: Throwable) {
                    // Try next compatible setter candidate.
                }
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

    val patchIsarCompileSdk = tasks.register("patchIsarCompileSdkVersion") {
        doLast {
            val gradleFile = file("build.gradle")
            if (!gradleFile.exists()) return@doLast
            val original = gradleFile.readText()
            val patched = original.replace(
                Regex("""compileSdkVersion\s+\d+"""),
                "compileSdkVersion 36",
            )
            if (patched != original) {
                gradleFile.writeText(patched)
            }
        }
    }

    tasks.configureEach {
        if (name.contains("process", ignoreCase = true) &&
            name.contains("manifest", ignoreCase = true)
        ) {
            dependsOn(patchIsarManifest)
        }
        if (name.contains("merge", ignoreCase = true) &&
            name.contains("resources", ignoreCase = true)
        ) {
            dependsOn(patchIsarCompileSdk)
        }
        if (name.contains("verify", ignoreCase = true) &&
            name.contains("resources", ignoreCase = true)
        ) {
            dependsOn(patchIsarCompileSdk)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
