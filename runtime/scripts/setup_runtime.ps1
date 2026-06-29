#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Downloads and configures the embedded Android SDK, emulator, and AVD.

.DESCRIPTION
  Run once on each Windows machine before launching Worky Kiosko.
  Creates runtime/android-sdk with platform-tools, emulator, and a system image.
#>
param(
    [string]$ApiLevel = "34",
    [string]$AvdName = "WorkyKiosk"
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"

$runtimeRoot = Get-RuntimeRoot
$sdkRoot = Join-Path $runtimeRoot "android-sdk"
$cmdlineTools = Join-Path $sdkRoot "cmdline-tools\latest"
$sdkmanager = Join-Path $cmdlineTools "bin\sdkmanager.bat"

Write-Host "Worky Kiosko — Android Runtime Setup" -ForegroundColor Cyan
Write-Host "Runtime directory: $runtimeRoot"

# Enable required Windows features for emulator acceleration.
$features = @("VirtualMachinePlatform", "HypervisorPlatform")
foreach ($feature in $features) {
    $state = (Get-WindowsOptionalFeature -Online -FeatureName $feature).State
    if ($state -ne "Enabled") {
        Write-Host "Enabling Windows feature: $feature"
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -All | Out-Null
    }
}

New-Item -ItemType Directory -Force -Path $sdkRoot | Out-Null

if (-not (Test-Path $sdkmanager)) {
    Write-Host "Downloading Android command-line tools..."
    $zipUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
    $zipPath = Join-Path $env:TEMP "android-cmdline-tools.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
    $extractDir = Join-Path $env:TEMP "android-cmdline-tools"
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
    New-Item -ItemType Directory -Force -Path (Join-Path $sdkRoot "cmdline-tools\latest") | Out-Null
    Copy-Item -Path (Join-Path $extractDir "cmdline-tools\*") -Destination (Join-Path $sdkRoot "cmdline-tools\latest") -Recurse -Force
}

$env:ANDROID_SDK_ROOT = $sdkRoot
$env:ANDROID_HOME = $sdkRoot

Write-Host "Installing SDK packages (this may take several minutes)..."
$packages = @(
    "platform-tools",
    "emulator",
    "platforms;android-$ApiLevel",
    "system-images;android-$ApiLevel;google_apis;x86_64"
)
foreach ($pkg in $packages) {
    Write-Host "  -> $pkg"
    echo "y" | & $sdkmanager $pkg 2>&1 | Out-Null
}

$avdManager = Join-Path $cmdlineTools "bin\avdmanager.bat"
$existing = & $avdManager list avd 2>&1 | Select-String $AvdName
if (-not $existing) {
    Write-Host "Creating AVD: $AvdName"
    echo "no" | & $avdManager create avd -n $AvdName -k "system-images;android-$ApiLevel;google_apis;x86_64" -d "pixel_6" --force 2>&1 | Out-Null
}

# Configure AVD for kiosk use: webcam passthrough, performance tuning.
$avdDir = Join-Path $env:USERPROFILE ".android\avd\${AvdName}.avd"
$configIni = Join-Path $avdDir "config.ini"
if (Test-Path $configIni) {
    $content = Get-Content $configIni -Raw
    if ($content -notmatch "hw.camera.back") {
        Add-Content $configIni "`nhw.camera.back=webcam0`nhw.camera.front=webcam0`nhw.keyboard=yes`nhw.dPad=no"
    }
}

# Marker file indicating setup completed.
$marker = Join-Path $runtimeRoot ".runtime_ready"
Set-Content -Path $marker -Value (Get-Date -Format "o")

Write-Host ""
Write-Host "Setup complete." -ForegroundColor Green
Write-Host "Place worky_kiosko.apk in assets/apk/ before building, or install manually via adb."
Write-Host "You can now launch Worky Kiosko."
