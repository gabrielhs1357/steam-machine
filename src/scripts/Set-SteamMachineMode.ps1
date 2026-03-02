# =============================================================================
# Set-SteamMachineMode.ps1 — Ativa o modo Steam Machine
# Chamado por: Start-OnBoot.ps1 | Toggle-MachineMode.ps1 | manualmente
# =============================================================================

Import-Module DisplayConfig -ErrorAction Stop
. "$PSScriptRoot\_config.ps1"

Write-Host "Ativando modo Steam Machine..."

$tvDisplayId = Get-TvDisplayId

# --- Configuração dos monitores ---
Write-Host "Configurando monitores..."
Enable-Display  -DisplayId $tvDisplayId
Set-DisplayPrimary -DisplayId $tvDisplayId
Disable-Display -DisplayId $primaryMonitorId
Disable-Display -DisplayId $secondaryMonitorId

Write-Host "Ajustando resolução e taxa de atualização..."
Start-Sleep -Seconds 3

Get-DisplayConfig |
    Set-DisplayResolution -DisplayId $tvDisplayId -Width 3840 -Height 2160 |
    Set-DisplayRefreshRate -DisplayId $tvDisplayId -RefreshRate 60 |
    Use-DisplayConfig

# --- Áudio ---
Write-Host "Definindo saída de áudio para a TV..."
Get-AudioDevice -List |
    Where-Object { $_.Name -like $tvAudioName } |
    Set-AudioDevice -DefaultOnly

# --- Steam Big Picture ---
Write-Host "Iniciando Steam em modo Big Picture..."
Start-Process -FilePath "C:\Games\Steam\steam.exe" -ArgumentList "steam://open/bigpicture"

# --- Salva o estado ---
Save-MachineState "Console"

Write-Host "Modo Steam Machine ativado com sucesso!"
