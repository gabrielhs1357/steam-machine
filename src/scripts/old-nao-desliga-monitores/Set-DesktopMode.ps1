# =============================================================================
# Set-DesktopMode.ps1 — Ativa o modo Desktop (Versao Simplificada)
# =============================================================================

Import-Module DisplayConfig -ErrorAction SilentlyContinue
. "$PSScriptRoot\_config.ps1"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Ativando modo Desktop (Mesa)..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# --- 1. Definir Monitor Principal ---
Write-Host "[1/3] Definindo monitor da mesa como principal..." -ForegroundColor Yellow
try {
    # Usa a variavel $primaryMonitorId que ja existe no seu _config.ps1
    Set-DisplayPrimary -DisplayId $primaryMonitorId
    Write-Host "  [OK] Monitor definido como principal!" -ForegroundColor Green
} catch {
    Write-Host "  [ERRO] Falha ao definir monitor: $_" -ForegroundColor Red
}

# --- 2. Configurar Saída de Áudio ---
Write-Host "[2/3] Redirecionando som para Realtek Audio..." -ForegroundColor Yellow
try {
    # Busca qualquer dispositivo que contenha "Realtek" no nome e seta como padrao
    $realtekAudio = Get-AudioDevice -List | Where-Object { $_.Name -match "Realtek" }
    
    if ($realtekAudio) {
        $realtekAudio | Set-AudioDevice -DefaultOnly
        Write-Host "  [OK] Audio redirecionado para a caixinha de som." -ForegroundColor Green
    } else {
        Write-Host "  [AVISO] Dispositivo 'Realtek' não encontrado." -ForegroundColor DarkYellow
    }
} catch {
    Write-Host "  [ERRO] Falha ao alterar o audio: $_" -ForegroundColor Red
}

# --- 3. Encerrar a Steam ---
Write-Host "[3/3] Fechando a Steam..." -ForegroundColor Yellow
try {
    $steamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
    if ($steamProcess) {
        Stop-Process -Name "steam" -Force
        Write-Host "  [OK] Steam encerrada com sucesso." -ForegroundColor Green
    } else {
        Write-Host "  [OK] A Steam ja estava fechada." -ForegroundColor Gray
    }
} catch {
    Write-Host "  [ERRO] Falha ao fechar a Steam: $_" -ForegroundColor Red
}

# (Opcional) Mantive a sua funcao de salvar o estado no INI caso outras coisas dependam disso
try {
    Save-MachineState "Desktop"
} catch { }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pronto para o trabalho!" -ForegroundColor Cyan
Start-Sleep -Seconds 2