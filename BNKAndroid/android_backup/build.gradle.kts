// 🔧 루트 build.gradle.kts

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://naver.jfrog.io/artifactory/maven/") } // 네이버 지도 SDK 저장소
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
