plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.wa.ayx"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.wa.ayx"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Embedded Node (libnode.so) ships arm64-v8a only — the user's
        // phone is arm64, and the original app is arm64-only too.
        // Without this, the CMake build would look for a libnode.so
        // for armeabi-v7a / x86_64 that does not exist and fail.
        ndk {
            abiFilters += "arm64-v8a"
        }
    }

    // JNI glue for the embedded Node runtime (node_bridge.cpp).
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    androidResources {
        noCompress += "zip"   // keep assets/nodejs-project.zip STORED, not deflated
    }

    packaging {
        // Extract libnode.so to the filesystem (safer for the embedded runtime).
        jniLibs {
            useLegacyPackaging = false
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required: resolves Theme.Material3.* if any Material theme reference survives.
    implementation("com.google.android.material:material:1.12.0")
}
