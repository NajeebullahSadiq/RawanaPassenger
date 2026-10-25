import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.rawana.passenger_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.rawana.passenger_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Flutter 3.44: GeneratedPluginRegistrant.java cannot resolve Kotlin plugin
// classes at javac time. Rewrite those constructors to reflection.
tasks.matching { it.name.startsWith("compile") && it.name.contains("Java") }.configureEach {
    doFirst {
        val registrant = file("${project.projectDir}/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
        if (!registrant.exists()) return@doFirst
        var contents = registrant.readText()
        val replacements = mapOf(
            "new dev.fluttercommunity.plus.packageinfo.PackageInfoPlugin()" to
                "(io.flutter.embedding.engine.plugins.FlutterPlugin) Class.forName(\"dev.fluttercommunity.plus.packageinfo.PackageInfoPlugin\").getDeclaredConstructor().newInstance()",
            "new dev.fluttercommunity.plus.share.SharePlusPlugin()" to
                "(io.flutter.embedding.engine.plugins.FlutterPlugin) Class.forName(\"dev.fluttercommunity.plus.share.SharePlusPlugin\").getDeclaredConstructor().newInstance()",
            "new dev.fluttercommunity.plus.device_info.DeviceInfoPlusPlugin()" to
                "(io.flutter.embedding.engine.plugins.FlutterPlugin) Class.forName(\"dev.fluttercommunity.plus.device_info.DeviceInfoPlusPlugin\").getDeclaredConstructor().newInstance()",
        )
        var changed = false
        for ((old, replacement) in replacements) {
            if (contents.contains(old)) {
                contents = contents.replace(old, replacement)
                changed = true
            }
        }
        if (changed) registrant.writeText(contents)
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
