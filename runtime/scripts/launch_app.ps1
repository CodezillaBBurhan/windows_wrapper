param(
    [string]$Component = "mx.worky.kioskoapp/.MainActivity"
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"

Invoke-Adb "shell", "am", "start", "-n", $Component, "-W"
Write-Host "Launched $Component"
