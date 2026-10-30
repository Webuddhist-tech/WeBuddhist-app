import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

android {
    namespace = "org.pecha.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.pecha.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Airbridge credentials — read from local.properties (gitignored) or
        // from CI environment variables so plaintext tokens never enter source.
        val airbridgeName = System.getenv("AIRBRIDGE_APP_NAME")
            ?: localProperties.getProperty("airbridge.app.name", "")
        val airbridgeToken = System.getenv("AIRBRIDGE_SDK_TOKEN")
            ?: localProperties.getProperty("airbridge.app.token", "")
        buildConfigField("String", "AIRBRIDGE_APP_NAME", "\"$airbridgeName\"")
        buildConfigField("String", "AIRBRIDGE_SDK_TOKEN", "\"$airbridgeToken\"")
        // Manifest placeholder so intent filters resolve the Airbridge domains at build time.
        manifestPlaceholders["airbridgeAppName"] = airbridgeName
    }

    val cmKeystorePath: String? = System.getenv("CM_KEYSTORE_PATH")
    val cmKeystorePassword: String? = System.getenv("CM_KEYSTORE_PASSWORD")
    val cmKeyAlias: String? = System.getenv("CM_KEY_ALIAS")
    val cmKeyPassword: String? = System.getenv("CM_KEY_PASSWORD")
    val isCi: Boolean = !cmKeystorePath.isNullOrBlank()

    signingConfigs {
        fun createSigningConfig(flavor: String) {
            val storeFilePath = if (isCi) cmKeystorePath
                else keystoreProperties["${flavor}.storeFile"]?.toString()
            if (storeFilePath.isNullOrBlank()) return

            create("${flavor}Release") {
                storeFile = file(storeFilePath)
                storePassword = if (isCi) cmKeystorePassword
                    else keystoreProperties["${flavor}.storePassword"]?.toString()
                keyAlias = if (isCi) cmKeyAlias
                    else keystoreProperties["${flavor}.keyAlias"]?.toString()
                keyPassword = if (isCi) cmKeyPassword
                    else keystoreProperties["${flavor}.keyPassword"]?.toString()
            }
        }

        createSigningConfig("dev")
        createSigningConfig("staging")
        createSigningConfig("prod")
    }

    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationId = "org.pecha.app.dev"
            resValue("string", "app_name", "[Dev] WeBuddhist")
            versionNameSuffix = "-dev"
            signingConfigs.findByName("devRelease")?.let { signingConfig = it }
            manifestPlaceholders["airbridgeAppName"] = "webuddhist"
            manifestPlaceholders["auth0Domain"] = "dev-vz6o17motc18g45h.us.auth0.com"
            manifestPlaceholders["auth0Scheme"] = "org.pecha.app.dev"
        }

        create("staging") {
            dimension = "environment"
            applicationId = "org.pecha.app.staging"
            resValue("string", "app_name", "[Stage] WeBuddhist")
            versionNameSuffix = "-staging"
            signingConfigs.findByName("stagingRelease")?.let { signingConfig = it }
            manifestPlaceholders["airbridgeAppName"] = "webuddhist"
            manifestPlaceholders["auth0Domain"] = "we-buddhist-prod.us.auth0.com"
            manifestPlaceholders["auth0Scheme"] = "org.pecha.app.staging"
        }

        create("prod") {
            dimension = "environment"
            applicationId = "org.pecha.app"
            resValue("string", "app_name", "WeBuddhist")
            signingConfigs.findByName("prodRelease")?.let { signingConfig = it }
            manifestPlaceholders["airbridgeAppName"] = "webuddhist"
            manifestPlaceholders["auth0Domain"] = "we-buddhist-prod.us.auth0.com"
            manifestPlaceholders["auth0Scheme"] = "org.pecha.app"
        }
    }

    buildTypes {
        getByName("release") {
            // Enable ProGuard for release builds
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
