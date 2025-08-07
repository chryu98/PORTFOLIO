// 🔧 루트 build.gradle.kts

// 플러그인 정의
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 리포지토리 정의
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://naver.jfrog.io/artifactory/maven/") }
    }
}

// 💡 빌드 디렉토리 변경
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// 💣 태스크 직접 선언
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
