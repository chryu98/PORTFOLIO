plugins {
    id("com.android.application")
    // Kotlin 안 쓸 거면 아래 줄 제거 유지
    // id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bnkandroid"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    // ❌ kotlinOptions 블록 없음 (지워야 함)

    defaultConfig {
        applicationId = "com.example.bnkandroid"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("com.naver.maps:map-sdk:3.22.1")
}

flutter {
    source = "../.."
}


