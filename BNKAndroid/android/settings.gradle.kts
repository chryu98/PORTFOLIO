// settings.gradle.kts (Kotlin DSL)

pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        // Flutter Gradle 플러그인/임베딩 쪽 추가
        maven(url = "https://storage.googleapis.com/download.flutter.io")
        // 네이버맵 SDK 저장소 추가
        maven(url = "https://naver.jfrog.io/artifactory/maven/")
        gradlePluginPortal()
    }
}

// ★ 여기가 핵심: 실제 의존성 해석에 사용되는 저장소를 명시
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        // Flutter 임베딩 아티팩트 저장소
        maven(url = "https://storage.googleapis.com/download.flutter.io")
        // 네이버맵 SDK 저장소
        maven(url = "https://naver.jfrog.io/artifactory/maven/")
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
