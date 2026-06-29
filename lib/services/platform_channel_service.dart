import 'package:flutter/services.dart';

/// Native Windows platform channel for window embedding and process management.
class PlatformChannelService {
  PlatformChannelService({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('com.worky.android_wrapper/runtime');

  final MethodChannel _channel;

  Future<void> createEmbedHost({
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    await _channel.invokeMethod<void>('createEmbedHost', {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    });
  }

  Future<bool> embedProcessWindow({
    required int processId,
    String windowTitleHint = 'Android Emulator',
    int timeoutMs = 120000,
  }) async {
    final result = await _channel.invokeMethod<bool>('embedProcessWindow', {
      'processId': processId,
      'windowTitleHint': windowTitleHint,
      'timeoutMs': timeoutMs,
    });
    return result ?? false;
  }

  Future<void> resizeEmbedHost({
    required int width,
    required int height,
  }) async {
    await _channel.invokeMethod<void>('resizeEmbedHost', {
      'width': width,
      'height': height,
    });
  }

  Future<void> setEmbedHostVisible(bool visible) async {
    await _channel.invokeMethod<void>('setEmbedHostVisible', {
      'visible': visible,
    });
  }

  Future<void> setFlutterViewVisible(bool visible) async {
    await _channel.invokeMethod<void>('setFlutterViewVisible', {
      'visible': visible,
    });
  }

  Future<void> destroyEmbedHost() async {
    await _channel.invokeMethod<void>('destroyEmbedHost');
  }

  Future<bool> isProcessRunning(int processId) async {
    final result = await _channel.invokeMethod<bool>('isProcessRunning', {
      'processId': processId,
    });
    return result ?? false;
  }

  Future<bool> requestCameraPermission() async {
    final result =
        await _channel.invokeMethod<bool>('requestCameraPermission');
    return result ?? false;
  }
}
