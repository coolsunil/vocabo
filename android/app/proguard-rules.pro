# Flutter engine rules are added automatically by the Flutter Gradle plugin.

# Keep our widget provider (also referenced in AndroidManifest, but explicit is safer)
-keep class com.jarhauliyalabs.vocabo.WordOfDayWidgetProvider { *; }
-keep class com.jarhauliyalabs.vocabo.MainActivity { *; }

# Google Play Billing (has consumer rules bundled, this is extra safety)
-keep class com.android.billingclient.** { *; }

# Suppress warnings for classes that may not exist on all API levels
-dontwarn java.lang.invoke.**
