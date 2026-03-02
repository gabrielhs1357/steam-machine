# =============================================================================
# Toggle-MachineMode.ps1 — Alterna entre modo Desktop e Steam Machine
# Chamado manualmente via AutoHotkey
# =============================================================================

. "$PSScriptRoot\_config.ps1"

$currentState = Get-MachineState
Write-Host "Estado atual: $currentState"

if ($currentState -eq "Desktop") {
    Write-Host "Alternando para Steam Machine..."
    & "$PSScriptRoot\Set-SteamMachineMode.ps1"
} else {
    Write-Host "Alternando para Desktop..."
    & "$PSScriptRoot\Set-DesktopMode.ps1"
}
