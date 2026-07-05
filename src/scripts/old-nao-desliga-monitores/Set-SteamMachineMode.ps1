# =============================================================================
# Set-SteamMachineMode.ps1 — Ativa o modo Steam Machine (Versao Simplificada)
# =============================================================================

Import-Module DisplayConfig -ErrorAction SilentlyContinue
. "$PSScriptRoot\_config.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ativando modo Steam Machine (Sala)..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# --- 1. Definir TV como Principal ---
Write-Host "[1/3] Definindo TV como tela principal..." -ForegroundColor Yellow
try {
    # Mantivemos a sua funcao Get-TvDisplayId que ja busca o ID correto
    $tvDisplayId = Get-TvDisplayId
    Set-DisplayPrimary -DisplayId $tvDisplayId
    Write-Host "  [OK] TV definida como principal!" -ForegroundColor Green
} catch {
    Write-Host "  [ERRO] Falha ao definir a TV como principal: $_" -ForegroundColor Red
}

# --- 2. Configurar Saída de Áudio ---
Write-Host "[2/3] Redirecionando som para a TV (Beyond)..." -ForegroundColor Yellow
try {
    # Busca o dispositivo usando a palavra "Beyond" ou a variavel antiga do config
    $tvAudio = Get-AudioDevice -List | Where-Object { $_.Name -match "Beyond" -or $_.Name -like $tvAudioName }
    
    if ($tvAudio) {
        $tvAudio | Set-AudioDevice -DefaultOnly
        Write-Host "  [OK] Audio redirecionado para a TV." -ForegroundColor Green
    } else {
        Write-Host "  [AVISO] Dispositivo 'Beyond' não encontrado." -ForegroundColor DarkYellow
    }
} catch {
    Write-Host "  [ERRO] Falha ao alterar o audio: $_" -ForegroundColor Red
}

# --- 3. Iniciar Steam em Big Picture ---
Write-Host "[3/3] Iniciando Steam em modo Big Picture..." -ForegroundColor Yellow
try {
    # Usa o mesmo caminho validado do seu script original[cite: 2]
    $steamPath = "C:\Games\Steam\steam.exe"
    
    if (Test-Path $steamPath) {
        Start-Process -FilePath $steamPath -ArgumentList "steam://open/bigpicture"
        Write-Host "  [OK] Steam chamado para a sala!" -ForegroundColor Green
    } else {
        # Fallback de seguranca caso o executavel mude de pasta no futuro
        Start-Process "steam://open/bigpicture"
        Write-Host "  [OK] Steam chamado via URI padrão do Windows!" -ForegroundColor Green
    }
} catch {
    Write-Host "  [ERRO] Falha ao iniciar a Steam: $_" -ForegroundColor Red
}

# --- Salvar estado ---
try {
    # Mantem a persistencia de estado para compatibilidade com outros scripts[cite: 2]
    Save-MachineState "Console"
} catch { }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pronto para jogar no sofá!" -ForegroundColor Cyan
Start-Sleep -Seconds 2