# =============================================================================
# Set-SteamMachineMode.ps1 — Ativa o modo Steam Machine
# Chamado por: Start-OnBoot.ps1 | Toggle-MachineMode.ps1 | manualmente
# Versao 2.0 — Com try/catch, logs sequenciais e validacao por etapa
# =============================================================================

Import-Module DisplayConfig -ErrorAction Stop
. "$PSScriptRoot\_config.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ativando modo Steam Machine..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# --- ETAPA 1: Enumeracao e diagnostico ---
try {
    Write-Host "[1/5] Enumerando monitores..." -ForegroundColor Yellow
    $tvDisplayId = Get-TvDisplayId
    $allDisplays = Get-DisplayInfo
    
    Write-Host "  [OK] TV Display ID: $tvDisplayId"
    Write-Host "  [OK] Displays encontrados:"
    $allDisplays | ForEach-Object {
        Write-Host "    - ID $($_.DisplayId): $($_.DisplayName) | Primary: $($_.Primary) | Mode: $($_.Mode)"
    }
    
    # Validacoes basicas
    if (-not $tvDisplayId) {
        throw "Nao foi possivel identificar a TV (DisplayId nao encontrado para 'Beyond TV')"
    }
    
    $primaryDisplay   = $allDisplays | Where-Object { $_.DisplayId -eq $primaryMonitorId }
    $secondaryDisplay = $allDisplays | Where-Object { $_.DisplayId -eq $secondaryMonitorId }
    $tvDisplay        = $allDisplays | Where-Object { $_.DisplayId -eq $tvDisplayId }
    
    if (-not $tvDisplay) {
        throw "TV (ID $tvDisplayId) nao encontrada"
    }
    if (-not $primaryDisplay) {
        throw "Monitor primario (ID $primaryMonitorId) nao encontrado"
    }
    if (-not $secondaryDisplay) {
        throw "Monitor secundario (ID $secondaryMonitorId) nao encontrado"
    }
    
    Write-Host "  [OK] Todas as telas estao acessiveis" -ForegroundColor Green
}
catch {
    Write-Host "  [ERRO] Erro na enumeracao: $_" -ForegroundColor Red
    exit 1
}

# --- ETAPA 2: Reconfigurar topologia de monitores ---
try {
    Write-Host "[2/5] Reconfigurando topologia de monitores..." -ForegroundColor Yellow
    
    Write-Host "  - Aguardando estabilizacao antes de reconfigurar (2 segundos)..."
    Start-Sleep -Seconds 2
    
    Write-Host "  - Habilitando TV (ID $tvDisplayId)..."
    Enable-Display -DisplayId $tvDisplayId
    Start-Sleep -Milliseconds 1500
    
    # Validacao: verificar se foi habilitada
    $tvAfterEnable = (Get-DisplayInfo | Where-Object { $_.DisplayId -eq $tvDisplayId })
    if (-not $tvAfterEnable.Active) {
        throw "TV (ID $tvDisplayId) nao ficou ativa apos Enable-Display"
    }
    Write-Host "    [Validacao] TV agora esta ativa: $($tvAfterEnable.Mode)"
    
    Write-Host "  - Desabilitando monitor primario (ID $primaryMonitorId)..."
    Disable-Display -DisplayId $primaryMonitorId
    Start-Sleep -Milliseconds 1000
    
    # Tentar desabilitar monitor secundario com retry
    $secondaryRetryCount = 0
    $secondaryDisabled = $false
    while ($secondaryRetryCount -lt 3 -and -not $secondaryDisabled) {
        $secondaryRetryCount++
        Write-Host "  - Tentativa $secondaryRetryCount/3: Desabilitando monitor secundario (ID $secondaryMonitorId)..."
        Disable-Display -DisplayId $secondaryMonitorId
        Start-Sleep -Milliseconds 1000
        
        $secondaryAfterDisable = (Get-DisplayInfo | Where-Object { $_.DisplayId -eq $secondaryMonitorId })
        if (-not $secondaryAfterDisable.Active) {
            $secondaryDisabled = $true
            Write-Host "    [Validacao] Monitor secundario agora esta desativo"
        }
        else {
            Write-Host "    [Retry] Monitor secundario ainda esta ativo. Tentando novamente..."
            Start-Sleep -Milliseconds 1000
        }
    }
    
    if (-not $secondaryDisabled) {
        Write-Host "  [AVISO] Monitor secundario (ID $secondaryMonitorId) nao conseguiu desativar apos 3 tentativas" -ForegroundColor Yellow
        Write-Host "    Problema pode estar no hardware ou driver. Continuando mesmo assim..." -ForegroundColor Yellow
    }
    
    Write-Host "  - Definindo TV como monitor principal..."
    Set-DisplayPrimary -DisplayId $tvDisplayId
    Start-Sleep -Milliseconds 1000
    
    # Validacao final
    $finalPrimary = (Get-DisplayInfo | Where-Object { $_.DisplayId -eq $tvDisplayId })
    if (-not $finalPrimary.Primary) {
        throw "TV (ID $tvDisplayId) nao ficou como principal"
    }
    Write-Host "    [Validacao] TV agora esta como principal"
    
    Write-Host "  [OK] Topologia reconfigurada com sucesso" -ForegroundColor Green
}
catch {
    Write-Host "  [ERRO] Erro ao reconfigurar topologia: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "  [DEBUG] Estado atual dos monitores:"
    Get-DisplayInfo | ForEach-Object {
        Write-Host "    - ID $($_.DisplayId): $($_.DisplayName) | Active: $($_.Active) | Primary: $($_.Primary) | Mode: $($_.Mode)"
    }
    exit 1
}

# --- ETAPA 3: Aguardar estabilizacao e ajustar resolucao ---
try {
    Write-Host "[3/5] Ajustando resolucao e taxa de atualizacao..." -ForegroundColor Yellow
    
    Write-Host "  - Aguardando estabilizacao do monitor (3 segundos)..."
    Start-Sleep -Seconds 3
    
    Write-Host "  - Aplicando 3840x2160@60Hz na TV..."
    $displayConfig = Get-DisplayConfig
    $displayConfig | Set-DisplayResolution -DisplayId $tvDisplayId -Width 3840 -Height 2160 | Out-Null
    Start-Sleep -Milliseconds 300
    
    $displayConfig | Set-DisplayRefreshRate -DisplayId $tvDisplayId -RefreshRate 60 | Out-Null
    Start-Sleep -Milliseconds 300
    
    $displayConfig | Use-DisplayConfig
    Start-Sleep -Milliseconds 1000
    
    Write-Host "  [OK] Resolucao e taxa de atualizacao aplicadas com sucesso" -ForegroundColor Green
}
catch {
    Write-Host "  [ERRO] Erro ao ajustar resolucao: $_" -ForegroundColor Red
    exit 1
}

# --- ETAPA 4: Configurar audio ---
try {
    Write-Host "[4/5] Definindo saida de audio para a TV..." -ForegroundColor Yellow
    
    $audioDevices = Get-AudioDevice -List
    $tvAudio = $audioDevices | Where-Object { $_.Name -like $tvAudioName }
    
    if ($tvAudio) {
        Write-Host "  - Dispositivo encontrado: $($tvAudio.Name)"
        $tvAudio | Set-AudioDevice -DefaultOnly
        Write-Host "  [OK] Audio definido para TV" -ForegroundColor Green
    }
    else {
        Write-Host "  [AVISO] Dispositivo de audio '$tvAudioName' nao encontrado" -ForegroundColor Yellow
        Write-Host "    Dispositivos disponiveis:"
        $audioDevices | Where-Object { $_.Type -eq "Playback" } | ForEach-Object {
            Write-Host "      - $($_.Name)"
        }
    }
}
catch {
    Write-Host "  [AVISO] Aviso ao configurar audio: $_" -ForegroundColor Yellow
}

# --- ETAPA 5: Iniciar Steam em Big Picture ---
try {
    Write-Host "[5/5] Iniciando Steam em modo Big Picture..." -ForegroundColor Yellow
    
    $steamPath = "C:\Games\Steam\steam.exe"
    
    if (Test-Path $steamPath) {
        Write-Host "  - Iniciando Steam com 'steam://open/bigpicture'..."
        Start-Process -FilePath $steamPath -ArgumentList "steam://open/bigpicture"
        Start-Sleep -Seconds 2
        Write-Host "  [OK] Steam iniciado" -ForegroundColor Green
    }
    else {
        Write-Host "  [ERRO] Steam nao encontrado em '$steamPath'" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "  [ERRO] Erro ao iniciar Steam: $_" -ForegroundColor Red
    exit 1
}

# --- Salvar estado e finalizar ---
try {
    Write-Host ""
    Write-Host "Salvando estado no INI..." -ForegroundColor Yellow
    Save-MachineState "Console"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "[OK] Modo Steam Machine ativado com sucesso!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
}
catch {
    Write-Host "  [ERRO] Erro ao salvar estado: $_" -ForegroundColor Red
    exit 1
}
