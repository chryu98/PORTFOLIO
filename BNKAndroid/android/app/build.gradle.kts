import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")   // ✅ 추가
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

    // Java 17 권장 (AGP 8.x 조합에서 필요)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }



    // 디버그/릴리스 설정 (Kotlin DSL 문법!)
    buildTypes {
        getByName("debug") {
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("release") {
            isDebuggable = false   // ✅ Groovy의 'debuggable false' 아님
            isMinifyEnabled = false
            isShrinkResources = false
            // 서명/프로가드 필요 시 나중에 추가
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }

    // 에뮬레이터 설치/탐지 이슈 줄이려면 디버그에서 ABI 스플릿 끄기
    splits {
        abi {
            isEnable = false
            // 또는 isUniversalApk = true
        }
    }

    // ndkVersion은 꼭 필요할 때만 지정 (없어도 보통 무관)
    // ndkVersion = "27.0.12077973"
}

dependencies {
    implementation("com.naver.maps:map-sdk:3.22.1")
}

flutter {
    source = "../.."
}


tasks.withType<KotlinCompile>().configureEach {
    kotlinOptions {
        jvmTarget = "17"
    }
}