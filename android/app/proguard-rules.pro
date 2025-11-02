# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Play Core for dynamic delivery
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }

# Tasks and listeners
-keep class com.google.android.play.core.tasks.** { *; }

# Your application
-keep class com.indigi.indigi_attendance_app.** { *; }

# JSON serialization
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes *Annotation*
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Platform channels
-keep class * extends io.flutter.plugin.common.MethodCallHandler { *; }

# General app classes
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# HTTP clients
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class retrofit2.** { *; }

# For data classes and models
-keepclassmembers class * {
    public <init>();
}

# Reflection
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations

# Preserve native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep relevant resources
-keepclassmembers class **.R$* {
    public static <fields>;
}