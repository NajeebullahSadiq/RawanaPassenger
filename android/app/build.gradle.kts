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

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

// Kept out of git: set MAPS_API_KEY in android/local.properties or the environment.
val mapsApiKey: String = localProperties.getProperty("MAPS_API_KEY") ?: System.getenv("MAPS_API_KEY") ?: ""

// CI smoke builds may opt into debug signing; real releases must use key.properties.
val allowDebugSigning = System.getenv("RAWANA_ALLOW_DEBUG_SIGNING") == "true"

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
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
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
            signingConfig = when {
                keystorePropertiesFile.exists() -> signingConfigs.getByName("release")
                allowDebugSigning -> signingConfigs.getByName("debug")
                else -> null
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

gradle.taskGraph.whenReady {
    val releasing = allTasks.any {
        (it.name.startsWith("assemble") || it.name.startsWith("bundle")) && it.name.endsWith("Release")
    }
    if (releasing && !keystorePropertiesFile.exists() && !allowDebugSigning) {
        throw GradleException(
            "android/key.properties is missing. Release builds must be signed with the upload key " +
                "(see key.properties.example), or set RAWANA_ALLOW_DEBUG_SIGNING=true for a local smoke build."
        )
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
    apply(plugin = "com.google.firebase.crashlytics")
}
