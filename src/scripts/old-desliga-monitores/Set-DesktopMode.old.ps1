# =============================================================================
# Set-DesktopMode.ps1 — Ativa o modo Desktop
# Chamado por: Start-OnBoot.ps1 | Toggle-MachineMode.ps1 | manualmente
# Versao 2.0 — Com try/catch, logs sequenciais e validacao por etapa
# =============================================================================

Import-Module DisplayConfig -ErrorAction Stop
. "$PSScriptRoot\_config.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ativando modo Desktop..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# --- ETAPA 1: Enumeracao e diagnostico ---
try {
    Write-Host "[1/6] Enumerando monitores..." -ForegroundColor Yellow
    $tvDisplayId  = Get-TvDisplayId
    $allDisplays  = Get-DisplayInfo
    
    Write-Host "  [OK] TV Display ID: $tvDisplayId"
    Write-Host "  [OK] Displays encontrados:"
    $allDisplays | ForEach-Object {
        Write-Host "    - ID $($_.DisplayId): $($_.DisplayName) | Active: $($_.Active) | Primary: $($_.Primary) | Mode: $($_.Mode)"
    }
    
    # Validacoes basicas
    if (-not $tvDisplayId) {
        throw "Nao foi possivel identificar a TV (DisplayId nao encontrado para 'Beyond TV')"
    }
    
    $primaryDisplay   = $allDisplays | Where-Object { $_.DisplayId -eq $primaryMonitorId }
    $secondaryDisplay = $allDisplays | Where-Object { $_.DisplayId -eq $secondaryMonitorId }
    $tvDisplay        = $allDisplays | Where-Object { $_.DisplayId -eq $tvDisplayId }
    
    if (-not $primaryDisplay) {
        throw "Monitor primario (ID $primaryMonitorId) nao encontrado"
    }
    if (-not $secondaryDisplay) {
        throw "Monitor secundario (ID $secondaryMonitorId) nao encontrado"
    }
    if (-not $tvDisplay) {
        throw "TV (ID $tvDisplayId) nao encontrada"
    }
    
    # Validacao de integridade: alertar se algum monitor nao tem Mode
    if ([string]::IsNullOrWhiteSpace($primaryDisplay.Mode)) {
        Write-Host "  [AVISO] Monitor primario (ID $primaryMonitorId) nao tem Mode definido. Pode estar em estado invalido." -ForegroundColor Yellow
    }
    if ([string]::IsNullOrWhiteSpace($secondaryDisplay.Mode)) {
        Write-Host "  [AVISO] Monitor secundario (ID $secondaryMonitorId) nao tem Mode definido. Pode estar em estado invalido." -ForegroundColor Yellow
    }
    
    Write-Host "  [OK] Todas as telas estao acessiveis" -ForegroundColor Green
}
catch {
    Write-Host "  [ERRO] Erro na enumeracao: $_" -ForegroundColor Red
    exit 1
}

# --- ETAPA 2: Analisar configuracao atual ---
try {
    Write-Host "[2/6] Analisando configuracao atual..." -ForegroundColor Yellow
    
    $shouldSetPrimaryMode          = -not $primaryDisplay.Primary
    $shouldFixPrimaryRefreshRate   = $primaryDisplay.Mode   -notlike "*180 Hz*"
    $shouldFixSecondaryRefreshRate = $secondaryDisplay.Mode -notlike "*120 Hz*"
    
    Write-Host "  - Monitor primario como principal? $(-not $shouldSetPrimaryMode)"
    Write-Host "  - Monitor primario em 180 Hz? $(-not $shouldFixPrimaryRefreshRate)"
    Write-Host "  - Monitor secundario em 120 Hz? $(-not $shouldFixSecondaryRefreshRate)"
    Write-Host "  [OK] Analise concluida" -ForegroundColor Green
}
catch {
    Write-Host "  [ERRO] Erro na analise: $_" -ForegroundColor Red
    exit 1
}

# --- ETAPA 3: Reconfigurar topologia de monitores ---
if ($shouldSetPrimaryMode) {
    try {
        Write-Host "[3/6] Reconfigurando topologia de monitores..." -ForegroundColor Yellow
        
        Write-Host "  - Aguardando estabilizacao antes de reconfigurar (2 segundos)..."
        Start-Sleep -Seconds 2
        
        Write-Host "  - Habilitando monitor primario (ID $primaryMonitorId)..."
        Enable-Display -DisplayId $primaryMonitorId
        Start-Sleep -Milliseconds 1500
        
        # Validacao: verificar se foi habilitado
        $primaryAfterEnable = (Get-DisplayInfo | Where-Object { $_.DisplayId -eq $primaryMonitorId })
        if (-not $primaryAfterEnable.Active) {
            throw "Monitor primario (ID $primaryMonitorId) nao ficou ativo apos Enable-Display"
        }
        Write-Host "    [Validacao] Monitor primario agora esta ativo: $($primaryAfterEnable.Mode)"
        
        # Tentar habilitar monitor secundario com retry
        $secondaryRetryCount = 0
        $secondaryEnabled = $false
        while ($secondaryRetryCount -lt 3 -and -not $secondaryEnabled) {
            $secondaryRetryCount++
            Write-Host "  - Tentativa $secondaryRetryCount/3: Habilitando monitor secundario (ID $secondaryMonitorId)..."
            Enable-Display -DisplayId $secondaryMonitorId
            Start-Sleep -Milliseconds 1500
            
            $secondaryAfterEnable = (Get-DisplayInfo | Where-Object { $_.DisplayId -eq $secondaryMonitorId })
            if ($secondaryAfterEnable.Active) {
                $secondaryEnabled = $true
                Write-Host "    [Validacao] Monitor secundario agora esta ativo: $($secondaryAfterEnable.Mode)"
            }
            else {
                Write-Host "    [Retry] Monitor secundario ainda nao esta ativo. Aguardando e tentando novamente..."
                Start-Sleep -Seconds 1
            }
        }
        
        if (-not $secondaryEnabled) {
            Write-Host "  [AVISO] Monitor secundario (ID $secondaryMonitorId) nao conseguiu ficar ativo apos 3 tentativas" -ForegroundColor Yellow
            Write-Host "    Possveis causas:" -ForegroundColor Yellow
            Write-Host "      - Monitor desconectado ou cabo frouxo" -ForegroundColor Yellow
            Write-Host "      - Problema no driver de video" -ForegroundColor Yellow
            Write-Host "    Continuando com apenas o monitor primario..." -ForegroundColor Yellow
        }
        
        Write-Host "  - Desabilitando TV (ID $tvDisplayId) primeiro..."
        Disable-Display -DisplayId $tvDisplayId
        Start-Sleep -Milliseconds 1000
        
        Write-Host "  - Definindo monitor primario (ID $primaryMonitorId) como principal..."
        Set-DisplayPrimary -DisplayId $primaryMonitorId
        Start-Sleep -Milliseconds 1000
        
        # Validacao final
        $finalPrimary = (Get-DisplayInfo | Where-Object { $_.DisplayId -eq $primaryMonitorId })
        if (-not $finalPrimary.Primary) {
            throw "Monitor primario (ID $primaryMonitorId) nao ficou como principal"
        }
        Write-Host "    [Validacao] Monitor primario agora esta como principal"
        
        if ($secondaryEnabled) {
            Write-Host "  [OK] Topologia reconfigurada com sucesso" -ForegroundColor Green
        }
        else {
            Write-Host "  [OK] Topologia parcialmente reconfigurada (secundario indisponivel)" -ForegroundColor Green
        }
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
}
else {
    Write-Host "[3/6] Topologia ja esta correta, pulando..." -ForegroundColor Gray
}

# --- ETAPA 4: Ajustar taxas de atualizacao ---
if ($shouldFixPrimaryRefreshRate -or $shouldFixSecondaryRefreshRate) {
    try {
        Write-Host "[4/6] Ajustando taxas de atualizacao..." -ForegroundColor Yellow
        
        # Obter configuracao atual
        $displayConfig = Get-DisplayConfig
        
        if ($shouldFixPrimaryRefreshRate) {
            Write-Host "  - Ajustando monitor primario para 180 Hz..."
            $displayConfig | Set-DisplayRefreshRate -DisplayId $primaryMonitorId -RefreshRate 180 | Out-Null
            Start-Sleep -Milliseconds 300
        }
        
        if ($shouldFixSecondaryRefreshRate) {
            Write-Host "  - Ajustando posicao do secundario para X=1920, Y=-290..."
            $displayConfig | Set-DisplayPosition -DisplayId $secondaryMonitorId -XPosition 1920 -YPosition -290 -AsOffset | Out-Null
            Start-Sleep -Milliseconds 300
            
            Write-Host "  - Ajustando monitor secundario para 120 Hz..."
            $displayConfig | Set-DisplayRefreshRate -DisplayId $secondaryMonitorId -RefreshRate 120 | Out-Null
            Start-Sleep -Milliseconds 300
        }
        
        Write-Host "  - Aplicando configuracao de display..."
        $displayConfig | Use-DisplayConfig
        Start-Sleep -Milliseconds 1000
        
        Write-Host "  [OK] Taxas de atualizacao ajustadas com sucesso" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERRO] Erro ao ajustar taxas de atualizacao: $_" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "[4/6] Taxas de atualizacao ja estao corretas, pulando..." -ForegroundColor Gray
}

# --- ETAPA 5: Encerrar Steam ---
try {
    Write-Host "[5/6] Encerrando Steam..." -ForegroundColor Yellow
    $steamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
    
    if ($steamProcess) {
        Write-Host "  - Encerrando processo Steam..."
        Stop-Process -Name "steam" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Host "  [OK] Steam encerrado" -ForegroundColor Green
    }
    else {
        Write-Host "  - Steam nao estava em execucao" -ForegroundColor Gray
    }
}
catch {
    Write-Host "  [AVISO] Aviso ao encerrar Steam: $_" -ForegroundColor Yellow
}

# --- ETAPA 6: Configurar audio ---
try {
    Write-Host "[6/6] Definindo saida de audio para o Desktop..." -ForegroundColor Yellow
    
    $audioDevices = Get-AudioDevice -List
    $desktopAudio = $audioDevices | Where-Object { $_.Name -like $desktopAudioName }
    
    if ($desktopAudio) {
        Write-Host "  - Dispositivo encontrado: $($desktopAudio.Name)"
        $desktopAudio | Set-AudioDevice -DefaultOnly
        Write-Host "  [OK] Audio definido para Desktop" -ForegroundColor Green
    }
    else {
        Write-Host "  [AVISO] Dispositivo de audio '$desktopAudioName' nao encontrado" -ForegroundColor Yellow
        Write-Host "    Dispositivos disponiveis:"
        $audioDevices | Where-Object { $_.Type -eq "Playback" } | ForEach-Object {
            Write-Host "      - $($_.Name)"
        }
    }
}
catch {
    Write-Host "  [AVISO] Aviso ao configurar audio: $_" -ForegroundColor Yellow
}

# --- Salvar estado e finalizar ---
try {
    Write-Host ""
    Write-Host "Salvando estado no INI..." -ForegroundColor Yellow
    Save-MachineState "Desktop"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "[OK] Modo Desktop ativado com sucesso!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
}
catch {
    Write-Host "  [ERRO] Erro ao salvar estado: $_" -ForegroundColor Red
    exit 1
}
