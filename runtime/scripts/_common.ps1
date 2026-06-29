# Shared helpers for Android runtime management.

$ErrorActionPreference = "Stop"

function Get-RuntimeRoot {
    if ($env:WORKY_RUNTIME_ROOT) {
        return $env:WORKY_RUNTIME_ROOT
    }
    # Default: runtime folder next to the executable.
    $exeDir = Split-Path -Parent $PSScriptRoot
    return $exeDir
}

function Get-SdkRoot {
    $root = Get-RuntimeRoot
    $sdk = Join-Path $root "android-sdk"
    if (-not (Test-Path $sdk)) {
        throw "Android SDK not found at $sdk. Run setup_runtime.ps1 first."
    }
    return $sdk
}

function Get-AdbPath {
    $sdk = Get-SdkRoot
    return Join-Path $sdk "platform-tools\adb.exe"
}

function Get-EmulatorPath {
    $sdk = Get-SdkRoot
    return Join-Path $sdk "emulator\emulator.exe"
}

function Invoke-Adb {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    $adb = Get-AdbPath
    & $adb @Args
    if ($LASTEXITCODE -ne 0) {
        throw "adb failed: $Args"
    }
}

function Test-HypervisorAvailable {
    $whp = Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -ErrorAction SilentlyContinue
    $hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -ErrorAction SilentlyContinue
    return (($whp.State -eq "Enabled") -or ($hyperv.State -eq "Enabled"))
}

function Write-JsonResult {
    param([hashtable]$Data)
    $Data | ConvertTo-Json -Compress
}
