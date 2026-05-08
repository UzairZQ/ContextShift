allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Restore original logic but using safe property-based setters for Gradle 8.x
rootProject.layout.buildDirectory.set(
    rootProject.layout.buildDirectory.dir("../../build")
)

subprojects {
    project.layout.buildDirectory.set(
        rootProject.layout.buildDirectory.dir(project.name)
    )
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
