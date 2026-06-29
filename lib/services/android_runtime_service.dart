import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../config/app_config.dart';
import 'platform_channel_service.dart';

/// Manages the embedded Android emulator lifecycle on Windows.
class AndroidRuntimeService {
  AndroidRuntimeService({
    PlatformChannelService? platform,
    String? runtimeRoot,
  })  : _platform = platform ?? PlatformChannelService(),
        _runtimeRoot = runtimeRoot;

  final PlatformChannelService _platform;
  final String? _runtimeRoot;

  Process? _emulatorProcess;
  int? _emulatorPid;

  String get runtimeDirectory {
    if (_runtimeRoot != null) return _runtimeRoot;
    final executable = Platform.resolvedExecutable;
    return p.normalize(p.join(p.dirname(executable), 'runtime'));
  }

  String get scriptsDirectory => p.join(runtimeDirectory, 'scripts');

  String _scriptPath(String name) => p.join(scriptsDirectory, name);

  Future<bool> isRuntimeInstalled() async {
    final marker = File(p.join(runtimeDirectory, '.runtime_ready'));
    return marker.existsSync();
  }

  Future<Map<String, dynamic>> checkPrerequisites() async {
    final result = await _runPowerShell(_scriptPath('health_check.ps1'), [
      '-Mode',
      'prerequisites',
    ]);
    return _parseJsonOutput(result.stdout) ?? {};
  }

  Future<bool> waitForDeviceReady({
    Duration timeout = AppConfig.runtimeTimeout,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final result = await _runPowerShell(_scriptPath('health_check.ps1'), [
        '-Mode',
        'device',
      ]);
      final json = _parseJsonOutput(result.stdout);
      if (json?['ready'] == true) {
        return true;
      }
      await Future<void>.delayed(AppConfig.healthCheckInterval);
    }
    return false;
  }

  Future<void> startEmulator() async {
    if (_emulatorPid != null) {
      return;
    }

    final result = await _runPowerShell(_scriptPath('start_emulator.ps1'), [
      '-AvdName',
      AppConfig.avdName,
    ]);

    if (result.exitCode != 0) {
      throw StateError(result.stderr.trim().isEmpty
          ? 'Failed to start Android emulator'
          : result.stderr.trim());
    }

    final json = _parseJsonOutput(result.stdout);
    final pid = json?['pid'];
    if (pid is int) {
      _emulatorPid = pid;
    } else if (pid is num) {
      _emulatorPid = pid.toInt();
    } else {
      _emulatorPid = await _readPidFile();
    }
  }

  Future<int?> _readPidFile() async {
    final pidFile = File(p.join(runtimeDirectory, '.emulator.pid'));
    if (!pidFile.existsSync()) return null;
    final text = (await pidFile.readAsString()).trim();
    return int.tryParse(text);
  }

  Future<void> installApplication({String? apkPath}) async {
    final result = await _runPowerShell(_scriptPath('install_app.ps1'), [
      '-PackageName',
      AppConfig.packageName,
      if (apkPath != null) ...['-ApkPath', apkPath],
    ]);

    if (result.exitCode != 0) {
      throw StateError(result.stderr.trim().isEmpty
          ? 'APK installation failed'
          : result.stderr.trim());
    }
  }

  Future<void> grantPermission(String permission) async {
    final result = await _runPowerShell(_scriptPath('grant_permissions.ps1'), [
      '-PackageName',
      AppConfig.packageName,
      '-Permission',
      permission,
    ]);

    if (result.exitCode != 0) {
      debugPrint('Permission grant warning for $permission: ${result.stderr}');
    }
  }

  Future<void> launchApplication() async {
    final result = await _runPowerShell(_scriptPath('launch_app.ps1'), [
      '-Component',
      AppConfig.launchActivity,
    ]);

    if (result.exitCode != 0) {
      throw StateError(result.stderr.trim().isEmpty
          ? 'Failed to launch ${AppConfig.packageName}'
          : result.stderr.trim());
    }
  }

  Future<bool> isCameraAvailable() async {
    final result = await _runPowerShell(_scriptPath('health_check.ps1'), [
      '-Mode',
      'camera',
    ]);
    final json = _parseJsonOutput(result.stdout);
    return json?['available'] == true;
  }

  Future<bool> embedEmulatorWindow() async {
    final pid = _emulatorPid;
    if (pid == null) return false;

    return _platform.embedProcessWindow(
      processId: pid,
      windowTitleHint: AppConfig.emulatorWindowTitleHint,
    );
  }

  Future<bool> isEmulatorRunning() async {
    final pid = _emulatorPid;
    if (pid == null) return false;
    return _platform.isProcessRunning(pid);
  }

  Future<void> stopEmulator() async {
    try {
      await _runPowerShell(_scriptPath('stop_emulator.ps1'), []);
    } catch (_) {
      _emulatorProcess?.kill();
    } finally {
      _emulatorProcess = null;
      _emulatorPid = null;
    }
  }

  int? get emulatorProcessId => _emulatorPid;

  Future<_ScriptResult> _runPowerShell(
    String script,
    List<String> args,
  ) async {
    final result = await Process.run(
      'powershell.exe',
      [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        script,
        ...args,
      ],
      workingDirectory: runtimeDirectory,
      runInShell: true,
    );

    return _ScriptResult(
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }

  Map<String, dynamic>? _parseJsonOutput(String output) {
    final lines = output.split('\n').map((l) => l.trim()).where((l) {
      return l.isNotEmpty && l.startsWith('{');
    });
    if (lines.isEmpty) return null;
    try {
      return jsonDecode(lines.last) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }
}

class _ScriptResult {
  const _ScriptResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}
