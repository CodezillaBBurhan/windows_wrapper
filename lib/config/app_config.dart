/// Application configuration for the Worky Kiosko Android wrapper.
class AppConfig {
  AppConfig._();

  static const String appTitle = 'Worky Kiosko';
  static const String packageName = 'mx.worky.kioskoapp';

  /// Relative path to the bundled APK inside assets.
  static const String apkAssetPath = 'apk/worky_kiosko.apk';

  /// AVD name created by the runtime setup script.
  static const String avdName = 'WorkyKiosk';

  /// Android permissions required by the wrapped app.
  static const List<String> requiredPermissions = [
    'android.permission.CAMERA',
    'android.permission.INTERNET',
    'android.permission.ACCESS_NETWORK_STATE',
  ];

  /// Main activity launched after runtime initialization.
  static const String launchActivity =
      'mx.worky.kioskoapp/.MainActivity';

  /// Emulator window title substring used for HWND lookup.
  static const String emulatorWindowTitleHint = 'Android Emulator';

  /// Default window dimensions.
  static const double defaultWidth = 1280;
  static const double defaultHeight = 800;

  /// Maximum time to wait for the Android runtime to become ready.
  static const Duration runtimeTimeout = Duration(minutes: 5);

  /// Interval between runtime health checks during startup.
  static const Duration healthCheckInterval = Duration(seconds: 2);
}
