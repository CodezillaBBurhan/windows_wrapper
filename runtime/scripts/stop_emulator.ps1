$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_common.ps1"

try {
    Invoke-Adb "emu", "kill"
} catch {
    Get-Process -Name "qemu-system*" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "emulator" -ErrorAction SilentlyContinue | Stop-Process -Force
}
