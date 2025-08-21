// android/settings.gradle.kts

pluginManagement {
    val flutterSdkPath = run {
        val p = java.util.Properties()
        file("local.properties").inputStream().use { p.load(it) }
        p.getProperty("flutter.sdk") ?: error("flutter.sdk not set in local.properties")
    }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // Flutter 전용 저장소 (필수)
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        // 네이버맵 쓰면
        maven { url = uri("https://naver.jfrog.io/artifactory/maven/") }
    }
}

// ★ 플러그인 버전은 settings에서만!
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.6.1" apply false   // ← 8.6.x
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false // 1.9.24 안정권
}

// 저장소 해석은 프로젝트/모듈도 허용 (플러그인이 maven 추가해도 OK)
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        maven { url = uri("https://naver.jfrog.io/artifactory/maven/") }
    }
}

rootProject.name = "bnkandroid"
include(":app")
