param(
    [string]$PackageName = "mx.worky.kioskoapp",
    [string]$ApkPath = ""
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"

$installed = & (Get-AdbPath) shell pm list packages $PackageName 2>&1
if ($installed -match $PackageName) {
    Write-Host "Package already installed: $PackageName"
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ApkPath)) {
    $bundled = Join-Path (Get-RuntimeRoot) "apk\worky_kiosko.apk"
    if (Test-Path $bundled) {
        $ApkPath = $bundled
    } else {
        throw "APK not found. Provide -ApkPath or place worky_kiosko.apk in runtime/apk/"
    }
}

if (-not (Test-Path $ApkPath)) {
    throw "APK file not found: $ApkPath"
}

Write-Host "Installing $ApkPath"
Invoke-Adb "install", "-r", "-g", $ApkPath
