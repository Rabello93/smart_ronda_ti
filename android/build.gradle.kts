allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    // WORKAROUND: Fix for older plugins missing namespace (e.g. image_gallery_saver)
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android is com.android.build.gradle.BaseExtension) {
                if (android.namespace == null) {
                    val packageName = project.group.toString().replace(":", ".")
                    if (packageName.isNotEmpty()) {
                        android.namespace = packageName
                    }
                }
                android.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
                android.compileOptions.targetCompatibility = JavaVersion.VERSION_17
            }
        }
        
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
