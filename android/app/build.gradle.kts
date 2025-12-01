plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties if present. Keep key.properties out of version control.
import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.docucapper.docucapper"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Unique Application ID for Play Store
        applicationId = "com.docucapper.docucapper"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val alias = keystoreProperties.getProperty("keyAlias")
                val keyPwd = keystoreProperties.getProperty("keyPassword")
                val storeFileProp = keystoreProperties.getProperty("storeFile")
                val storePwd = keystoreProperties.getProperty("storePassword")

                if (alias != null) keyAlias = alias
                if (keyPwd != null) keyPassword = keyPwd
                if (storeFileProp != null) storeFile = file(storeFileProp)
                if (storePwd != null) storePassword = storePwd
            }
        }
    }

    buildTypes {
        release {
            // Use the release signing config if key.properties was provided,
            // otherwise fall back to the debug signing config so local runs still work.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")

            // Disable code shrinking/minification for now to avoid R8 errors
            // related to ML Kit optional language modules. You can re-enable
            // minification once ProGuard/R8 rules are adjusted.
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}
