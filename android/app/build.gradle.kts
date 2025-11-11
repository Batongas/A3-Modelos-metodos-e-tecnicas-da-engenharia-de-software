plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.viva_verde.viva_verde" // (Mantenha o seu se for diferente)
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        
        // 1. NOME CORRIGIDO: (isCoreLibraryDesugaringEnabled)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.viva_verde.viva_verde" // (Mantenha o seu se for diferente)
        
        // 2. SINTAXE MANTIDA (Correta):
        minSdkVersion(24) 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 3. BLOCO MANTIDO (Correto):
dependencies {
    // Adiciona a biblioteca "desugar"
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}