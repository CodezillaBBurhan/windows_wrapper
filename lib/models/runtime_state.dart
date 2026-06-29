/// Lifecycle states for the embedded Android runtime.
enum RuntimePhase {
  idle,
  checkingPrerequisites,
  startingRuntime,
  installingApp,
  grantingPermissions,
  launchingApp,
  embedding,
  running,
  error,
  stopped,
}

extension RuntimePhaseLabel on RuntimePhase {
  String get message {
    switch (this) {
      case RuntimePhase.idle:
        return 'Preparing…';
      case RuntimePhase.checkingPrerequisites:
        return 'Checking system requirements…';
      case RuntimePhase.startingRuntime:
        return 'Starting Android runtime…';
      case RuntimePhase.installingApp:
        return 'Installing application…';
      case RuntimePhase.grantingPermissions:
        return 'Configuring permissions…';
      case RuntimePhase.launchingApp:
        return 'Launching application…';
      case RuntimePhase.embedding:
        return 'Preparing display…';
      case RuntimePhase.running:
        return 'Running';
      case RuntimePhase.error:
        return 'Error';
      case RuntimePhase.stopped:
        return 'Stopped';
    }
  }

  double get progress {
    switch (this) {
      case RuntimePhase.idle:
        return 0.05;
      case RuntimePhase.checkingPrerequisites:
        return 0.15;
      case RuntimePhase.startingRuntime:
        return 0.35;
      case RuntimePhase.installingApp:
        return 0.55;
      case RuntimePhase.grantingPermissions:
        return 0.70;
      case RuntimePhase.launchingApp:
        return 0.85;
      case RuntimePhase.embedding:
        return 0.95;
      case RuntimePhase.running:
        return 1.0;
      case RuntimePhase.error:
      case RuntimePhase.stopped:
        return 0.0;
    }
  }
}
