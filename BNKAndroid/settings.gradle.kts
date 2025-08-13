pluginManagement {
    repositories {
        google()
        gradlePluginPortal()
        mavenCentral()
        // 추가
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        maven { url = uri("https://naver.jfrog.io/artifactory/maven/") }
    }
}

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
