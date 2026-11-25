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

# Flutter deferred components optional Play Core references (AGP 8/9+ R8)
-dontwarn com.google.android.play.core.**

# Flutter Secure Storage & Google Tink AES-256 EncryptedSharedPreferences
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# Flutter Local Notifications (keep notification classes under R8)
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**
