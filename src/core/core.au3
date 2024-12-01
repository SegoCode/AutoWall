; Script: PlaceMPVBehindDesktop.au3
; Description: Places mpv playing a video behind the desktop icons on Windows 11.

#include <WinAPI.au3>
#include <WinAPISys.au3>
#include <WinAPIMisc.au3>
#include <WindowsConstants.au3>

; Step 1: Launch mpv with the video
Local $sMPVPath = 'C:\Users\SegoCode\Desktop\AutoWall\mpv\mpv.exe'
Local $sVideoPath = 'C:\Users\SegoCode\Desktop\AutoWall\VideosHere\demo2.mp4'
; Optional: Additional mpv options
Local $sMPVOptions = '--loop --no-border --fullscreen --ontop' ; Adjust options as needed
Local $iPID = Run('"' & $sMPVPath & '" "' & $sVideoPath & '" ' & $sMPVOptions, "", @SW_SHOW)

; Allow mpv to start
Sleep(2000)

; Step 2: Get the handle of the mpv window
Local $hMPV = _GetMPVWindowHandle($iPID)
If $hMPV = 0 Then
    MsgBox(16, "Error", "mpv window not found.")
    Exit
EndIf

; Step 3: Create or find the WorkerW window
_CreateWorkerWWindow()
Local $hWorkerW = _GetWorkerWHandle()

If $hWorkerW = 0 Then
    MsgBox(16, "Error", "WorkerW window not found.")
    Exit
EndIf

; Step 4: Set mpv's parent to the WorkerW window
Local $aResult = DllCall("user32.dll", "hwnd", "SetParent", "hwnd", $hMPV, "hwnd", $hWorkerW)
If @error Then
    MsgBox(16, "Error", "Failed to set mpv's parent.")
    Exit
EndIf

; Step 5: Remove window decorations from mpv
_RemoveWindowBorders($hMPV)

; Step 6: Resize and position mpv to cover the desktop
_LocalizeMPV($hMPV, $hWorkerW)

; Step 7: Refresh the desktop to apply changes
DllCall("user32.dll", "int", "UpdateWindow", "hwnd", $hWorkerW)

; ---- Function Definitions ----

Func _GetMPVWindowHandle($iPID)
    ; Get the window handle of mpv based on PID
    Local $aWinList = WinList()
    For $i = 1 To $aWinList[0][0]
        If WinGetProcess($aWinList[$i][1]) = $iPID Then
            Return $aWinList[$i][1]
        EndIf
    Next
    Return 0
EndFunc

Func _CreateWorkerWWindow()
    ; Send a message to Progman to create a WorkerW window
    Local $hProgman = WinGetHandle("[CLASS:Progman]")
    If $hProgman = 0 Then
        MsgBox(16, "Error", "Progman window not found.")
        Exit
    EndIf

    ; Send the magic message to Progman
    DllCall("user32.dll", "lresult", "SendMessageTimeoutW", _
        "hwnd", $hProgman, _
        "uint", 0x052C, _
        "wparam", 0x0000000D, _
        "lparam", 0x00000001, _
        "uint", 0x0000, _ ; SMTO_NORMAL
        "uint", 1000, _
        "ptr", 0)
    Sleep(500)
EndFunc

Func _GetWorkerWHandle()
    ; Enumerate all top-level windows to find the WorkerW window
    Local $hWorkerW = 0
    Local $aWinList = WinList()

    For $i = 1 To $aWinList[0][0]
        ; Get the handle of the current window
        Local $hWnd = $aWinList[$i][1]

        ; Look for SHELLDLL_DefView child window
        Local $hShellView = _FindWindowEx($hWnd, 0, "SHELLDLL_DefView", "")
        If $hShellView <> 0 Then
            ; Found a window with SHELLDLL_DefView as child
            ; Now get the next sibling window which should be WorkerW
            $hWorkerW = _FindWindowEx(0, $hWnd, "WorkerW", "")
            If $hWorkerW <> 0 Then
                Return $hWorkerW
            EndIf
        EndIf
    Next

    ; Try to find WorkerW under Progman
    Local $hProgman = WinGetHandle("[CLASS:Progman]")
    If $hProgman <> 0 Then
        $hWorkerW = _FindWindowEx($hProgman, 0, "WorkerW", "")
        If $hWorkerW <> 0 Then
            Return $hWorkerW
        EndIf
    EndIf

    Return 0
EndFunc

Func _FindWindowEx($hWndParent, $hWndChildAfter, $sClassName, $sWindowName)
    ; Wrapper for FindWindowEx API
    Local $aResult = DllCall("user32.dll", "hwnd", "FindWindowExW", _
        "hwnd", $hWndParent, _
        "hwnd", $hWndChildAfter, _
        "wstr", $sClassName, _
        "wstr", $sWindowName)
    If @error Then Return SetError(@error, @extended, 0)
    Return $aResult[0]
EndFunc

Func _RemoveWindowBorders($hWnd)
    ; Remove window styles to eliminate borders and title bar
    Local Const $GWL_STYLE = -16
    Local Const $GWL_EXSTYLE = -20
    Local $iStyle = _WinAPI_GetWindowLong($hWnd, $GWL_STYLE)
    Local $iExStyle = _WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE)

    ; Remove WS_CAPTION and WS_THICKFRAME styles
    $iStyle = BitAND($iStyle, BitNOT($WS_CAPTION))
    $iStyle = BitAND($iStyle, BitNOT($WS_THICKFRAME))
    ; Remove WS_EX_APPWINDOW style
    $iExStyle = BitAND($iExStyle, BitNOT($WS_EX_APPWINDOW))
    ; Add WS_EX_TOOLWINDOW style
    $iExStyle = BitOR($iExStyle, $WS_EX_TOOLWINDOW)

    _WinAPI_SetWindowLong($hWnd, $GWL_STYLE, $iStyle)
    _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, $iExStyle)

    ; Apply the changes
    _WinAPI_SetWindowPos($hWnd, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
EndFunc

Func _LocalizeMPV($hMPV, $hWorkerW)
    ; Get the size of the desktop (WorkerW window)
    Local $aWorkerWPos = WinGetPos($hWorkerW)
    ; Move mpv to cover the entire desktop
    _WinAPI_SetWindowPos($hMPV, 0, $aWorkerWPos[0], $aWorkerWPos[1], $aWorkerWPos[2], $aWorkerWPos[3], $SWP_NOZORDER)
EndFunc
