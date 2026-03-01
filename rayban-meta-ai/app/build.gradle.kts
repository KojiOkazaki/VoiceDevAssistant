plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
}

android {
    namespace = "com.example.raybanmetaai"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.raybanmetaai"
        minSdk = 29  // Android 10 (Meta AI app requirement)
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        // Read OpenAI API key from local.properties
        val localProperties = java.util.Properties()
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            localProperties.load(localPropertiesFile.inputStream())
        }
        buildConfigField(
            "String",
            "OPENAI_API_KEY",
            "\"${localProperties.getProperty("openai_api_key", "")}\""
        )
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    buildFeatures {
        viewBinding = true
        buildConfig = true
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.material)
    implementation(libs.androidx.constraintlayout)
    implementation(libs.androidx.lifecycle.runtime)
    implementation(libs.androidx.lifecycle.viewmodel)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.okhttp)

    // Meta Wearables Device Access Toolkit
    implementation(libs.mwdat.core)
    implementation(libs.mwdat.camera)
    implementation(libs.mwdat.mockdevice)
}
