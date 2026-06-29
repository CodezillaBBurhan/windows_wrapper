import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import '../models/runtime_error.dart';
import '../models/runtime_state.dart';
import 'android_runtime_service.dart';
import 'network_service.dart';
import 'permission_service.dart';
import 'platform_channel_service.dart';

/// Orchestrates startup, embedding, monitoring, and recovery of the Android app.
class LauncherController extends ChangeNotifier {
  LauncherController({
    AndroidRuntimeService? runtime,
    NetworkService? network,
    PermissionService? permissions,
    PlatformChannelService? platform,
  })  : _runtime = runtime ?? AndroidRuntimeService(),
        _network = network ?? NetworkService(),
        _platform = platform ?? PlatformChannelService() {
    _permissions = permissions ??
        PermissionService(runtime: _runtime, platform: _platform);
  }

  final AndroidRuntimeService _runtime;
  final NetworkService _network;
  final PlatformChannelService _platform;
  late final PermissionService _permissions;

  RuntimePhase _phase = RuntimePhase.idle;
  RuntimeError? _error;
  bool _isFullscreen = false;
  bool _isEmbedded = false;
  Timer? _watchdog;

  RuntimePhase get phase => _phase;
  RuntimeError? get error => _error;
  bool get isFullscreen => _isFullscreen;
  bool get isEmbedded => _isEmbedded;
  bool get isRunning => _phase == RuntimePhase.running;
  bool get hasError => _error != null;

  Future<void> start() async {
    _error = null;
    await _setPhase(RuntimePhase.checkingPrerequisites);

    try {
      if (!await _network.hasInternetAccess()) {
        throw RuntimeError.internetUnavailable();
      }

      if (!await _runtime.isRuntimeInstalled()) {
        throw RuntimeError.runtimeNotAvailable(
          details: 'Missing ${p.join(_runtime.runtimeDirectory, '.runtime_ready')}',
        );
      }

      final prerequisites = await _runtime.checkPrerequisites();
      if (prerequisites['hypervisor'] != true) {
        throw RuntimeError.initializationFailed(
          details: 'Hypervisor not available. Enable virtualization in BIOS.',
        );
      }

      if (!await _permissions.isCameraAvailable()) {
        throw RuntimeError.cameraUnavailable();
      }

      await _setPhase(RuntimePhase.startingRuntime);
      await _runtime.startEmulator();

      final ready = await _runtime.waitForDeviceReady();
      if (!ready) {
        throw RuntimeError.initializationFailed(
          details: 'Emulator did not report ready within timeout.',
        );
      }

      await _setPhase(RuntimePhase.installingApp);
      final apkPath = await _extractBundledApk();
      await _runtime.installApplication(apkPath: apkPath);

      await _setPhase(RuntimePhase.grantingPermissions);
      try {
        await _permissions.configurePermissions();
      } on StateError catch (e) {
        if (e.message.contains('camera')) {
          throw RuntimeError.cameraPermissionDenied(details: e.message);
        }
        rethrow;
      }

      await _setPhase(RuntimePhase.launchingApp);
      await _runtime.launchApplication();

      await _setPhase(RuntimePhase.embedding);
      await _embedRuntime();

      await _setPhase(RuntimePhase.running);
      _startWatchdog();
    } on RuntimeError catch (e) {
      _error = e;
      await _setPhase(RuntimePhase.error);
    } catch (e, stack) {
      debugPrint('Launcher error: $e\n$stack');
      _error = RuntimeError.unknown(details: e.toString());
      await _setPhase(RuntimePhase.error);
    }
  }

  Future<void> retry() async {
    await stop();
    await start();
  }

  Future<void> stop() async {
    _watchdog?.cancel();
    _watchdog = null;
    await _platform.destroyEmbedHost();
    await _platform.setFlutterViewVisible(true);
    await _runtime.stopEmulator();
    _isEmbedded = false;
    await _setPhase(RuntimePhase.stopped);
  }

  Future<void> toggleFullscreen() async {
    _isFullscreen = !_isFullscreen;
    notifyListeners();
  }

  Future<String?> _extractBundledApk() async {
    try {
      final bytes = await rootBundle.load(AppConfig.apkAssetPath);
      final tempDir = await getTemporaryDirectory();
      final apkFile = File(p.join(tempDir.path, 'worky_kiosko.apk'));
      await apkFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      return apkFile.path;
    } on FlutterError {
      // APK not bundled — install script will use an existing installation.
      return null;
    }
  }

  Future<void> _embedRuntime() async {
    await _platform.createEmbedHost(x: 0, y: 0, width: 1280, height: 720);

    final embedded = await _runtime.embedEmulatorWindow();
    if (!embedded) {
      throw RuntimeError.appLaunchFailed(
        details: 'Could not embed emulator window.',
      );
    }

    await _platform.setFlutterViewVisible(false);
    await _platform.setEmbedHostVisible(true);
    _isEmbedded = true;
    notifyListeners();
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_phase != RuntimePhase.running) return;

      if (!await _runtime.isEmulatorRunning()) {
        _error = RuntimeError.runtimeCrashed();
        await _setPhase(RuntimePhase.error);
        _watchdog?.cancel();
        return;
      }

      if (!await _network.hasInternetAccess()) {
        _error = RuntimeError.internetUnavailable();
        await _setPhase(RuntimePhase.error);
        _watchdog?.cancel();
      }
    });
  }

  Future<void> _setPhase(RuntimePhase phase) async {
    _phase = phase;
    notifyListeners();
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }
}
