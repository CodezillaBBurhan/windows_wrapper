import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../models/runtime_state.dart';
import '../services/launcher_controller.dart';
import '../widgets/error_panel.dart';
import '../widgets/loading_screen.dart';

/// Main launcher screen coordinating runtime startup and embedded display.
class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  late final LauncherController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LauncherController();
    _controller.addListener(_onControllerUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.start();
    });
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _exitApp() async {
    await _controller.stop();
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    final phase = _controller.phase;
    final error = _controller.error;

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Worky Kiosko')),
        body: ErrorPanel(
          error: error,
          onRetry: _controller.retry,
          onExit: _exitApp,
        ),
      );
    }

    if (_controller.isEmbedded) {
      // Native embed host is visible; Flutter provides minimal chrome.
      return Scaffold(
        backgroundColor: Colors.black,
        body: const SizedBox.expand(),
      );
    }

    return Scaffold(
      appBar: phase == RuntimePhase.running
          ? null
          : AppBar(
              title: const Text('Worky Kiosko'),
              actions: [
                if (Platform.isWindows)
                  IconButton(
                    tooltip: 'Fullscreen',
                    onPressed: () async {
                      final isFull = await windowManager.isFullScreen();
                      await windowManager.setFullScreen(!isFull);
                    },
                    icon: const Icon(Icons.fullscreen),
                  ),
              ],
            ),
      body: LoadingScreen(
        phase: phase,
        subtitle: phase == RuntimePhase.startingRuntime
            ? 'First launch may take a few minutes while the Android runtime initializes.'
            : null,
      ),
    );
  }
}
