plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.adic_poc"
    compileSdk =  35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.adic_poc"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["appAuthRedirectScheme"] = "msauth"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.code.findbugs:jsr305:3.0.2") // For @Nullable, @Nonnull, etc.
    implementation("com.google.errorprone:error_prone_annotations:2.11.0") // For Tink annotations
    implementation("com.microsoft.azure:notification-hubs-android-sdk-fcm:1.1.4")
    implementation ("androidx.appcompat:appcompat:1.4.1")
    implementation("com.android.volley:volley:1.2.1")
}

apply(plugin = "com.google.gms.google-services")
