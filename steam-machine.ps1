Import-Module DisplayConfig -ErrorAction Stop

$tvAudioName = "*Beyond TV (NVIDIA High Definition Audio)*"
$desktopAudioName = "*Realtek(R) Audio*"

$allDisplays = Get-DisplayInfo

Write-Host "Iniciando script..."

$tvDisplayId = ($allDisplays | Where-Object { $_.DisplayName -eq "Beyond TV" }).DisplayId
$primaryMonitorId = 1
$secondaryMonitorId = 2

$shouldSetPrimaryMode = -not ($allDisplays | Where-Object { $_.DisplayId -eq $primaryMonitorId }).Primary
$shouldFixPrimaryRefreshRate = ($allDisplays | Where-Object { $_.DisplayId -eq $primaryMonitorId }).Mode -notlike "*144 Hz*"
$shouldFixSecondaryRefreshRate = ($allDisplays | Where-Object { $_.DisplayId -eq $secondaryMonitorId }).Mode -notlike "*120 Hz*"

Write-Host "TV ID: $tvDisplayId | Primário ID: $primaryMonitorId | Secundário ID: $secondaryMonitorId"

# Procura pelo controle 8BitDo (identificado como controle de Xbox 360)
$ConnectedControllers = Get-PnpDevice | `
    where {$_.FriendlyName -eq "Controlador XBOX 360 para Windows"} | `
    where {$_.status -eq "OK"}

# Se o controle estiver ligado ativa o modo Steam Machine
if (@($ConnectedControllers) -like "*XBOX*"){
    Write-host "Controle detectado! Iniciando modo Steam Machine..."
    
    Write-Host "Configurando monitores em 3 segundos..."

    Start-Sleep -s 3

    Enable-Display -DisplayId $tvDisplayId
    Set-DisplayPrimary -DisplayId $tvDisplayId
    Disable-Display -DisplayId $primaryMonitorId
    Disable-Display -DisplayId $secondaryMonitorId

    Write-Host "Ajustando taxas de atualização em 3 segundos..."
    Start-Sleep -s 3

    Get-DisplayConfig |
        Set-DisplayResolution -DisplayId $tvDisplayId -Width 3840 -Height 2160 |
        Set-DisplayRefreshRate -DisplayId $tvDisplayId -RefreshRate 60 |
        Use-DisplayConfig

    # Ajusta a saída de áudio para a TV
    Get-AudioDevice -List | Where-Object {$_.Name -like $tvAudioName} | Set-AudioDevice -DefaultOnly
    
    # Inicia o Steam em modo Big Picture
    Start-Process -FilePath "C:\Games\Steam\steam.exe" -ArgumentList "steam://open/bigpicture"
}
else {
    Write-host "Controle não detectado! Iniciando modo Desktop..."

    if ($shouldSetPrimaryMode) {
        Write-Host "Monitor primário não está definido corretamente. Corrigindo..."
        Start-Sleep -s 3

        Enable-Display -DisplayId $primaryMonitorId
        Enable-Display -DisplayId $secondaryMonitorId
        Set-DisplayPrimary -DisplayId $primaryMonitorId
    }
    
    if ($shouldFixPrimaryRefreshRate -or $shouldFixSecondaryRefreshRate) {
        Write-Host "Taxas de atualização dos monitores estão incorretas. Corrigindo..."
        Start-Sleep -s 3

        Get-DisplayConfig |
            Set-DisplayRefreshRate -DisplayId $primaryMonitorId -RefreshRate 144 |
            Set-DisplayPosition -DisplayId $secondaryMonitorId -XPosition 1920 -YPosition -290 |
            Set-DisplayRefreshRate -DisplayId $secondaryMonitorId -RefreshRate 120 |
            Use-DisplayConfig
    }

    # Ajusta a saída de áudio para o Desktop
    Get-AudioDevice -List | Where-Object {$_.Name -like $desktopAudioName} | Set-AudioDevice -DefaultOnly
}

Read-Host -Prompt "Press Enter to exit"
