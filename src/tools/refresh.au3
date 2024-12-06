; -----------------------------------------------------------------------------
; Script: WorkerW Integration
; Description:
;   This script integrate a known window into the Windows 11 
;   desktop layer by using a hidden WorkerW window.
;
; Steps:
;   1. Close any existing WorkerW windows to get a "clean slate".
;   2. Retrieve the WorkerW window handle, which sits behind the desktop icons.
;   3. Re-parent your known window (hAppWnd) as a child of the WorkerW window.
;   4. Remove all window decorations and position it to cover the entire desktop.
;   5. Trigger a shell refresh to ensure proper desktop icon layering.
;
; By doing this, your window effectively becomes a background element behind
; icons creating dynamic wallpapers, interactive desktops, or embedding custom 
; UI into the desktop background layer.
; -----------------------------------------------------------------------------

#include <WinAPI.au3>
#include <WindowsConstants.au3>

; -----------------------------------------------------------------------------
; MAIN EXECUTION
; -----------------------------------------------------------------------------

; Ensure the user provided the application window handle as a parameter:
; Example: script.exe 0x00300218
If $CmdLine[0] < 1 Then
    MsgBox(16, "Error", "Please provide the hAppWnd as a parameter (hex handle).")
    Exit
EndIf

; Convert the command-line argument (string) to a handle (numeric).
; Note: hAppWnd should be provided in hex format (e.g., 0x00300218).
Local $hAppWnd = $CmdLine[1]

; Step 0: Close any existing WorkerW windows to ensure a fresh environment.
_CloseAllWorkerWWindows()

; Step 1: Retrieve the WorkerW window handle.
; The WorkerW window is created by the Explorer process and usually sits behind
; SHELLDLL_DefView which hosts the desktop icons. If we find that view, we can
; find the corresponding WorkerW. If not found, we can still try Progman fallback.
Local $hWorkerW = _GetWorkerWHandle()
If $hWorkerW = 0 Then
    MsgBox(16, "Error", "WorkerW window not found after attempting to create/locate it.")
    Exit
EndIf

; Step 2: Set the known application window to be a child of the WorkerW window.
; This effectively places your app behind the icons on the Windows 11 desktop.
Local $aSetParent = DllCall("user32.dll", "hwnd", "SetParent", "hwnd", $hAppWnd, "hwnd", $hWorkerW)
If @error Then
    MsgBox(16, "Error", "Failed to set the specified window's parent to WorkerW.")
    Exit
EndIf

; Step 3: Remove window decorations from hAppWnd.
; We strip out caption bars, thick frames, and other styles, leaving a borderless
; window that can cleanly integrate with the desktop background.
_RemoveWindowBorders($hAppWnd)

; Step 4: Position the hAppWnd to cover the entire WorkerW area (entire desktop).
; The WorkerW typically matches the desktop dimension, so we size and position
; our window to match it exactly.
_LocalizeApp($hAppWnd, $hWorkerW)

; Step 5: Trigger a shell refresh. This simulates right-click "Refresh" on the
; desktop, ensuring that icons and other elements refresh their Z-order and
; that the new WorkerW configuration is properly reflected.
DllCall("shell32.dll", "none", "SHChangeNotify", _
    "long", 0x8000000, _ ; SHCNE_ASSOCCHANGED
    "uint", 0x0, _
    "ptr", 0, _
    "ptr", 0)

; Done! Your window should now sit behind the desktop icons.

; -----------------------------------------------------------------------------
; FUNCTION DEFINITIONS
; -----------------------------------------------------------------------------

; _CloseAllWorkerWWindows()
; Closes all existing WorkerW windows. This ensures that there's no stale
; WorkerW environment. If multiple WorkerWs are found, we close them all
; to avoid unexpected behaviors.
Func _CloseAllWorkerWWindows()
    Local $aWinList = WinList()
    For $i = 1 To $aWinList[0][0]
        Local $hWnd = $aWinList[$i][1]
        If $aWinList[$i][0] <> "" Then
            If _WinAPI_GetClassName($hWnd) = "WorkerW" Then
                WinClose($hWnd)
            EndIf
        EndIf
    Next
    ; Short sleep to allow the system to process the closing of these windows.
    Sleep(500)
EndFunc

; _GetWorkerWHandle()
; Attempts to find or create a WorkerW handle which sits behind the icons.
; The logic:
;   1. Enumerate all top-level windows.
;   2. Identify the SHELLDLL_DefView child window (the one hosting desktop icons).
;   3. The WorkerW behind it is where we want to parent our custom window.
; If not found directly, tries the Progman fallback approach.
Func _GetWorkerWHandle()
    Local $aWinList = WinList()

    For $i = 1 To $aWinList[0][0]
        Local $hWnd = $aWinList[$i][1]
        Local $hShellView = _FindWindowEx($hWnd, 0, "SHELLDLL_DefView", "")
        If $hShellView <> 0 Then
            ; Once we find SHELLDLL_DefView, the WorkerW behind it can be found.
            Local $hWorkerW = _FindWindowEx(0, $hWnd, "WorkerW", "")
            If $hWorkerW <> 0 Then
                Return $hWorkerW
            EndIf
        EndIf
    Next

    ; Fallback: use Progman if above method fails.
    Local $hProgman = WinGetHandle("[CLASS:Progman]")
    If $hProgman <> 0 Then
        Local $hWorkerW = _FindWindowEx($hProgman, 0, "WorkerW", "")
        If $hWorkerW <> 0 Then Return $hWorkerW
    EndIf

    ; If none found, return 0 indicating failure.
    Return 0
EndFunc

; _FindWindowEx($hWndParent, $hWndChildAfter, $sClassName, $sWindowName)
; Wrapper for FindWindowExW. Searches a window's children by class and name.
Func _FindWindowEx($hWndParent, $hWndChildAfter, $sClassName, $sWindowName)
    Local $aResult = DllCall("user32.dll", "hwnd", "FindWindowExW", _
        "hwnd", $hWndParent, _
        "hwnd", $hWndChildAfter, _
        "wstr", $sClassName, _
        "wstr", $sWindowName)
    If @error Then Return SetError(@error, @extended, 0)
    Return $aResult[0]
EndFunc

; _RemoveWindowBorders($hWnd)
; Removes standard window borders, captions, thickframes, and changes EX-style
; to remove appwindow style and add toolwindow, making it appear more like a
; non-decorated background element.
Func _RemoveWindowBorders($hWnd)
    Local Const $GWL_STYLE = -16
    Local Const $GWL_EXSTYLE = -20

    Local $iStyle = _WinAPI_GetWindowLong($hWnd, $GWL_STYLE)
    Local $iExStyle = _WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE)

    ; Remove caption and thickframe styles from the window.
    $iStyle = BitAND($iStyle, BitNOT($WS_CAPTION))
    $iStyle = BitAND($iStyle, BitNOT($WS_THICKFRAME))

    ; Adjust Extended Styles: remove appwindow, add toolwindow (removes taskbar presence).
    $iExStyle = BitAND($iExStyle, BitNOT($WS_EX_APPWINDOW))
    $iExStyle = BitOR($iExStyle, $WS_EX_TOOLWINDOW)

    ; Apply the new styles.
    _WinAPI_SetWindowLong($hWnd, $GWL_STYLE, $iStyle)
    _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, $iExStyle)

    ; Refresh the window frame to apply changes.
    _WinAPI_SetWindowPos($hWnd, 0, 0, 0, 0, 0, _
        BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
EndFunc

; _LocalizeApp($hAppWnd, $hWorkerW)
; Positions and resizes the application window ($hAppWnd) to exactly cover the
; WorkerW window. As WorkerW typically matches the desktop dimension, this ensures
; the app spans the entire screen behind the icons.
Func _LocalizeApp($hAppWnd, $hWorkerW)
    Local $aWorkerWPos = WinGetPos($hWorkerW)
    _WinAPI_SetWindowPos($hAppWnd, 0, _
        $aWorkerWPos[0], $aWorkerWPos[1], $aWorkerWPos[2], $aWorkerWPos[3], _
        $SWP_NOZORDER)
EndFunc
