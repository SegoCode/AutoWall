; -----------------------------------------------------------------------------
; Script: PlaceMPVBehindDesktop.au3
; Description: Launches mpv (a media player) playing a video, and places it behind
; the desktop icons on Windows 11. This involves manipulating the Windows shell's
; "WorkerW" window to host mpv as a background layer.
; -----------------------------------------------------------------------------

#include <WinAPI.au3>
#include <WinAPISys.au3>
#include <WinAPIMisc.au3>
#include <WindowsConstants.au3>

; -----------------------------------------------------------------------------
; Step 1: Launch mpv with the video
; -----------------------------------------------------------------------------
; The idea here is to launch mpv in a way that it can be repositioned. We run mpv
; with certain command-line options that make sense for a wallpaper scenario:
; - `--loop`: loop the video indefinitely.
; - `--no-border`: remove mpv window borders (though we also handle borders separately in code).
; - `--fullscreen`: start mpv in fullscreen mode.
; - `--ontop`: force mpv to remain on top initially (we will move it behind the desktop icons later).
; Afterwards, we locate the mpv window handle by its PID and will re-parent it to the WorkerW window.
; -----------------------------------------------------------------------------
Local $sMPVPath = 'C:\Users\SegoCode\Desktop\AutoWall\mpv\mpv.exe'
Local $sVideoPath = 'C:\Users\SegoCode\Desktop\AutoWall\VideosHere\demo2.mp4'
Local $sMPVOptions = '--loop --no-border --fullscreen --ontop'
Local $iPID = Run('"' & $sMPVPath & '" "' & $sVideoPath & '" ' & $sMPVOptions, "", @SW_SHOW)

; Give mpv some time to start up and create its window.
Sleep(2000)

; -----------------------------------------------------------------------------
; Step 2: Get the handle of the mpv window
; -----------------------------------------------------------------------------
; Once mpv is running, we find its window handle (HWND) by using the PID returned
; from `Run()`. We'll search through all windows and match by process ID.
; Having the HWND is crucial because we'll manipulate its parent window later.
; -----------------------------------------------------------------------------
Local $hMPV = _GetMPVWindowHandle($iPID)
If $hMPV = 0 Then
    MsgBox(16, "Error", "mpv window not found.")
    Exit
EndIf

; -----------------------------------------------------------------------------
; Step 3: Create or find the WorkerW window
; -----------------------------------------------------------------------------
; The Windows shell uses multiple layered windows. By default, desktop icons are
; hosted in a SHELLDLL_DefView child window of Progman or a WorkerW window.
; To place our mpv instance behind the icons, we need to find the WorkerW window
; that sits behind the icons. If one doesn’t exist, we send a specific message
; (0x052C) to Progman to force creation of a WorkerW window. This WorkerW window
; will act like a "canvas" behind the icons, allowing us to put mpv in the background.
; -----------------------------------------------------------------------------
_CreateWorkerWWindow()
Local $hWorkerW = _GetWorkerWHandle()

If $hWorkerW = 0 Then
    MsgBox(16, "Error", "WorkerW window not found.")
    Exit
EndIf

; -----------------------------------------------------------------------------
; Step 4: Set mpv's parent to the WorkerW window
; -----------------------------------------------------------------------------
; By calling `SetParent` and making mpv's parent the WorkerW window, we effectively
; embed mpv as a child of that background layer. This allows mpv to be displayed
; behind desktop icons, as the WorkerW window resides behind them in the z-order.
; -----------------------------------------------------------------------------
Local $aResult = DllCall("user32.dll", "hwnd", "SetParent", "hwnd", $hMPV, "hwnd", $hWorkerW)
If @error Then
    MsgBox(16, "Error", "Failed to set mpv's parent.")
    Exit
EndIf

; -----------------------------------------------------------------------------
; Step 5: Remove window decorations from mpv
; -----------------------------------------------------------------------------
; Even though we started mpv with `--no-border`, this step ensures all window
; borders, title bars, and other decorations are removed at the Windows API level.
; It also changes the window style to prevent mpv from appearing in the taskbar.
; The goal is to make mpv appear as a seamless background, like wallpaper.
; -----------------------------------------------------------------------------
_RemoveWindowBorders($hMPV)

; -----------------------------------------------------------------------------
; Step 6: Resize and position mpv to cover the desktop
; -----------------------------------------------------------------------------
; Using the dimensions of the WorkerW window (which matches the desktop size),
; we resize mpv so that it completely covers the visible desktop area. This ensures
; the video is displayed as a full background.
; -----------------------------------------------------------------------------
_LocalizeMPV($hMPV, $hWorkerW)

; -----------------------------------------------------------------------------
; Step 7: Refresh the desktop to apply changes
; -----------------------------------------------------------------------------
; After making these changes (re-parenting, resizing, etc.), we call `UpdateWindow`
; on the WorkerW to ensure the UI is refreshed and the mpv window is properly
; displayed behind the icons.
; -----------------------------------------------------------------------------
DllCall("user32.dll", "int", "UpdateWindow", "hwnd", $hWorkerW)

; -----------------------------------------------------------------------------
; Function Definitions
; -----------------------------------------------------------------------------

; _GetMPVWindowHandle: Given a PID, find the associated mpv window handle.
; We iterate through all windows and check if the process ID matches mpv's PID.
Func _GetMPVWindowHandle($iPID)
    Local $aWinList = WinList()
    For $i = 1 To $aWinList[0][0]
        ; If the process ID of this window matches mpv’s PID, return its handle.
        If WinGetProcess($aWinList[$i][1]) = $iPID Then
            Return $aWinList[$i][1]
        EndIf
    Next
    Return 0
EndFunc

; _CreateWorkerWWindow: Sends a special message to Progman that triggers the creation
; of a WorkerW window behind the desktop icons. This is a known trick often used
; in "animated wallpaper" setups. After sending the message, a WorkerW window
; becomes available for hosting our content.
Func _CreateWorkerWWindow()
    Local $hProgman = WinGetHandle("[CLASS:Progman]")
    If $hProgman = 0 Then
        MsgBox(16, "Error", "Progman window not found.")
        Exit
    EndIf

    ; 0x052C (DVM_SELFFIRST) with WPARAM=0xD and LPARAM=0x1 is a known undocumented
    ; message that forces Progman to spawn a WorkerW window.
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

; _GetWorkerWHandle: Enumerates top-level windows to find the newly created WorkerW.
; The desktop icons are usually hosted inside a window called SHELLDLL_DefView,
; which in turn is hosted inside a WorkerW window (or sometimes under Progman).
; We look for SHELLDLL_DefView and then take the next sibling window, which is
; often the WorkerW we need. If not found this way, we try other known methods.
Func _GetWorkerWHandle()
    Local $hWorkerW = 0
    Local $aWinList = WinList()

    For $i = 1 To $aWinList[0][0]
        Local $hWnd = $aWinList[$i][1]

        ; If this window has a SHELLDLL_DefView child, it’s typically the main
        ; desktop window chain. The WorkerW we want is often the next sibling.
        Local $hShellView = _FindWindowEx($hWnd, 0, "SHELLDLL_DefView", "")
        If $hShellView <> 0 Then
            ; Once we find SHELLDLL_DefView, the WorkerW should be next.
            $hWorkerW = _FindWindowEx(0, $hWnd, "WorkerW", "")
            If $hWorkerW <> 0 Then
                Return $hWorkerW
            EndIf
        EndIf
    Next

    ; If we didn't find it via enumeration, try directly under Progman.
    Local $hProgman = WinGetHandle("[CLASS:Progman]")
    If $hProgman <> 0 Then
        $hWorkerW = _FindWindowEx($hProgman, 0, "WorkerW", "")
        If $hWorkerW <> 0 Then
            Return $hWorkerW
        EndIf
    EndIf

    Return 0
EndFunc

; _FindWindowEx: A wrapper for the WinAPI FindWindowEx function, which searches for
; child windows by class and name, starting from a specified parent.
Func _FindWindowEx($hWndParent, $hWndChildAfter, $sClassName, $sWindowName)
    Local $aResult = DllCall("user32.dll", "hwnd", "FindWindowExW", _
        "hwnd", $hWndParent, _
        "hwnd", $hWndChildAfter, _
        "wstr", $sClassName, _
        "wstr", $sWindowName)
    If @error Then Return SetError(@error, @extended, 0)
    Return $aResult[0]
EndFunc

; _RemoveWindowBorders: Removes the standard window styles and extended styles that
; create a title bar, border, or a taskbar button. Also ensures it's treated as a
; tool window rather than an app window, thus making it less intrusive and more
; suitable as a background element.
Func _RemoveWindowBorders($hWnd)
    Local Const $GWL_STYLE = -16
    Local Const $GWL_EXSTYLE = -20
    Local $iStyle = _WinAPI_GetWindowLong($hWnd, $GWL_STYLE)
    Local $iExStyle = _WinAPI_GetWindowLong($hWnd, $GWL_EXSTYLE)

    ; Remove WS_CAPTION and WS_THICKFRAME to eliminate borders/title bar.
    $iStyle = BitAND($iStyle, BitNOT($WS_CAPTION))
    $iStyle = BitAND($iStyle, BitNOT($WS_THICKFRAME))

    ; Remove WS_EX_APPWINDOW so it doesn't appear in the taskbar.
    $iExStyle = BitAND($iExStyle, BitNOT($WS_EX_APPWINDOW))

    ; Add WS_EX_TOOLWINDOW style to further prevent taskbar presence.
    $iExStyle = BitOR($iExStyle, $WS_EX_TOOLWINDOW)

    _WinAPI_SetWindowLong($hWnd, $GWL_STYLE, $iStyle)
    _WinAPI_SetWindowLong($hWnd, $GWL_EXSTYLE, $iExStyle)

    ; Apply style changes so they take effect immediately.
    _WinAPI_SetWindowPos($hWnd, 0, 0, 0, 0, 0, BitOR($SWP_NOMOVE, $SWP_NOSIZE, $SWP_NOZORDER, $SWP_FRAMECHANGED))
EndFunc

; _LocalizeMPV: Adjust mpv’s window position and size to cover the entire desktop.
; We get the position and size of the WorkerW (which matches the desktop resolution),
; and then set mpv’s window to those exact dimensions.
Func _LocalizeMPV($hMPV, $hWorkerW)
    Local $aWorkerWPos = WinGetPos($hWorkerW)
    ; $aWorkerWPos format: [X, Y, Width, Height]
    _WinAPI_SetWindowPos($hMPV, 0, $aWorkerWPos[0], $aWorkerWPos[1], $aWorkerWPos[2], $aWorkerWPos[3], $SWP_NOZORDER)
EndFunc
