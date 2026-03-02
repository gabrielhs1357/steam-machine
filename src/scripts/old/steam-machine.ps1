Import-Module DisplayConfig -ErrorAction Stop

# get-help Set-DisplayPosition
# Get-Command -Module DisplayConfig

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

$RegPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
$RegValues = (Get-ItemProperty -Path $RegPath).Settings

# Define o caminho do arquivo INI na mesma pasta do script
$iniPath = Join-Path -Path $PSScriptRoot -ChildPath "machine_state.ini"
$targetMode = "Unknown"

# Procura pelo controle 8BitDo (identificado como controle de Xbox 360)
$ConnectedControllers = Get-PnpDevice | `
    where {$_.FriendlyName -eq "Controlador XBOX 360 para Windows"} | `
    where {$_.status -eq "OK"}

# Se o controle estiver ligado ativa o modo Steam Machine
if (@($ConnectedControllers) -like "*XBOX*"){
    Write-host "Controle detectado! Iniciando modo Steam Machine..."
    $targetMode = "SteamMachine"

    Write-Host "Configurando monitores..."

    Enable-Display -DisplayId $tvDisplayId
    Set-DisplayPrimary -DisplayId $tvDisplayId
    Disable-Display -DisplayId $primaryMonitorId
    Disable-Display -DisplayId $secondaryMonitorId

    # Write-Host "Ajustando taxas de atualização em 3 segundos..."
    # Start-Sleep -s 3

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
    $targetMode = "Desktop"

    if ($shouldSetPrimaryMode) {
        Write-Host "Monitor primário não está definido corretamente. Corrigindo..."

        Enable-Display -DisplayId $primaryMonitorId
        Enable-Display -DisplayId $secondaryMonitorId
        Set-DisplayPrimary -DisplayId $primaryMonitorId
        Disable-Display -DisplayId $tvDisplayId
    }
    
    if ($shouldFixPrimaryRefreshRate -or $shouldFixSecondaryRefreshRate) {
        Write-Host "Taxas de atualização dos monitores estão incorretas. Corrigindo..."

        Get-DisplayConfig |
            Set-DisplayRefreshRate -DisplayId $primaryMonitorId -RefreshRate 144 |
            Set-DisplayPosition -DisplayId $secondaryMonitorId -XPosition 1920 -YPosition -290 -AsOffset |
            Set-DisplayRefreshRate -DisplayId $secondaryMonitorId -RefreshRate 120 |
            Use-DisplayConfig
    }

    # Ajusta a saída de áudio para o Desktop
    Get-AudioDevice -List | Where-Object {$_.Name -like $desktopAudioName} | Set-AudioDevice -DefaultOnly
}

# Gravação do Estado Atual
$iniContent = @"
[State]
Mode=$targetMode
"@

# Sobrescreve o arquivo com o novo estado
$iniContent | Out-File -FilePath $iniPath -Encoding UTF8
Write-Host "Estado '$targetMode' salvo com sucesso no arquivo machine_state.ini."

# Read-Host -Prompt "Press Enter to exit"