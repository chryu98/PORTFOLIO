// android/build.gradle.kts  (루트)

import org.gradle.api.tasks.compile.JavaCompile
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

// 필요 시 저장소만 선언 (settings.gradle.kts에서 처리 중이면 생략 가능)
allprojects {
    repositories {
        google()
        mavenCentral()
        // 네이버 지도 SDK 등 별도 레포가 필요하면 유지
        maven { url = uri("https://naver.jfrog.io/artifactory/maven/") }
    }
}

// 모든 서브프로젝트(모듈)에 공통 적용: JVM 타깃 17로 통일
subprojects {
    // Java 컴파일러
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }

    // Kotlin 컴파일러
    tasks.withType<KotlinCompile>().configureEach {
        // kotlinOptions 경고는 뜰 수 있지만 동작에는 문제 없습니다.
        kotlinOptions.jvmTarget = "17"
    }
}

// 루트 clean 태스크(Flutter 템플릿 호환)
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
