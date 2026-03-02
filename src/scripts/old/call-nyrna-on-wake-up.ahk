#Requires AutoHotkey v2.0

; Define o caminho do arquivo INI na mesma pasta do script
IniPath := A_ScriptDir "\nyrna_state.ini"

Sleep(1000) ; Espera 1 segundo para a tela do Moonlight estabilizar

; Lê a variável do arquivo. Se o arquivo não existir ainda, assume "0" (false)
isSuspended := IniRead(IniPath, "Nyrna", "IsSuspended", "0")

; Se a suspensão foi iniciada com o jogo aberto (true)
if (isSuspended == "1") {
    Send("!{F12}") ; Envia Alt + F12 para o Nyrna
    
    ; Reseta a variável para false (0) no arquivo INI
    IniWrite("0", IniPath, "Nyrna", "IsSuspended")
}