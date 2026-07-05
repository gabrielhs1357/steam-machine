# =============================================================================
# Set-SteamMachineMode.ps1 — Ativa o modo Steam Machine (Versão Linear e Limpa)
# =============================================================================

Import-Module DisplayConfig -ErrorAction Stop
. "$PSScriptRoot\_config.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ativando modo Steam Machine..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    # Busca o ID da TV
    $tvDisplayId = Get-TvDisplayId

    # --- PASSO 1: Ligar tudo que precisa ligar ---
    Write-Host "[1/5] Ligando a TV..." -ForegroundColor Yellow
    Enable-Display -DisplayId $tvDisplayId
    Start-Sleep -Seconds 5

    # Validação de segurança (Fail-Fast): Verifica se a TV ligou
    $tvState = Get-DisplayInfo | Where-Object { $_.DisplayId -eq $tvDisplayId }
    if (-not $tvState.Active) {
        throw "Falha crítica: TV não respondeu. Abortando para evitar tela preta na mesa."
    }
    Write-Host "  [OK] TV respondeu" -ForegroundColor Green

    # --- PASSO 2: Passar a coroa ---
    Write-Host "[2/5] Definindo TV como principal..." -ForegroundColor Yellow
    Set-DisplayPrimary -DisplayId $tvDisplayId
    Start-Sleep -Seconds 5
    Write-Host "  [OK] Coroa transferida para a TV" -ForegroundColor Green

    # --- PASSO 3: Desligar o que sobrou ---
    Write-Host "[3/5] Desligando os monitores da mesa..." -ForegroundColor Yellow
    Disable-Display -DisplayId $primaryMonitorId
    Disable-Display -DisplayId $secondaryMonitorId
    Start-Sleep -Seconds 5
    Write-Host "  [OK] Monitores desativados" -ForegroundColor Green

    # --- PASSO 4: Força Bruta de Configuração ---
    Write-Host "[4/5] Aplicando resolução e taxa de atualização..." -ForegroundColor Yellow
    $displayConfig = Get-DisplayConfig
    
    # TV (Força 4K e 60Hz)
    $displayConfig | Set-DisplayResolution -DisplayId $tvDisplayId -Width 3840 -Height 2160 | Out-Null
    $displayConfig | Set-DisplayRefreshRate -DisplayId $tvDisplayId -RefreshRate 60 | Out-Null
    
    # Aplica todas as configurações de vídeo de uma vez
    $displayConfig | Use-DisplayConfig
    # Start-Sleep -Seconds 5
    Write-Host "  [OK] 4K e 60Hz aplicados" -ForegroundColor Green

}
catch {
    Write-Host "  [ERRO CRÍTICO] Falha na topologia de vídeo: $_" -ForegroundColor Red
    exit 1
}

# --- PASSO 5: Inicialização (Steam e Áudio) ---
Write-Host "[5/5] Executando inicialização do ambiente (Steam e Áudio)..." -ForegroundColor Yellow

# Configura o áudio para a TV
try {
    $tvAudio = Get-AudioDevice -List | Where-Object { $_.Name -like $tvAudioName }
    if ($tvAudio) {
        $tvAudio | Set-AudioDevice -DefaultOnly
        Write-Host "  - Áudio redirecionado para: $($tvAudio.Name)" -ForegroundColor Gray
    } else {
        Write-Host "  [AVISO] Dispositivo de áudio '$tvAudioName' não encontrado." -ForegroundColor DarkYellow
    }
}
catch {
    Write-Host "  [AVISO] Falha ao configurar o áudio: $_" -ForegroundColor DarkYellow
}

# Inicia a Steam em Big Picture silenciosamente
Write-Host "  - Chamando Steam em modo Big Picture..." -ForegroundColor Gray
try {
    $steamPath = "C:\Games\Steam\steam.exe"
    if (Test-Path $steamPath) {
        Start-Process -FilePath $steamPath -ArgumentList "steam://open/bigpicture"
    } else {
        # Fallback caso o caminho mude
        Start-Process "steam://open/bigpicture"
    }
} catch {
    Write-Host "  [AVISO] Falha ao chamar a Steam: $_" -ForegroundColor DarkYellow
}

# Salva o estado silenciosamente
try {
    Save-MachineState "Console"
} catch { }

Write-Host "========================================" -ForegroundColor Green
Write-Host "[OK] Modo Steam Machine ativado com sucesso!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green