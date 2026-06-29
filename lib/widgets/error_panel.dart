import 'package:flutter/material.dart';

import '../models/runtime_error.dart';

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    super.key,
    required this.error,
    required this.onRetry,
    this.onExit,
  });

  final RuntimeError error;
  final VoidCallback onRetry;
  final VoidCallback? onExit;

  IconData _iconFor(RuntimeErrorType type) {
    switch (type) {
      case RuntimeErrorType.runtimeNotAvailable:
      case RuntimeErrorType.initializationFailed:
      case RuntimeErrorType.runtimeCrashed:
        return Icons.memory;
      case RuntimeErrorType.cameraUnavailable:
      case RuntimeErrorType.cameraPermissionDenied:
        return Icons.videocam_off;
      case RuntimeErrorType.internetUnavailable:
        return Icons.wifi_off;
      case RuntimeErrorType.appLaunchFailed:
        return Icons.launch;
      case RuntimeErrorType.unknown:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _iconFor(error.type),
                      size: 36,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        error.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  error.message,
                  style: theme.textTheme.bodyLarge,
                ),
                if (error.recoveryAction != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error.recoveryAction!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (error.technicalDetails != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error.technicalDetails!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onExit != null)
                      TextButton(
                        onPressed: onExit,
                        child: const Text('Exit'),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
