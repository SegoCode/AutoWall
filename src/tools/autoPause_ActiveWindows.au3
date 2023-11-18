#NoTrayIcon
; Resume playback only when the Desktop is active
While 1
   $activeWindow = WinGetTitle("[ACTIVE]") ; Get the title of the active window
   If $activeWindow <> "" And $activeWindow <> "Desktop" Then ; If the active window is not the desktop
       ; Send the pause command to mpv
       Run(@ComSpec & " /c " & "echo set pause yes >\\.\pipe\mpvsocket", "", @SW_HIDE)
   Else
       ; Send the resume command to mpv
       Run(@ComSpec & " /c " & "echo set pause no >\\.\pipe\mpvsocket", "", @SW_HIDE)
   EndIf
   Sleep(1000) ; Check every second
WEnd

