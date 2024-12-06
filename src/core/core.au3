; -----------------------------------------------------------------------------
; Script: core.au3
; Description: Places a given program window behind the desktop icons on Windows 11.
;
; Usage:
; core.exe run <AppPath> [args...]
;
; Example (with mpv):
; core.exe run "C:\Path\To\mpv.exe" "--loop" "--no-border" "--fullscreen" "--ontop" "C:\Path\To\video.mp4"
; -----------------------------------------------------------------------------

#include <WinAPI.au3>
#include <WinAPISys.au3>
#include <WinAPIMisc.au3>
#include <WindowsConstants.au3>

; -----------------------------------------------------------------------------
; Parse command-line arguments:
; We expect: core.exe run <AppPath> [args...]
; -----------------------------------------------------------------------------
If $CmdLine[0] < 2 Then
    MsgBox(64, "Usage", "core.exe run <AppPath> [args...]")
    Exit
EndIf

If $CmdLine[1] <> "run" Then
    MsgBox(16, "Error", "Invalid command. Expected 'run' as the first argument.")
    Exit
EndIf

Local $sAppPath = $CmdLine[2]
Local $sAppParams = ""
For $i = 3 To $CmdLine[0]
    $sAppParams &= '"' & $CmdLine[$i] & '" '
Next
$sAppParams = StringStripWS($sAppParams, 3)

; -----------------------------------------------------------------------------
; Step 1: Launch the specified application with given parameters
; -----------------------------------------------------------------------------
Local $iPID = Run('"' & $sAppPath & '" ' & $sAppParams, "", @SW_SHOW)
If $iPID = 0 Then
    MsgBox(16, "Error", "Failed to run the application.")
    Exit
EndIf

; -----------------------------------------------------------------------------
; Step 2: Wait up to 10 seconds for the application window to appear by PID OR
; a window titled "litewebview" to appear. Whichever comes first.
; -----------------------------------------------------------------------------
Local $hAppWnd = 0
Local $iStartTime = TimerInit()
While True
    ; Check by PID
    $hAppWnd = _GetWindowHandleByPID($iPID)
    If $hAppWnd <> 0 Then
        ExitLoop
    EndIf

    ; Check by title
    Local $hLiteWebView = WinGetHandle("[TITLE:litewebview]")
    If Not @error And $hLiteWebView <> "" Then
        $hAppWnd = $hLiteWebView
        ExitLoop
    EndIf

    ; Check time
    If TimerDiff($iStartTime) > 10000 Then
        MsgBox(16, "Error", "Application window not found by PID or by title 'litewebview' within 10 seconds.")
        Exit
    EndIf
    Sleep(100)
WEnd

; -----------------------------------------------------------------------------
; Step 3: Create or find the WorkerW window
; -----------------------------------------------------------------------------
_CreateWorkerWWindow()
Local $hWorkerW = _GetWorkerWHandle()

If $hWorkerW = 0 Then
    MsgBox(16, "Error", "WorkerW window not found.")
    Exit
EndIf

; -----------------------------------------------------------------------------
; Step 4: Re-parent the application's window to the WorkerW window
; This places it behind the desktop icons.
; -----------------------------------------------------------------------------
Local $aResult = DllCall("user32.dll", "hwnd", "SetParent", "hwnd", $hAppWnd, "hwnd", $hWorkerW)
If @error Then
    MsgBox(16, "Error", "Failed to set the application's parent.")
    Exit
EndIf

; -----------------------------------------------------------------------------
; Step 5: Remove window decorations
; -----------------------------------------------------------------------------
_RemoveWindowBorders($hAppWnd)

; -----------------------------------------------------------------------------
; Step 6: Resize and position the window to cover the entire desktop
; -----------------------------------------------------------------------------
_LocalizeApp($hAppWnd, $hWorkerW)

; -----------------------------------------------------------------------------
; Step 7: Trigger a shell refresh similar to right-click "Refresh"
; -----------------------------------------------------------------------------
DllCall("shell32.dll", "none", "SHChangeNotify", _
    "long", 0x8000000, _ ; SHCNE_ASSOCCHANGED
    "uint", 0x0, _
    "ptr", 0, _
    "ptr", 0)


; -----------------------------------------------------------------------------
; Function Definitions
; -----------------------------------------------------------------------------

; _GetWindowHandleByPID:
; Given a PID, find a top-level window owned by that process.
Func _GetWindowHandleByPID($iPID)
    Local $aWinList = WinList()
    For $i = 1 To $aWinList[0][0]
        If WinGetProcess($aWinList[$i][1]) = $iPID Then
            Return $aWinList[$i][1]
        EndIf
    Next
    Return 0
EndFunc

; _CreateWorkerWWindow:
; Sends a known message to Progman that forces a WorkerW window to appear.
Func _CreateWorkerWWindow()
    Local $hProgman = WinGetHandle("[CLASS:Progman]")
    If $hProgman = 0 Then
        MsgBox(16, "Error", "Progman window not found.")
        Exit
    EndIf

    DllCall("user32.dll", "lresult", "SendMessageTimeoutW", _
        "hwnd", $hProgman, _
        "uint", 0x052C, _
        "wparam", 0x0000000D, _
        "lparam", 0x00000001, _
        "uint", 0x0000, _
        "uint", 1000, _
        "ptr", 0)
    Sleep(500)
EndFunc

; _GetWorkerWHandle:
; Finds the WorkerW window by enumerating windows and looking for SHELLDLL_DefView.
Func _GetWorkerWHandle()
    Local $hWorkerW = 0
    Local $aWinList = WinList()

    For $i = 1 To $aWinList[0][0]
        Local $hWnd = $aWinList[$i][1]
        Local $hShellView = _FindWindowEx($hWnd, 0, "SHELLDLL_DefView", "")
        If $hShellView <> 0 Then
            $hWorkerW = _FindWindowEx(0, $hWnd, "WorkerW", "")
            If $hWorkerW <> 0 Then
                Return $hWorkerW
            EndIf
        EndIf
    Next

    Local $hProgman = WinGetHandle("[CLASS:Progman]")
    If $hProgman <> 0 Then
        $hWorkerW = _FindWindowEx($hProgman, 0, "WorkerW", "")
        If $hWorkerW <> 0 Then
            Return $hWorkerW
        EndIf
    EndIf

    Return 0
EndFunc

; _FindWindowEx:
; A wrapper for the WinAPI FindWindowEx function.
Func _FindWindowEx($hWndParent, $hWndChildAfter, $sClassName, $sWindowName)
    Local $aResult = DllCall("user32.dll", "hwnd", "FindWindowExW", _
        "hwnd", $hWndParent, _
        "hwnd", $hWndChildAfter, _
        "wstr", $sClassName, _
        "wstr", $sWindowName)
    If @error Then Return SetError(@error, @extended, 0)
    Return $aResult[0]
EndFunc

; _RemoveWindowBorders:
; Removes window styles so it's borderless and doesn't appear in the taskbar.
Func _RemoveWindowBorders($hWnd)
    Local Const $GWL_STYLE = -16
    Local Const $GWL_EXSTYLE = -20
    Local $iStyle = _WinAPI_GetWindowLong($hWnd, $GWL_STYLE)
    Local $iExStyle = _WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE)

    $iStyle = BitAND($iStyle, BitNOT($WS_CAPTION))
    $iStyle = BitAND($iStyle, BitNOT($WS_THICKFRAME))
    $iExStyle = BitAND($iExStyle, BitNOT($WS_EX_APPWINDOW))
    $iExStyle = BitOR($iExStyle, $WS_EX_TOOLWINDOW)

    _WinAPI_SetWindowLong($hWnd, $GWL_STYLE, $iStyle)
    _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, $iExStyle)
    _WinAPI_SetWindowPos($hWnd, 0, 0, 0, 0, 0, _
        BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
EndFunc

; _LocalizeApp:
; Positions the app window to match the entire WorkerW (desktop) dimensions.
Func _LocalizeApp($hAppWnd, $hWorkerW)
    Local $aWorkerWPos = WinGetPos($hWorkerW)
    _WinAPI_SetWindowPos($hAppWnd, 0, $aWorkerWPos[0], $aWorkerWPos[1], $aWorkerWPos[2], $aWorkerWPos[3], $SWP_NOZORDER)
EndFunc
