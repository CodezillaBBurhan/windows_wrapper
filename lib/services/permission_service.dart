import '../config/app_config.dart';
import 'android_runtime_service.dart';
import 'platform_channel_service.dart';

/// Handles camera and Android permission grants for the wrapped app.
class PermissionService {
  PermissionService({
    required AndroidRuntimeService runtime,
    PlatformChannelService? platform,
  })  : _runtime = runtime,
        _platform = platform ?? PlatformChannelService();

  final AndroidRuntimeService _runtime;
  final PlatformChannelService _platform;

  /// Ensures Windows camera access and grants Android runtime permissions.
  Future<void> configurePermissions() async {
    final cameraGranted = await _platform.requestCameraPermission();
    if (!cameraGranted) {
      throw StateError('Windows camera permission denied');
    }

    for (final permission in AppConfig.requiredPermissions) {
      await _runtime.grantPermission(permission);
    }
  }

  Future<bool> isCameraAvailable() => _runtime.isCameraAvailable();
}
