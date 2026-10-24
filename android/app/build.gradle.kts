import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// The versionCode/versionName are parsed straight from pubspec.yaml instead of relying on
// `flutter.versionCode` / `flutter.versionName`. Those fall back to 1 / "1.0" whenever the
// pubspec version has no "+buildNumber" suffix, which produces an AAB with versionCode 1 that
// Play Store rejects with "Version code 1 has already been used".
val pubspecVersion = rootProject.file("../pubspec.yaml")
    .readLines()
    .firstOrNull { it.trimStart().startsWith("version:") }
    ?.substringAfter("version:")
    ?.trim()
    .orEmpty()

val appVersionName = pubspecVersion.substringBefore("+")
val appVersionCode = pubspecVersion.substringAfter("+", "")
    .takeIf { it.isNotEmpty() }
    ?.toIntOrNull()

require(appVersionCode != null) {
    "pubspec.yaml has `version: $pubspecVersion`, which has no build number. " +
        "Flutter then silently builds with versionCode 1. " +
        "Use `version: ${appVersionName.ifEmpty { "1.0.0" }}+<buildNumber>` " +
        "(e.g. `version: ${appVersionName.ifEmpty { "1.0.0" }}+100`) and make the build number " +
        "higher than every versionCode already published on Play Console."
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pugazh.pebble"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pugazh.pebble"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = appVersionCode
        versionName = appVersionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}