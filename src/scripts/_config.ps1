# =============================================================================
# _config.ps1 — Configurações e funções compartilhadas
# Uso: . "$PSScriptRoot\_config.ps1"  (dot-source nos outros scripts)
# =============================================================================

# --- Nomes dos dispositivos de áudio ---
$tvAudioName      = "*Beyond TV (NVIDIA High Definition Audio)*"
$desktopAudioName = "*Realtek(R) Audio*"

# --- IDs dos monitores ---
$primaryMonitorId   = 1
$secondaryMonitorId = 2

# --- Caminho do arquivo de estado ---
# Sempre aponta para a pasta onde os scripts estão salvos
$iniPath = Join-Path -Path $PSScriptRoot -ChildPath "machine_state.ini"

# --- Função: obtém o DisplayId da TV ---
function Get-TvDisplayId {
    $allDisplays = Get-DisplayInfo
    return ($allDisplays | Where-Object { $_.DisplayName -eq "Beyond TV" }).DisplayId
}

# --- Função: lê o estado atual do arquivo INI ---
function Get-MachineState {
    if (Test-Path $iniPath) {
        $content = Get-Content -Path $iniPath -Raw
        if ($content -match "Mode\s*=\s*(Console|Desktop)") {
            return $matches[1].Trim()
        }
    }
    return "Desktop"   # padrão se o arquivo não existir
}

# --- Função: salva o estado no arquivo INI ---
function Save-MachineState {
    param([string]$Mode)
    $iniContent = @"
[State]
Mode=$Mode
"@
    $iniContent | Out-File -FilePath $iniPath -Encoding UTF8
    Write-Host "Estado '$Mode' salvo com sucesso em machine_state.ini."
}
