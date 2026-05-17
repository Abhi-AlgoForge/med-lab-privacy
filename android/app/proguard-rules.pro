# MedLab ProGuard / R8 rules
#
# R8 strips Java/Kotlin reflection metadata aggressively. Each plugin
# below either uses reflection internally (Gson model parsing, Play
# Billing service binding) or is invoked dynamically by Flutter's
# platform-channel layer, so the symbols must be preserved or the
# release APK will crash on first use.

# ---------------------------------------------------------------------
# Google Mobile Ads (google_mobile_ads)
# ---------------------------------------------------------------------
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep public class com.google.android.gms.ads.MobileAds { *; }
-dontwarn com.google.android.gms.ads.**

# ---------------------------------------------------------------------
# Google Play Billing (in_app_purchase)
# ---------------------------------------------------------------------
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.billing.** { *; }
-dontwarn com.android.billingclient.**

# ---------------------------------------------------------------------
# Firebase (firebase_core, firebase_remote_config)
# ---------------------------------------------------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ---------------------------------------------------------------------
# flutter_local_notifications
# ---------------------------------------------------------------------
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
# Notification action handlers + plugin instance preserved across
# JSON serialization for rescheduling on boot.
-keepclassmembers class * {
    @com.dexterous.flutterlocalnotifications.NotificationActionInfo *;
}

# ---------------------------------------------------------------------
# google_generative_ai (Gemini SDK)
# ---------------------------------------------------------------------
-keep class com.google.ai.client.generativeai.** { *; }
-dontwarn com.google.ai.client.generativeai.**

# ---------------------------------------------------------------------
# camera + image_picker
# ---------------------------------------------------------------------
-keep class io.flutter.plugins.camera.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# ---------------------------------------------------------------------
# share_plus, permission_handler, path_provider, etc.
# ---------------------------------------------------------------------
-keep class dev.fluttercommunity.plus.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# ---------------------------------------------------------------------
# Flutter platform channel glue — every plugin registrant relies on
# reflective discovery of its main class.
# ---------------------------------------------------------------------
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }

# ---------------------------------------------------------------------
# Annotations / signatures used at runtime by Gson, Retrofit-style
# adapters, and JSON model classes throughout the plugin ecosystem.
# ---------------------------------------------------------------------
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepattributes SourceFile, LineNumberTable
-renamesourcefileattribute SourceFile

# ---------------------------------------------------------------------
# Suppress noisy warnings from optional transitive deps.
# ---------------------------------------------------------------------
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn kotlinx.coroutines.**
