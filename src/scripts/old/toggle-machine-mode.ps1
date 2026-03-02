Import-Module DisplayConfig -ErrorAction Stop

# --- Configurações Iniciais ---
$tvAudioName = "*Beyond TV (NVIDIA High Definition Audio)*"
$desktopAudioName = "*Realtek(R) Audio*"

$primaryMonitorId = 1
$secondaryMonitorId = 2

Write-Host "Iniciando script de alternância de modo (Toggle)..."

$allDisplays = Get-DisplayInfo
$tvDisplayId = ($allDisplays | Where-Object { $_.DisplayName -eq "Beyond TV" }).DisplayId

# Define o caminho do arquivo INI para a mesma pasta onde o script está salvo
$iniPath = Join-Path -Path $PSScriptRoot -ChildPath "machine_state.ini"

# --- Leitura do Estado Atual ---
# Se o arquivo não existir ou estiver vazio, assumimos que o PC está no modo 'Desktop'
$currentState = "Desktop"

if (Test-Path $iniPath) {
    $content = Get-Content -Path $iniPath -Raw
    # Busca pela chave Mode=Valor ignorando espaços
    if ($content -match "Mode\s*=\s*(SteamMachine|Desktop)") {
        $currentState = $matches[1].Trim()
    }
}

Write-Host "Estado lido do INI: $currentState"

# --- Lógica de Toggle (Alternância) ---
if ($currentState -eq "Desktop") {
    $targetMode = "SteamMachine"
} else {
    $targetMode = "Desktop"
}

Write-Host "Trocando para o modo: $targetMode"

# --- Execução do Modo Alvo ---
if ($targetMode -eq "SteamMachine") {
    Write-Host "Configurando monitores para Steam Machine..."

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

} else {
    Write-Host "Configurando monitores para Desktop..."
    
    $shouldSetPrimaryMode = -not ($allDisplays | Where-Object { $_.DisplayId -eq $primaryMonitorId }).Primary
    $shouldFixPrimaryRefreshRate = ($allDisplays | Where-Object { $_.DisplayId -eq $primaryMonitorId }).Mode -notlike "*144 Hz*"
    $shouldFixSecondaryRefreshRate = ($allDisplays | Where-Object { $_.DisplayId -eq $secondaryMonitorId }).Mode -notlike "*120 Hz*"

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

# --- Gravação do Novo Estado ---
# Salva no formato INI padrão para facilitar a leitura por outras linguagens/scripts
$iniContent = @"
[State]
Mode=$targetMode
"@

$iniContent | Out-File -FilePath $iniPath -Encoding UTF8

Write-Host "Novo estado '$targetMode' salvo com sucesso no arquivo machine_state.ini."
Write-Host "Processo concluído!"