import 'package:flutter_test/flutter_test.dart';

import 'package:android_wrapper/config/app_config.dart';
import 'package:android_wrapper/models/runtime_error.dart';
import 'package:android_wrapper/models/runtime_state.dart';

void main() {
  test('AppConfig targets Worky Kiosko package', () {
    expect(AppConfig.packageName, 'mx.worky.kioskoapp');
    expect(AppConfig.requiredPermissions, contains('android.permission.CAMERA'));
    expect(AppConfig.requiredPermissions, contains('android.permission.INTERNET'));
  });

  test('RuntimePhase provides user-facing progress', () {
    expect(RuntimePhase.startingRuntime.message, isNotEmpty);
    expect(RuntimePhase.startingRuntime.progress, greaterThan(0));
    expect(RuntimePhase.running.progress, 1.0);
  });

  test('RuntimeError factories include recovery guidance', () {
    final error = RuntimeError.internetUnavailable();
    expect(error.title, isNotEmpty);
    expect(error.recoveryAction, isNotNull);
  });
}
