param(
    [string]$PackageName = "mx.worky.kioskoapp",
    [string]$Permission = "android.permission.CAMERA"
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"

try {
    Invoke-Adb "shell", "pm", "grant", $PackageName, $Permission
    Write-Host "Granted $Permission to $PackageName"
} catch {
    Write-Warning "Could not grant $Permission : $_"
}
