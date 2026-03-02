#Requires AutoHotkey v2.0

; Win + Alt + F12
#!F12:: {
    ; A_ScriptDir pega automaticamente a pasta onde este arquivo .ahk está salvo
    psScriptPath := A_ScriptDir "\toggle-machine-mode.ps1"
    
    ; Monta o comando do PowerShell para rodar em segundo plano sem restrições
    comando := 'powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "' psScriptPath '"'
    
    ; Executa o script silenciosamente ("Hide" oculta a janela)
    Run(comando, , "Hide")
}