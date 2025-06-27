; Requires AutoHotkey v2

;--------------------------------------------------------------------
; Super+| to switch between windows of the same application
; (Modified to be similar to GNOME's window switcher)
;--------------------------------------------------------------------

; This script piggybacks on the built-in Alt+Tab window switcher,
; filtering it to show only windows from the same process as the active window.
; It listens for Win+| and Win+Shift+| and converts them to Alt+Tab and Alt+Shift+Tab, respectively,
; after hiding windows from the task switcher with the ITaskbarList API,
; and then unhiding them after the switcher is closed.
; Pressing | again while holding Win will tab through the windows of the same application,
; and Shift+| will tab through them in reverse.
; Tab or Shift+Tab also works (automatically, since that's what the switcher normally uses.)

#MaxThreadsPerHotkey 2

TraySetIcon "shell32.dll", 99 ; overlapped windows icon

A_TrayMenu.Add()
A_TrayMenu.Add("Report Issue", MenuHandler)
A_TrayMenu.Add("Project Homepage", MenuHandler)

MenuHandler(ItemName, ItemPos, MyMenu) {
  if ItemName = "Report Issue" {
    Run("https://github.com/1j01/window-switcher/issues")
  } else if ItemName = "Project Homepage" {
    Run("https://github.com/1j01/window-switcher/?tab=readme-ov-file#window-switcher")
  }
}

WS_EX_APPWINDOW := 0x00040000
WS_EX_TOOLWINDOW := 0x00000080
WS_CHILD := 0x40000000

IID_ITaskbarList := "{56FDF342-FD6D-11d0-958A-006097C9A090}"
CLSID_TaskbarList := "{56FDF344-FD6D-11d0-958A-006097C9A090}"

ITaskbarList_VTable := {
  HrInit: 3,
  AddTab: 4,
  DeleteTab: 5,
  ActivateTab: 6,
  SetActiveAlt: 7,
}
TaskbarList := ComObject(CLSID_TaskbarList, IID_ITaskbarList)
TaskbarListInitialized := False

TempHiddenWindows := []

; --- MODIFICATION START ---
; 1. Added wildcard prefix (*) to allow hotkey to fire even if other modifiers (like Alt) are logically down.
; 2. Passed a parameter to the function to handle reverse cycling correctly.
*#+|:: FilteredWindowSwitcher(True)  ; Pass True for reverse (Shift is held)
*#|:: FilteredWindowSwitcher(False) ; Pass False for forward
; --- MODIFICATION END ---

FilteredWindowSwitcher(IsReverse := False) {
  global TaskbarListInitialized, TempHiddenWindows, TaskbarList, ITaskbarList_VTable

  ; --- MODIFICATION START ---
  ; Determine which key to send based on whether Shift is held.
  local KeyToSend := IsReverse ? "+{Tab}" : "{Tab}"
  ; --- MODIFICATION END ---
  
  if TempHiddenWindows.Length {
    ; If switcher is already active, just send the correct key combination to cycle.
    ; SendInput is generally more reliable than Send. {Blind} is crucial.
    SendInput "{Blind}" KeyToSend
    return
  }

  try {
    ActiveProcessName := WinGetProcessName("A")
  } catch TargetError {
    MakeSplash("Window Switcher", "Active window not found.", 1000)
    return
  }
  if WinGetCount("ahk_exe " ActiveProcessName) <= 1 {
    return
  }

  WindowsOfApp := WinGetList("ahk_exe " ActiveProcessName)
  AllWindows := WinGetList()
  Messages := []

  for Window in AllWindows {
    SameApp := false
    for WindowOfApp in WindowsOfApp {
      if Window = WindowOfApp {
        SameApp := true
        break
      }
    }
    if !SameApp && Switchable(Window) {
      try {
        if (!TaskbarListInitialized) {
          ComCall(ITaskbarList_VTable.HrInit, TaskbarList)
          TaskbarListInitialized := True
        }
        ComCall(ITaskbarList_VTable.DeleteTab, TaskbarList, "ptr", Window)
        TempHiddenWindows.Push(Window)
      } catch Error {
        ; Fail silently for problematic windows
      }
    }
  }

  ; The script still needs to send Alt+Tab to trigger the system's native switcher.
  Send "{LAlt Down}"
  SendInput "{Blind}" KeyToSend

  ; Wait for the PHYSICAL Win key to be released.
  KeyWait "LWin"

  ; --- MODIFICATION START ---
  ; 1. Commit the selection and close the switcher IMMEDIATELY after LWin is released.
  ;    This prevents focus issues from cancelling the window switch.
  Send "{LAlt Up}"

  ; 2. Restore the hidden windows *after* the switch has already happened.
  for Window in TempHiddenWindows {
    try {
      ComCall(ITaskbarList_VTable.AddTab, TaskbarList, "ptr", Window)
    } catch Error as e {
      Messages.Push("Failed to unhide window.`n`n" DescribeWindow(Window) "`n`n" e.Message)
    }
  }
  TempHiddenWindows.Length := 0
  ; --- MODIFICATION END ---

  for message in Messages {
    MsgBox(message, "Window Switcher", 0x10)
  }
}

Switchable(Window) {
  ExStyle := WinGetExStyle(Window)
  if ExStyle & WS_EX_TOOLWINDOW {
    return false
  }
  if ExStyle & WS_EX_APPWINDOW {
    return true
  }
  Style := WinGetStyle(Window)
  return !(Style & WS_CHILD)
}

DescribeWindow(Window) {
  return "Window Title: " WinGetTitle(Window) "`nWindow Class: " WinGetClass(Window) "`nProcess Name: " WinGetProcessName(Window)
}

~^s:: {
  if WinActive(A_ScriptName) {
    MakeSplash("AHK Auto-Reload", "`n  Reloading " A_ScriptName "   `n", 500)
    Reload
  }
}

MakeSplash(Title, Text, Duration := 0) {
  SplashGui := Gui(, Title)
  SplashGui.Opt("+AlwaysOnTop +Disabled -SysMenu +Owner")
  SplashGui.Add("Text", , Text)
  SplashGui.Show("NoActivate")
  if Duration {
    Sleep(Duration)
    SplashGui.Destroy()
  }
  return SplashGui
}
