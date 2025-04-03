# Flutter Framework
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.android.play.core.** { *; }

-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Правило для вашего приложения (замените com.example.flutter_pos на ваш реальный package name)
# Вы можете найти его вверху файла android/app/src/main/AndroidManifest.xml
# или в android/app/build.gradle (параметр applicationId)
-keep class com.example.flutter_pos.** { *; }

# Добавьте СЮДА правила для плагинов, которые вы найдете в их документации
# Например:
# -keep class androidx.security.crypto.** { *; } # Для flutter_secure_storage (проверьте актуальность)