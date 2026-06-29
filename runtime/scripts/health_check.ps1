param(
    [ValidateSet("prerequisites", "device", "camera")]
    [string]$Mode = "device"
)

$ErrorActionPreference = "SilentlyContinue"
. "$PSScriptRoot\_common.ps1"

switch ($Mode) {
    "prerequisites" {
        $hypervisor = Test-HypervisorAvailable
        $root = Get-RuntimeRoot
        $sdkPath = Join-Path $root "android-sdk"
        $sdkExists = Test-Path $sdkPath
        Write-JsonResult @{
            hypervisor = $hypervisor
            sdkInstalled = $sdkExists
            runtimeReady = (Test-Path (Join-Path $root ".runtime_ready"))
        }
    }
    "device" {
        $adb = Get-AdbPath
        $state = & $adb get-state 2>&1
        $boot = & $adb shell getprop sys.boot_completed 2>&1
        $ready = ($state -eq "device") -and ($boot -match "1")
        Write-JsonResult @{ ready = $ready; state = "$state"; boot = "$boot" }
    }
    "camera" {
        $webcams = Get-PnpDevice -Class Camera -Status OK -ErrorAction SilentlyContinue
        $available = ($null -ne $webcams) -and ($webcams.Count -gt 0)
        Write-JsonResult @{ available = $available; count = @($webcams).Count }
    }
}
