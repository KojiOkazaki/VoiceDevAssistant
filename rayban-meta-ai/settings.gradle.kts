// Load local.properties
val localProperties = java.util.Properties()
val localPropertiesFile = file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(localPropertiesFile.inputStream())
}

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()

        // Meta Wearables Device Access Toolkit (GitHub Packages)
        maven {
            url = uri("https://maven.pkg.github.com/facebook/meta-wearables-dat-android")
            credentials {
                username = localProperties.getProperty("github_user")
                    ?: System.getenv("GITHUB_USER")
                    ?: "token"
                password = localProperties.getProperty("github_token")
                    ?: System.getenv("GITHUB_TOKEN")
                    ?: error("github_token not set in local.properties or GITHUB_TOKEN env var")
            }
        }
    }
}

rootProject.name = "RayBanMetaAI"
include(":app")
