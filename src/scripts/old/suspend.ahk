#Requires AutoHotkey v2.0

; Shift + Alt + F12
+!F12:: {
    Sleep(1000)  ; Espera 1 segundo
    DllCall("PowrProf\SetSuspendState", "Int", 0, "Int", 0, "Int", 0) ; Suspende o PC
}