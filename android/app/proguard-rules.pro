# ── flutter_local_notifications + Gson ────────────────────────────────────────
# R8 was stripping generic signatures, so Gson's TypeToken lost its type
# parameter ("Missing type parameter") and scheduled notifications failed to
# persist/restore — the alarm fired but nothing was posted. Keeping the
# Signature/annotation attributes and the plugin + Gson type machinery fixes it.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod

# The plugin's serialised model classes (NotificationDetails, etc.)
-keep class com.dexterous.** { *; }

# Gson reflective type resolution
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ── Flutter / core-library desugaring ─────────────────────────────────────────
-keep class io.flutter.** { *; }
-dontwarn com.google.errorprone.annotations.**

# Flutter references Play Core (deferred components / split install) which we
# don't ship. Tell R8 to ignore the missing classes.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
