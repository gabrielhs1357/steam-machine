# =============================================================================
# Set-DesktopMode.ps1 — Ativa o modo Desktop
# Chamado por: Start-OnBoot.ps1 | Toggle-MachineMode.ps1 | manualmente
# =============================================================================

Import-Module DisplayConfig -ErrorAction Stop
. "$PSScriptRoot\_config.ps1"

Write-Host "Ativando modo Desktop..."

$tvDisplayId  = Get-TvDisplayId
$allDisplays  = Get-DisplayInfo

$shouldSetPrimaryMode          = -not ($allDisplays | Where-Object { $_.DisplayId -eq $primaryMonitorId }).Primary
$shouldFixPrimaryRefreshRate   = ($allDisplays | Where-Object { $_.DisplayId -eq $primaryMonitorId }).Mode   -notlike "*144 Hz*"
$shouldFixSecondaryRefreshRate = ($allDisplays | Where-Object { $_.DisplayId -eq $secondaryMonitorId }).Mode -notlike "*120 Hz*"

# --- Configuração dos monitores ---
if ($shouldSetPrimaryMode) {
    Write-Host "Monitor primário não está definido corretamente. Corrigindo..."

    Enable-Display    -DisplayId $primaryMonitorId
    Enable-Display    -DisplayId $secondaryMonitorId
    Set-DisplayPrimary -DisplayId $primaryMonitorId
    Disable-Display   -DisplayId $tvDisplayId
}

if ($shouldFixPrimaryRefreshRate -or $shouldFixSecondaryRefreshRate) {
    Write-Host "Taxas de atualização dos monitores estão incorretas. Corrigindo..."

    Get-DisplayConfig |
        Set-DisplayRefreshRate -DisplayId $primaryMonitorId   -RefreshRate 144 |
        Set-DisplayPosition    -DisplayId $secondaryMonitorId -XPosition 1920 -YPosition -290 -AsOffset |
        Set-DisplayRefreshRate -DisplayId $secondaryMonitorId -RefreshRate 120 |
        Use-DisplayConfig
}

# --- Áudio ---
Write-Host "Definindo saída de áudio para o Desktop..."
Get-AudioDevice -List |
    Where-Object { $_.Name -like $desktopAudioName } |
    Set-AudioDevice -DefaultOnly

# --- Salva o estado ---
Save-MachineState "Desktop"

Write-Host "Modo Desktop ativado com sucesso!"
