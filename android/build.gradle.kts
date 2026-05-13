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

// isar_flutter_libs 3.1.0+1 still ships compileSdkVersion 30 after its android {} block.
// Transitive AndroidX can reference android:attr/lStar (API 31+). Plugin callbacks that
// run at apply-plugin time run *before* that block and get overwritten — bump here.
// `evaluationDependsOn(":app")` above can leave some subprojects already evaluated, so
// registering afterEvaluate on them throws; run the same logic immediately in that case.
subprojects {
    fun Project.bumpAndroidLibraryCompileSdkAndNamespace() {
        if (!plugins.hasPlugin("com.android.library")) return
        extensions.configure<LibraryExtension>("android") {
            compileSdk = 36
            if (namespace.isNullOrBlank()) {
                namespace =
                    "autogen.${name.replace('-', '_').replace('.', '_')}"
            }
        }
    }
    if (state.executed) {
        bumpAndroidLibraryCompileSdkAndNamespace()
    } else {
        afterEvaluate { bumpAndroidLibraryCompileSdkAndNamespace() }
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
