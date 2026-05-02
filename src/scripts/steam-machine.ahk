#Requires AutoHotkey v2.0

; Ctrl + Shift + 1 -> Toggle machine mode (PowerShell)
^+1:: {
    ; A_ScriptDir pega automaticamente a pasta onde este arquivo .ahk está salvo
    psScriptPath := A_ScriptDir "\Toggle-MachineMode.ps1"
    
    ; Monta o comando do PowerShell para rodar em segundo plano sem restrições
    comando := 'powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "' psScriptPath '"'
    
    ; Executa o script silenciosamente ("Hide" oculta a janela)
    ; Run(comando, , "Hide")
    Run(comando, , "Max")
}

; Ctrl + Shift + 2 -> Desliga o PC
^+2:: {
    Shutdown(1) ; 1 = Shutdown
}

; Ctrl + Shift + 3 -> Reinicia o PC
^+3:: {
    Shutdown(2) ; 2 = Reboot
}

; Ctrl + Shift + 4 -> Suspende o PC
^+4:: {
    Sleep(1000)
    DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)
}