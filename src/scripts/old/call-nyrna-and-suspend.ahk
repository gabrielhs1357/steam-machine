#Requires AutoHotkey v2.0

; Define o caminho do arquivo INI na mesma pasta do script
IniPath := A_ScriptDir "\nyrna_state.ini"

; Ctrl + Alt + F12
^!F12:: { 
    ; Seta a variável como true (1) no arquivo INI
    IniWrite("1", IniPath, "Nyrna", "IsSuspended")
    
    Send("!{F12}")  ; Envia Alt + F12 (para o Nyrna)
    Sleep(1000)     ; Espera 1 segundo
    DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0) ; Suspende o PC
}