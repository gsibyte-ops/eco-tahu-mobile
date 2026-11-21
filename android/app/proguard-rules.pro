# Flutter & Android R8 / ProGuard Rules for EcoTahu Mobile
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase & Google Play Services / Google Sign-In
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**

# OkHttp / Networking & Video Player
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }
