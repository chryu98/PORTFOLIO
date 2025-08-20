import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bnkandroid"

    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.bnkandroid"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ Java 17로 고정
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildTypes {
        getByName("debug") {
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("release") {
            isDebuggable = false
            isMinifyEnabled = false
            isShrinkResources = false
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }

    splits {
        abi {
            isEnable = false
            // isUniversalApk = true
        }
    }

    // ndkVersion = "27.0.12077973" // 필요 시만 지정
}

dependencies {
    implementation("com.naver.maps:map-sdk:3.22.1")
}

flutter {
    source = "../.."
}

// ✅ Kotlin도 17로 고정
tasks.withType<KotlinCompile>().configureEach {
    kotlinOptions {
        jvmTarget = "17"
    }
}

// ✅ Toolchain (모듈 단위에서도 적용)
kotlin {
    jvmToolchain(17)
}
