import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val configuredKeyPropertiesPath =
    System.getenv("RECHENBLITZ_KEY_PROPERTIES")
val keystorePropertiesFile = configuredKeyPropertiesPath
    ?.takeIf { it.isNotBlank() }
    ?.let { rootProject.file(it) }
    ?: rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use {
        keystoreProperties.load(it)
    }
}

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "de.mdkks.rechenblitz"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        resValues = true
    }

    defaultConfig {
        applicationId = "de.mdkks.rechenblitz"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "subject"
    productFlavors {
        create("rechenblitz") {
            dimension = "subject"
            applicationId = "de.mdkks.rechenblitz"
            resValue("string", "app_name", "Rechenblitz")
        }
        create("wortblitz") {
            dimension = "subject"
            applicationId = "de.mdkks.wortblitz"
            resValue("string", "app_name", "Wortblitz")
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(
                    keystoreProperties.getProperty("storeFile"),
                )
                storePassword =
                    keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        getByName("release") {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

val generatedPluginRegistrant =
    file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")

tasks.matching { it.name == "preBuild" }.configureEach {
    doFirst {
        if (!generatedPluginRegistrant.exists()) {
            throw GradleException(
                "Flutter plugin registration is missing. Run `flutter pub get` " +
                    "and build through `flutter build`, not raw Gradle.",
            )
        }
    }
}

tasks.matching {
    it.name.startsWith("pre") && it.name.endsWith("ReleaseBuild")
}.configureEach {
    doFirst {
        if (!keystorePropertiesFile.exists()) {
            throw GradleException(
                "Release signing is required. Provide android/key.properties " +
                    "or RECHENBLITZ_KEY_PROPERTIES.",
            )
        }
    }
}

flutter {
    source = "../.."
}
