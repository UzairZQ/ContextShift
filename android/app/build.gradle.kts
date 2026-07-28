import java.util.Properties
import java.io.FileInputStream
import java.io.File
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    // Apply the Flutter Gradle Plugin after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
}


val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val hasReleaseSigning = listOf(
    "keyAlias",
    "keyPassword",
    "storeFile",
    "storePassword",
).all { key -> !keystoreProperties.getProperty(key).isNullOrBlank() }
val releaseStoreFile = keystoreProperties.getProperty("storeFile")?.let { path ->
    val configuredFile = File(path)
    if (configuredFile.isAbsolute) configuredFile else rootProject.file(path)
}
val hasUsableReleaseSigning = hasReleaseSigning && releaseStoreFile?.isFile == true

if (keystorePropertiesFile.exists() && !hasUsableReleaseSigning) {
    throw GradleException(
        "android/key.properties is incomplete or its storeFile does not exist. " +
            "Fix the local signing configuration before building a release."
    )
}


android {
    namespace = "com.uzairzq.contextshift"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        if (hasUsableReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = releaseStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.uzairzq.contextshift"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters += listOf("arm64-v8a")
        }
    }

    buildTypes {
        release {
            // Never publish a release signed with the debug key. Configure
            // android/key.properties before building an uploadable artifact.
            signingConfig = if (hasUsableReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                null
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
