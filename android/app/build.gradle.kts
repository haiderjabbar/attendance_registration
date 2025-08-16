plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // ✅ Official plugin ID
    id("dev.flutter.flutter-gradle-plugin") // Must be last
}

flutter {
    source = "../.."
}

android {
    namespace = "com.example.attendance_registration"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.attendance_registration"
        minSdk = 26
        targetSdk = 33
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false // ✅ Add this line to avoid the error
        }
    }


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11" // ✅ cleaner
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
}
