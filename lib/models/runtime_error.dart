/// Typed errors surfaced to the user with recovery guidance.
enum RuntimeErrorType {
  runtimeNotAvailable,
  initializationFailed,
  cameraUnavailable,
  cameraPermissionDenied,
  internetUnavailable,
  appLaunchFailed,
  runtimeCrashed,
  unknown,
}

class RuntimeError {
  const RuntimeError({
    required this.type,
    required this.title,
    required this.message,
    this.recoveryAction,
    this.technicalDetails,
  });

  final RuntimeErrorType type;
  final String title;
  final String message;
  final String? recoveryAction;
  final String? technicalDetails;

  factory RuntimeError.runtimeNotAvailable({String? details}) => RuntimeError(
        type: RuntimeErrorType.runtimeNotAvailable,
        title: 'Android Runtime Not Available',
        message:
            'The embedded Android runtime could not be found. '
            'Run the setup script once to install the required components.',
        recoveryAction: 'Run runtime\\scripts\\setup_runtime.ps1 as Administrator, then restart.',
        technicalDetails: details,
      );

  factory RuntimeError.initializationFailed({String? details}) => RuntimeError(
        type: RuntimeErrorType.initializationFailed,
        title: 'Runtime Initialization Failed',
        message:
            'The Android emulator failed to start. '
            'Ensure virtualization (Hyper-V or HAXM) is enabled in BIOS and Windows features.',
        recoveryAction: 'Enable Windows Hypervisor Platform, then click Retry.',
        technicalDetails: details,
      );

  factory RuntimeError.cameraUnavailable({String? details}) => RuntimeError(
        type: RuntimeErrorType.cameraUnavailable,
        title: 'Camera Unavailable',
        message:
            'No webcam was detected on this computer. '
            'Connect a camera or check Device Manager.',
        recoveryAction: 'Connect a webcam and click Retry.',
        technicalDetails: details,
      );

  factory RuntimeError.cameraPermissionDenied({String? details}) => RuntimeError(
        type: RuntimeErrorType.cameraPermissionDenied,
        title: 'Camera Permission Denied',
        message:
            'Windows blocked camera access for this application. '
            'Allow camera access in Windows Settings → Privacy → Camera.',
        recoveryAction: 'Open Windows Camera privacy settings and allow desktop apps.',
        technicalDetails: details,
      );

  factory RuntimeError.internetUnavailable({String? details}) => RuntimeError(
        type: RuntimeErrorType.internetUnavailable,
        title: 'No Internet Connection',
        message:
            'The application requires an active internet connection. '
            'Check your network cable, Wi-Fi, or firewall settings.',
        recoveryAction: 'Restore your connection and click Retry.',
        technicalDetails: details,
      );

  factory RuntimeError.appLaunchFailed({String? details}) => RuntimeError(
        type: RuntimeErrorType.appLaunchFailed,
        title: 'Application Launch Failed',
        message:
            'The Android application could not be started inside the runtime.',
        recoveryAction: 'Click Retry to reinstall and relaunch the app.',
        technicalDetails: details,
      );

  factory RuntimeError.runtimeCrashed({String? details}) => RuntimeError(
        type: RuntimeErrorType.runtimeCrashed,
        title: 'Runtime Crashed',
        message:
            'The Android runtime stopped unexpectedly. '
            'Your session data may have been lost.',
        recoveryAction: 'Click Restart to reload the application.',
        technicalDetails: details,
      );

  factory RuntimeError.unknown({String? details}) => RuntimeError(
        type: RuntimeErrorType.unknown,
        title: 'Unexpected Error',
        message: 'An unexpected error occurred while running the application.',
        recoveryAction: 'Click Retry. If the problem persists, restart the app.',
        technicalDetails: details,
      );
}
