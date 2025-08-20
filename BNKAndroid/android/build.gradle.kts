// android/build.gradle.kts  (루트)

plugins {
    // 루트 빌드스크립트라면 보통 plugin은 없음
    // 필요 시 추가 가능
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://naver.jfrog.io/artifactory/maven/") } // 필요한 경우만 유지
    }
}

// ✅ JVM Toolchain 강제 (17로 고정)
plugins.withId("org.jetbrains.kotlin.android") {
    the<org.jetbrains.kotlin.gradle.dsl.KotlinJvmProjectExtension>().jvmToolchain(17)
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
