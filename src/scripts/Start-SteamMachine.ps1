# =============================================================================
# Start-OnBoot.ps1 — Executado na inicialização do Windows
# Detecta se o controle 8BitDo (Xbox 360) está conectado e ativa o modo
# correspondente chamando o script específico.
# =============================================================================

Write-Host "Iniciando verificação de modo na inicialização..."

# --- Detecta controle 8BitDo (identificado como Xbox 360) ---
$connectedControllers = Get-PnpDevice |
    Where-Object { $_.FriendlyName -eq "Controlador XBOX 360 para Windows" } |
    Where-Object { $_.Status -eq "OK" }

if (@($connectedControllers) -like "*XBOX*") {
    Write-Host "Controle detectado! Iniciando modo Steam Machine..."
    & "$PSScriptRoot\Set-SteamMachineMode.ps1"
} else {
    Write-Host "Controle não detectado. Iniciando modo Desktop..."
    & "$PSScriptRoot\Set-DesktopMode.ps1"
}
