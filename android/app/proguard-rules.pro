# Regras R8/ProGuard do Aurora — mantém o que os plugins refletem.
# (just_audio, flutter_local_notifications e file_picker embutem regras
# consumer; estas são as complementares padrão.)

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# AudioService / just_audio (media3)
-keep class androidx.media.** { *; }
-keep class androidx.media3.** { *; }
-keep class com.ryanheise.** { *; }
-dontwarn com.ryanheise.**

# Pigeon (shared_preferences e demais pontes Dart↔Java) — corrotinas Kotlin
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.coroutines.** { *; }
-dontwarn kotlin.coroutines.**

# timezone / joda-like (flutter_local_notifications usa joda time pop)
-dontwarn org.joda.time.**

# file_picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
