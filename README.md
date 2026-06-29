# Worky Kiosko — Windows Android Wrapper

A native Windows desktop application that runs the [Worky Kiosko Android app](https://play.google.com/store/apps/details?id=mx.worky.kioskoapp) inside an embedded Android runtime, with no changes required to the Android source code.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Flutter Windows Shell (Worky Kiosko.exe)               │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Loading screen · Error handling · Window controls │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Native Embed Host (Win32 SetParent)               │  │
│  │  ┌─────────────────────────────────────────────┐    │  │
│  │  │ Google Android Emulator (bundled AVD)       │    │  │
│  │  │  mx.worky.kioskoapp                         │    │  │
│  │  └─────────────────────────────────────────────┘    │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Runtime choice

| Option | Status | Verdict |
|--------|--------|---------|
| Windows Subsystem for Android (WSA) | Deprecated March 2025 | Not suitable for production |
| Google Android Emulator | Actively maintained | **Selected** — reliable, camera passthrough, full network |
| Third-party emulators (BlueStacks, etc.) | Proprietary, not embeddable | Not suitable |

The wrapper bundles the official Android Emulator with a pre-configured AVD (`WorkyKiosk`). PowerShell scripts manage SDK setup, emulator lifecycle, APK installation, and permission grants. The emulator window is embedded into the Flutter shell via Win32 `SetParent`.

## Features

- **Automatic launch** — Opens the Android app on startup after runtime initialization
- **Loading screen** — Progress indicator during emulator boot and app install
- **Camera** — Host webcam passed through (`-camera-back webcam0`); Android permissions auto-granted via ADB
- **Internet** — Full HTTP/HTTPS via emulator NAT; connectivity monitored at runtime
- **Embedded display** — Emulator window reparented into the desktop shell
- **Fullscreen** — Toggle via title bar control (window_manager)
- **Error handling** — User-friendly messages for runtime, camera, network, and crash scenarios with Retry

## Requirements

### Development machine

- Flutter SDK 3.10+ with Windows desktop enabled
- Visual Studio 2022 with "Desktop development with C++" workload

### Target Windows machines

- Windows 10 (2004+) or Windows 11, 64-bit
- CPU virtualization enabled in BIOS
- Windows features: **Virtual Machine Platform**, **Windows Hypervisor Platform**
- 8 GB RAM minimum (16 GB recommended)
- Webcam (for camera features)
- Internet connection

## Quick Start

### 1. Add the APK

Place your release APK at:

```
assets/apk/worky_kiosko.apk
```

Obtain the APK from your Android CI/CD pipeline. The Play Store does not allow redistributing APKs.

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Build for Windows

```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/`

### 4. Set up the Android runtime (once per machine)

On the target Windows PC, run as Administrator:

```powershell
cd build\windows\x64\runner\Release\runtime\scripts
.\setup_runtime.ps1
```

This downloads the Android SDK command-line tools, emulator, system image (API 34), and creates the `WorkyKiosk` AVD. Takes 5–15 minutes depending on network speed.

### 5. Launch

```bash
build\windows\x64\runner\Release\android_wrapper.exe
```

Or distribute the entire `Release` folder as your installer payload.

## Project structure

```
lib/
  config/app_config.dart          # Package name, permissions, timeouts
  models/                         # Runtime state and error types
  services/
    android_runtime_service.dart  # Emulator lifecycle via PowerShell
    launcher_controller.dart      # Startup orchestration
    permission_service.dart       # Camera + Android permissions
    network_service.dart          # Host connectivity checks
    platform_channel_service.dart # Win32 embedding bridge
  screens/launcher_screen.dart      # Main UI
  widgets/                        # Loading and error components
windows/runner/
  window_embedder.cpp             # SetParent embedding logic
  runtime_channel_handler.cpp     # Flutter ↔ native bridge
runtime/scripts/
  setup_runtime.ps1               # One-time SDK/AVD setup
  start_emulator.ps1              # Boot emulator with webcam
  install_app.ps1                 # APK installation
  grant_permissions.ps1           # ADB permission grants
  launch_app.ps1                  # Start MainActivity
  health_check.ps1                # Prerequisites, device, camera checks
  stop_emulator.ps1               # Clean shutdown
```

## Permissions

### Camera

1. **Windows** — Desktop apps access the webcam when available. If blocked, the user is directed to Settings → Privacy → Camera.
2. **Android** — `android.permission.CAMERA` is granted via `adb shell pm grant`.
3. **Emulator** — Webcam mapped with `-camera-back webcam0`.

### Internet

- Emulator uses NAT networking (`-netspeed full`) for unrestricted HTTP/HTTPS.
- The wrapper monitors host connectivity and surfaces errors if the network drops.

## Error recovery

| Scenario | User message | Recovery |
|----------|-------------|----------|
| Runtime not installed | Android Runtime Not Available | Run `setup_runtime.ps1` |
| Emulator won't start | Runtime Initialization Failed | Enable virtualization / Hyper-V |
| No webcam | Camera Unavailable | Connect a camera |
| Camera blocked | Camera Permission Denied | Windows Privacy settings |
| No network | No Internet Connection | Restore connectivity |
| App won't launch | Application Launch Failed | Retry (reinstalls APK) |
| Emulator crash | Runtime Crashed | Restart |

## Distribution

For production deployment:

1. Build the release binary
2. Run `setup_runtime.ps1` on a golden image, or ship it as a first-run installer step
3. Optionally pre-populate `runtime/android-sdk` to avoid download on first run (~2 GB)
4. Package with an installer (WiX, Inno Setup, MSIX) that enables required Windows features

## Customization

Edit `lib/config/app_config.dart` to change:

- `packageName` — Android application ID
- `launchActivity` — Main activity component name
- `requiredPermissions` — Permissions to auto-grant
- `avdName` — Emulator profile name

## License

Private — Worky Kiosko wrapper. The Android application remains subject to its own license terms.
