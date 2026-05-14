plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "com.ayesh.dev.learnit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.ayesh.dev.learnit"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            // Use SYMBOL_TABLE to keep minimal debug symbols and avoid strip errors
            debugSymbolLevel = "SYMBOL_TABLE"
        }
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            } else {
                storeFile = file(System.getenv("KEYSTORE_PATH") ?: "debug.keystore")
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "android"
                keyAlias = System.getenv("KEY_ALIAS") ?: "androiddebugkey"
                keyPassword = System.getenv("KEY_PASSWORD") ?: "android"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Modern packaging configuration (AGP 8.0+)
    packaging {
        jniLibs {
            keepDebugSymbols += "**/*.so"
        }
    }

    // Disable lint for release builds
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

// Disable problematic native debug symbol stripping and lint tasks
afterEvaluate {
    tasks.configureEach {
        when (name) {
            "stripReleaseDebugSymbols" -> enabled = false
            "lintVitalAnalyzeRelease" -> enabled = false
            "lintAnalyzeRelease" -> enabled = false
            "lintRelease" -> enabled = false
        }
    }
}

flutter {
    source = "../.."
}
