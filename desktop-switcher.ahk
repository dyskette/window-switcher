#Requires AutoHotkey v2.0

;===============================================================================
; SCRIPT CONFIGURATION
;===============================================================================

; Define la ruta a nuestro programa ayudante compilado.
global HELPER_EXE := A_ScriptDir . "\VDesktopHelper\bin\Release\net8.0-windows10.0.19041\publish\VDesktopHelper.exe"

if !FileExist(HELPER_EXE) {
    MsgBox("Error Crítico: No se encontró el programa ayudante 'VDesktopHelper.exe'.`n`n"
        . "Por favor, compila el proyecto de C# y copia el archivo .exe a la subcarpeta 'libraries'.`n`n"
        . "Ruta esperada: " . HELPER_EXE, 
        "Error de Script", 16)
    ExitApp
}

;===============================================================================
; HOTKEYS (VERSIÓN CORREGIDA SIN CONFLICTOS)
;===============================================================================

; --- Parte 1: Cambiar entre Escritorios ---
; Se usa la sintaxis estándar con el modificador # (Win).
; Esto maneja tanto LWin como RWin automáticamente.
#PgUp::Send "^#{Left}"
#PgDn::Send "^#{Right}"


; --- Parte 2: Mover la Ventana Activa al Escritorio Adyacente ---
; Este atajo ahora funcionará correctamente junto con los de arriba.
#+PgUp::MoveWindowToAdjacentDesktop(-1)
#+PgDn::MoveWindowToAdjacentDesktop(1)


;===============================================================================
; CORE LOGIC
;===============================================================================

MoveWindowToAdjacentDesktop(direction) {
    global HELPER_EXE

    hwnd := WinExist("A")
    if !hwnd {
        return
    }

    ; Primero, verificamos si hay más de un escritorio para evitar trabajo innecesario.
    if (VD_GetDesktopCount() <= 1) {
        return
    }

    ; Ahora, simplemente le decimos al ayudante que mueva la ventana en la dirección deseada.
    ; Toda la lógica de "envolver" y encontrar el escritorio de destino ocurre en C#.
    if (direction > 0) {
        Send "^#{Right}"
    } else {
        Send "^#{Left}"
    }
    Run('"' HELPER_EXE '" move_adj ' hwnd ' ' direction, A_ScriptDir, "Hide")
}


;===============================================================================
; VIRTUAL DESKTOP WRAPPERS (via .NET Helper)
;===============================================================================

VD_GetDesktopCount() {
    global HELPER_EXE
    result := RunWait('"' HELPER_EXE '" get_count', A_ScriptDir, "Hide", &output)
    return Integer(Trim(output))
}
