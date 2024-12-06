; -----------------------------------------------------------------------------
; Script: core.au3
; Description: Places a given program window behind the desktop icons on Windows 11.
;
; Usage:
; core.exe run "C:\Path\To\YourApp.exe" "arg1" "arg2" ...
;
; Example (with mpv):
; core.exe run "C:\Users\SegoCode\Desktop\AutoWall\mpv\mpv.exe" "--loop" "--no-border" "--fullscreen" "--ontop" "C:\Users\SegoCode\Desktop\AutoWall\VideosHere\demo2.mp4"
; -----------------------------------------------------------------------------

#include <WinAPI.au3>
#include <WinAPISys.au3>
#include <WinAPIMisc.au3>
#include <WindowsConstants.au3>

; -----------------------------------------------------------------------------
; Parse command-line arguments:
; We expect: PlaceBehindDesktop.exe run <exepath> [optional args...]
; -----------------------------------------------------------------------------
If $CmdLine[0] < 2 Then
    MsgBox(64, "Usage", "PlaceBehindDesktop.exe run <AppPath> [args...]")
    Exit
EndIf

If $CmdLine[1] <> "run" Then
    MsgBox(16, "Error", "Invalid command. Expected 'run' as the first argument.")
    Exit
EndIf

; The executable path is the second argument
Local $sAppPath = $CmdLine[2]

; Build the parameter string from the remaining arguments
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

; Allow the application to start
Sleep(1000)

; -----------------------------------------------------------------------------
; Step 2: Get the handle of the newly launched window by PID
; This function searches all windows for one matching the given PID.
; -----------------------------------------------------------------------------
Local $hAppWnd = _GetWindowHandleByPID($iPID)
If $hAppWnd = 0 Then
    MsgBox(16, "Error", "Application window not found.")
    Exit
EndIf

; -----------------------------------------------------------------------------
; Step 3: Create or find the WorkerW window (the background layer)
; Sending a message to Progman forces a WorkerW window to appear.
; -----------------------------------------------------------------------------
_CreateWorkerWWindow()
Local $hWorkerW = _GetWorkerWHandle()

If $hWorkerW = 0 Then
    MsgBox(16, "Error", "WorkerW window not found.")
    Exit
EndIf

; -----------------------------------------------------------------------------
; Step 4: Re-parent the application's window to the WorkerW window
; This places it behind desktop icons.
; -----------------------------------------------------------------------------
Local $aResult = DllCall("user32.dll", "hwnd", "SetParent", "hwnd", $hAppWnd, "hwnd", $hWorkerW)
If @error Then
    MsgBox(16, "Error", "Failed to set the application's parent.")
    Exit
EndIf

; -----------------------------------------------------------------------------
; Step 5: Remove window decorations (optional but recommended)
; This ensures the application won't show borders or taskbar icons, making it
; appear as a true background.
; -----------------------------------------------------------------------------
_RemoveWindowBorders($hAppWnd)

; -----------------------------------------------------------------------------
; Step 6: Resize and position the window to cover the entire desktop
; -----------------------------------------------------------------------------
_LocalizeApp($hAppWnd, $hWorkerW)

; -----------------------------------------------------------------------------
; Step 7: Trigger a shell refresh similar to the desktop context menu "Refresh"
; Use SHChangeNotify to tell the shell that something changed, prompting a refresh.
; -----------------------------------------------------------------------------
DllCall("shell32.dll", "none", "SHChangeNotify", _
    "long", 0x8000000, _ ; SHCNE_ASSOCCHANGED: Notify that file type associations have changed
    "uint", 0x0, _       ; SHCNF_IDLIST or SHCNF_PATH could be used; 0 is often sufficient for global refresh
    "ptr", 0, _
    "ptr", 0)
    
; -----------------------------------------------------------------------------
; Function Definitions
; -----------------------------------------------------------------------------

; _GetWindowHandleByPID:
; Given a PID, scan all top-level windows for one owned by that process.
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
; Sends a message to Progman, which causes it to spawn a WorkerW window
; behind the desktop icons. This is a known trick for "animated wallpapers."
Func _CreateWorkerWWindow()
    Local $hProgman = WinGetHandle("[CLASS:Progman]")
    If $hProgman = 0 Then
        MsgBox(16, "Error", "Progman window not found.")
        Exit
    EndIf

    ; The message below triggers the creation of WorkerW.
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
; Enumerates windows to find the WorkerW window that sits behind desktop icons.
; It looks for SHELLDLL_DefView and then finds WorkerW as a sibling.
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
; A wrapper for the Windows API FindWindowEx function.
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
; Removes window styles that add borders, captions, or taskbar entries, making the
; window appear as a pure background element.
Func _RemoveWindowBorders($hWnd)
    Local Const $GWL_STYLE = -16
    Local Const $GWL_EXSTYLE = -20
    Local $iStyle = _WinAPI_GetWindowLong($hWnd, $GWL_STYLE)
    Local $iExStyle = _WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE)

    ; Remove caption and thickframe for no borders.
    $iStyle = BitAND($iStyle, BitNOT($WS_CAPTION))
    $iStyle = BitAND($iStyle, BitNOT($WS_THICKFRAME))

    ; Remove WS_EX_APPWINDOW so it doesn't show in the taskbar.
    $iExStyle = BitAND($iExStyle, BitNOT($WS_EX_APPWINDOW))

    ; Add WS_EX_TOOLWINDOW to avoid showing in Alt+Tab.
    $iExStyle = BitOR($iExStyle, $WS_EX_TOOLWINDOW)

    _WinAPI_SetWindowLong($hWnd, $GWL_STYLE, $iStyle)
    _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, $iExStyle)
    _WinAPI_SetWindowPos($hWnd, 0, 0, 0, 0, 0, _
        BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
EndFunc

; _LocalizeApp:
; Positions and resizes the application window to fill the entire WorkerW (desktop)
; area, making it look like a fullscreen background.
Func _LocalizeApp($hAppWnd, $hWorkerW)
    Local $aWorkerWPos = WinGetPos($hWorkerW)
    _WinAPI_SetWindowPos($hAppWnd, 0, $aWorkerWPos[0], $aWorkerWPos[1], $aWorkerWPos[2], $aWorkerWPos[3], $SWP_NOZORDER)
EndFunc
