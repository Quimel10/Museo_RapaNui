import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete
import org.gradle.api.tasks.compile.JavaCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

/**
 * ✅ FIX DEFINITIVO:
 * Algunas dependencias (ej: just_audio) inyectan "-Werror" tarde.
 * Entonces lo removemos JUSTO ANTES de compilar (doFirst), para todos los módulos.
 */
allprojects {
    tasks.withType(JavaCompile::class.java).configureEach {
        // A veces agregan -Werror después de la configuración, por eso lo quitamos en doFirst.
        doFirst {
            options.compilerArgs.removeAll(listOf("-Werror"))
        }

        // Opcional (no rompe nada)
        options.encoding = "UTF-8"
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
