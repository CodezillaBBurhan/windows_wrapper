param(
    [string]$AvdName = "WorkyKiosk"
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"

$emulator = Get-EmulatorPath
$sdkRoot = Get-SdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot
$env:ANDROID_HOME = $sdkRoot

# Start emulator with webcam passthrough and optimized settings for kiosk embedding.
$args = @(
    "-avd", $AvdName,
    "-camera-back", "webcam0",
    "-camera-front", "webcam0",
    "-gpu", "host",
    "-no-snapshot-save",
    "-no-boot-anim",
    "-netdelay", "none",
    "-netspeed", "full"
)

Write-Host "Starting emulator: $AvdName"
Start-Process -FilePath $emulator -ArgumentList $args -WorkingDirectory (Split-Path $emulator)

# Wait for the emulator process to appear and record its PID for window embedding.
$pidFile = Join-Path (Get-RuntimeRoot) ".emulator.pid"
$deadline = (Get-Date).AddMinutes(3)
$emulatorPid = $null

while ((Get-Date) -lt $deadline -and -not $emulatorPid) {
    Start-Sleep -Seconds 2
    $proc = Get-Process -Name "qemu-system-x86_64", "emulator" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($proc) {
        $emulatorPid = $proc.Id
    }
}

if ($emulatorPid) {
    Set-Content -Path $pidFile -Value $emulatorPid
    Write-Output "{ `"pid`": $emulatorPid }"
} else {
    throw "Emulator process did not start within timeout."
}
