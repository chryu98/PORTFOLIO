// android/build.gradle.kts  (루트)

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://naver.jfrog.io/artifactory/maven/") } // 필요한 경우만 유지
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
