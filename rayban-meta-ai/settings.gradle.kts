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
                username = providers.gradleProperty("github_user").orElse(
                    providers.environmentVariable("GITHUB_USER")
                ).getOrElse("token")
                password = providers.gradleProperty("github_token").orElse(
                    providers.environmentVariable("GITHUB_TOKEN")
                ).get()
            }
        }
    }
}

rootProject.name = "RayBanMetaAI"
include(":app")
