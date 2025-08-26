// android/build.gradle.kts (루트)

import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
}

// ⚠️ JavaCompile 전역 설정(특히 options.release)은 하지 마세요 (AGP와 충돌).
// Kotlin만 전역 17로 통일해도 충분합니다.
subprojects {
    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions.jvmTarget = "17"
    }
}
