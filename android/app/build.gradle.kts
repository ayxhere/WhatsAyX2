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
        // NOTE: do NOT add ndk { abiFilters } here — the workflow builds
        // with `--split-per-abi --target-platform android-arm64`, which
        // already restricts the build to arm64-v8a, and Gradle FAILS
        // ("Conflicting configuration") if abiFilters and splits abi
        // filters are both set (run #22). libnode.so ships arm64-only,
        // and --target-platform keeps CMake from looking for other ABIs.
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

    // Release signing (keystore "imayx", 2026-11-12): reads from env vars
    // (CI: KEYSTORE_BASE64 decoded to a file, KEYSTORE_PASSWORD,
    // KEY_ALIAS, KEY_PASSWORD) or from keystore.properties (local).
    // Falls back to debug signing when no keystore is configured, so
    // local/CI builds never break on a missing keystore.
    val keystoreProps = java.util.Properties().apply {
        val f = rootProject.file("keystore.properties")
        if (f.exists()) f.inputStream().use { load(it) }
    }
    fun keystoreProp(name: String): String? =
        System.getenv(name) ?: keystoreProps.getProperty(name)
    val ksFile = keystoreProp("KEYSTORE_FILE")?.let { file(it) }
        ?: keystoreProp("KEYSTORE_PATH")?.let { file(it) }
    val ksPass = keystoreProp("KEYSTORE_PASSWORD")
    val ksAlias = keystoreProp("KEY_ALIAS") ?: "imayx"
    val keyPass = keystoreProp("KEY_PASSWORD") ?: ksPass

    signingConfigs {
        create("release") {
            if (ksFile != null && ksFile.exists() && ksPass != null) {
                storeFile = ksFile
                storePassword = ksPass
                keyAlias = ksAlias
                keyPassword = keyPass
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = if (ksFile != null && ksFile.exists() && ksPass != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
