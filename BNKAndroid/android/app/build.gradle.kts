import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
// import java.nio.file.Files  // ← 안 씀: 제거해도 됨

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
        //minSdk = flutter.minSdkVersion
        minSdk = 23               // ★ 여기 숫자로 고정
        targetSdk = 36               // ← flutter.targetSdkVersion 대신 명시 권장
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // multiDexEnabled = true
    }

    buildTypes {
        debug {
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            isDebuggable = false
            isMinifyEnabled = false
            isShrinkResources = false
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("com.naver.maps:map-sdk:3.22.1")
    // implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}

tasks.withType<KotlinCompile>().configureEach {
    kotlinOptions.jvmTarget = "17"
}

