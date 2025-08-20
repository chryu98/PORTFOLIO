import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import java.io.File

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Flutter 기본 빌드 폴더 변경 설정
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// 🔥 모든 서브프로젝트(Java/Kotlin 컴파일러 옵션 통일)
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }
}

// clean task 정의
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
