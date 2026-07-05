# =============================================================================
# Set-DesktopMode.ps1 — Ativa o modo Desktop (Versão Linear e Limpa)
# =============================================================================

Import-Module DisplayConfig -ErrorAction Stop
. "$PSScriptRoot\_config.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ativando modo Desktop..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# --- PASSO 5: Limpeza (Steam e Áudio) ---
Write-Host "[1/5] Executando limpeza do ambiente (Steam e Áudio)..." -ForegroundColor Yellow

# Tira a Steam do Modo Big Picture sem matar o processo
Write-Host "  - Restaurando a Steam para o modo Desktop..." -ForegroundColor Gray
try {
    Start-Process "steam://close/bigpicture"
    Start-Sleep -Seconds 1
} catch {
    Write-Host "  [AVISO] Falha ao enviar comando para a Steam: $_" -ForegroundColor DarkYellow
}

# Configura o áudio para a mesa
try {
    $desktopAudio = Get-AudioDevice -List | Where-Object { $_.Name -like $desktopAudioName }
    if ($desktopAudio) {
        $desktopAudio | Set-AudioDevice -DefaultOnly
        Write-Host "  - Áudio redirecionado para: $($desktopAudio.Name)" -ForegroundColor Gray
    }
    else {
        Write-Host "  [AVISO] Dispositivo de áudio '$desktopAudioName' não encontrado." -ForegroundColor DarkYellow
    }
}
catch {
    Write-Host "  [AVISO] Falha ao configurar o áudio: $_" -ForegroundColor DarkYellow
}

try {
    # Busca o ID da TV
    $tvDisplayId = Get-TvDisplayId

    # --- PASSO 1: Ligar tudo que precisa ligar ---
    Write-Host "[2/5] Ligando monitores da mesa..." -ForegroundColor Yellow
    Enable-Display -DisplayId $primaryMonitorId
    Enable-Display -DisplayId $secondaryMonitorId
    Start-Sleep -Seconds 5

    # Validação de segurança (Fail-Fast): Verifica se o primário ligou
    $primaryState = Get-DisplayInfo | Where-Object { $_.DisplayId -eq $primaryMonitorId }
    if (-not $primaryState.Active) {
        throw "Falha crítica: Monitor primário (180Hz) não respondeu. Abortando para evitar tela preta."
    }
    Write-Host "  [OK] Monitores responderam" -ForegroundColor Green

    # --- PASSO 2: Passar a coroa ---
    Write-Host "[3/5] Definindo monitor primário como principal..." -ForegroundColor Yellow
    Set-DisplayPrimary -DisplayId $primaryMonitorId
    Start-Sleep -Seconds 5
    Write-Host "  [OK] Coroa transferida" -ForegroundColor Green

    # --- PASSO 3: Desligar o que sobrou ---
    Write-Host "[4/5] Desligando a TV..." -ForegroundColor Yellow
    Disable-Display -DisplayId $tvDisplayId
    Start-Sleep -Seconds 5
    Write-Host "  [OK] TV desativada" -ForegroundColor Green

    # --- PASSO 4: Força Bruta de Configuração ---
    Write-Host "[5/5] Aplicando taxas de atualização e posição..." -ForegroundColor Yellow
    $displayConfig = Get-DisplayConfig
    
    # Monitor Primário
    $displayConfig | Set-DisplayRefreshRate -DisplayId $primaryMonitorId -RefreshRate 180 | Out-Null
    
    # Monitor Secundário
    $displayConfig | Set-DisplayPosition -DisplayId $secondaryMonitorId -XPosition 1920 -YPosition -290 -AsOffset | Out-Null
    $displayConfig | Set-DisplayRefreshRate -DisplayId $secondaryMonitorId -RefreshRate 120 | Out-Null
    
    # Aplica todas as configurações de vídeo de uma vez
    $displayConfig | Use-DisplayConfig
    Start-Sleep -Seconds 5
    Write-Host "  [OK] 180Hz e 120Hz aplicados" -ForegroundColor Green

}
catch {
    Write-Host "  [ERRO CRÍTICO] Falha na topologia de vídeo: $_" -ForegroundColor Red
    exit 1
}

# Salva o estado silenciosamente
try {
    Save-MachineState "Desktop"
}
catch { }

Write-Host "========================================" -ForegroundColor Green
Write-Host "[OK] Modo Desktop ativado com sucesso!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green