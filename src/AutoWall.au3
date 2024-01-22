#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author:         SegoCode

 Script Function:
	Set live wallpapers on your Windows desktop usig mpv and weebp.

#ce ----------------------------------------------------------------------------

#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <AutoItConstants.au3>
#include <WinAPIShPath.au3>
#include <GuiComboBox.au3>


#Region ### START Koda GUI section ### Form=
$form = GUICreate("github.com/SegoCode", 513, 72, 183, 124, -1, $WS_EX_ACCEPTFILES)
GUISetOnEvent($GUI_EVENT_DROPPED, -1)
$applyb = GUICtrlCreateButton("Apply", 432, 8, 75, 25)
$resetb = GUICtrlCreateButton("Reset", 432, 40, 75, 25)
GUICtrlSetBkColor($resetb, 0xff7b7b)
$browseb = GUICtrlCreateButton("Browse", 352, 40, 75, 25)
$inputPath = GUICtrlCreateInput("", 8, 8, 417, 25)
$comboScreens = GUICtrlCreateCombo("", 225, 41, 120, 0, $CBS_DROPDOWNLIST)
GUICtrlSetState(-1, $GUI_DROPACCEPTED)
$winStart = GUICtrlCreateCheckbox("Set on windows startup", 8, 40, 137, 25)
Opt("TrayMenuMode", 1)
Opt("TrayOnEventMode", 1)
#EndRegion ### END Koda GUI section ###


;Autorun lauch
$autoRunState=False
If $CmdLine[0] > 0 Then
	$autoRunState=True
	If $CmdLine[0] > 1 Then		
		sleep(2000) ;Time to power others screens
		GUICtrlSetData($inputPath, $CmdLine[1])
		setwallpaperMultiScreen($CmdLine[2])
	Else
		GUICtrlSetData($inputPath, $CmdLine[1])
		setwallpaper()
		Run(@WorkingDir & "\tools\autoPause.exe", "", @SW_HIDE)
	EndIf
	Exit	
EndIf

;Detect multiple screen 
$multiScreen = False
If int(_WinAPI_GetSystemMetrics($SM_CMONITORS)) > 1 Then
	$aBox = MsgBox(4, "Multi-screen detected", "Do you want run AutoWall in multi-screen mode?")
	If $aBox = 6 Then
		$multiScreen = True
	ElseIf $aBox = 7 Then
		$multiScreen = False
	EndIf
EndIf

If Not $multiScreen Then
	;Wallpaper stop when isnt visible
	Run(@WorkingDir & "\tools\autoPause.exe", "", @SW_HIDE)
EndIf


;Init gui
GUISetState(@SW_SHOW)
GUICtrlSendMsg($inputPath, $EM_SETCUEBANNER, False, "Browse and select video")
GUICtrlSetState($winStart, $GUI_DISABLE)

If $multiScreen Then ;Init gui multiScreen
	GUICtrlSetState($applyb, $GUI_DISABLE)
	GUICtrlSetState($browseb, $GUI_DISABLE)
	_GUICtrlComboBox_SetItemHeight($comboScreens, 17)
	For $i = 0 To int(_WinAPI_GetSystemMetrics($SM_CMONITORS)) -1
		GUICtrlSetData($comboScreens, "Apply on screen " & $i+1)
	Next
Else
	GUICtrlSetState($comboScreens, $GUI_HIDE)
EndIf

;Check updates
Run(@WorkingDir & "\tools\updater.exe", "", @SW_HIDE)

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
		Case $applyb
			If $multiScreen Then
				setwallpaperMultiScreen()
			Else
				setwallpaper()
			EndIf
		Case $browseb
			browsefiles()
		case $comboScreens
			GUICtrlSetState($applyb, $GUI_ENABLE)
			GUICtrlSetState($browseb, $GUI_ENABLE)
			GUICtrlSetState($winStart, $GUI_UNCHECKED)
			GUICtrlSetState($winStart, $GUI_DISABLE)
			GUICtrlSetData($inputPath, "")
		Case $winStart
			onWinStart()
		Case $resetb
			reset()
	EndSwitch
WEnd

Func onWinStart()
	If GUICtrlRead($winStart) = $GUI_CHECKED Then
		$FileName = @WorkingDir & "\AutoWall.exe"
		$args = GUICtrlRead($inputPath)
		
		If $multiScreen Then
			$LinkFileName = @AppDataDir & "\Microsoft\Windows\Start Menu\Programs\Startup\" & "\AutoWall"& (_GUICtrlComboBox_GetCurSel($comboScreens)+1)&".lnk"
			$WorkingDirectory = @WorkingDir
			FileCreateShortcut($FileName, $LinkFileName, $WorkingDirectory, '"' & $args & '" '& (_GUICtrlComboBox_GetCurSel($comboScreens)+1), "", "", "", "", @SW_SHOWNORMAL)
		Else
			$LinkFileName = @AppDataDir & "\Microsoft\Windows\Start Menu\Programs\Startup\" & "\AutoWall.lnk"
			$WorkingDirectory = @WorkingDir
			FileCreateShortcut($FileName, $LinkFileName, $WorkingDirectory, '"' & $args & '"', "", "", "", "", @SW_SHOWNORMAL)
		EndIf
	Else	
		FileDelete(@AppDataDir & "\Microsoft\Windows\Start Menu\Programs\Startup\AutoWall.lnk")
		
		If $multiScreen Then 
				FileDelete(@AppDataDir & "\Microsoft\Windows\Start Menu\Programs\Startup\AutoWall"&(_GUICtrlComboBox_GetCurSel($comboScreens)+1)&".lnk")
		EndIf
		
	EndIf
EndFunc   ;==>onWinStart

Func setwallpaperMultiScreen($screenNumber = 0)
	$oldwork = @WorkingDir
	$weebp = @WorkingDir & "\weebp\wp.exe "
	$webview = @WorkingDir & "\tools\webview.exe"
	
	If Not $autoRunState Then
		$screenNumber = _GUICtrlComboBox_GetCurSel($comboScreens)+1
	EndIf
	
	FileChangeDir(@WorkingDir & "\mpv\")
	
	$inputUdf = GUICtrlRead($inputPath)
	If _WinAPI_UrlIs($inputUdf) == 0 Then
		;This is a temporary solution, usefull to initialize the screens, the first video does not have loop which dying in the end
		
		;Init screen, fake video spawn dying in the end
		RunWait($weebp & "run mpv " & '"' & GUICtrlRead($inputPath) & '"' & " --screen="& $screenNumber &" --player-operation-mode=pseudo-gui --force-window=yes --input-ipc-server=\\.\pipe\mpvsocket", "", @SW_HIDE)
		sleep(500)
		Run($weebp & "add --wait --fullscreen --class mpv", "", @SW_HIDE)
		
		;Final video spawn 
		RunWait($weebp & "run mpv " & '"' & GUICtrlRead($inputPath) & '"' & " --screen="& $screenNumber &" --loop=inf --player-operation-mode=pseudo-gui --force-window=yes --input-ipc-server=\\.\pipe\mpvsocket", "", @SW_HIDE)
		sleep(500)
		Run($weebp & "add --wait --fullscreen --class mpv", "", @SW_HIDE)
	Else
		MsgBox(0, "AutoWall Multi-screen mode", "Web wallpaper is not supported in multi-screen mode")
		GUICtrlSetData($inputPath, "")
	EndIf
	FileChangeDir($oldwork)
EndFunc   ;==>setwallpaperMultiScreen

Func setwallpaper()
	$oldwork = @WorkingDir
	$weebp = @WorkingDir & "\weebp\wp.exe "
	$webview = @WorkingDir & "\tools\webView.exe"

	$inputUdf = GUICtrlRead($inputPath)
	If _WinAPI_UrlIs($inputUdf) == 0 Then
		killAll()
		FileChangeDir(@WorkingDir & "\mpv\")
		Run($weebp & "run mpv " & '"' & GUICtrlRead($inputPath) & '"' & " --loop=inf --player-operation-mode=pseudo-gui --force-window=yes --input-ipc-server=\\.\pipe\mpvsocket", "", @SW_HIDE)
		Run($weebp & "add --wait --fullscreen --class mpv", "", @SW_HIDE)
	Else
		If StringInStr(GUICtrlRead($inputPath), "steamcommunity.com") Then
			$idSteam = StringSplit(GUICtrlRead($inputPath), "?id=", 1)
			GUICtrlSetState($winStart, $GUI_UNCHECKED)
			GUICtrlSetState($winStart, $GUI_DISABLE)
			GUICtrlSetData($inputPath, "")
			MsgBox($MB_TOPMOST, "Download from workshop", "Sorry, AutoWall no longer support steamworkshop downloads.")
		Else
			killAll()
			GUICtrlSetState($applyb, $GUI_DISABLE)
			Run($weebp & " run " & '"' & $webview & '"' & ' "" "' & GUICtrlRead($inputPath) & '"', "", @SW_HIDE)
            ; Loop until the window is found
            Local $hWnd = 0
			While $hWnd = 0
				$hWnd = WinGetHandle("litewebview")
                If $hWnd <> 0 Then ExitLoop ; Exit the loop if the window is found
				Sleep(500) ; Wait for before checking again
            WEnd
			Run($weebp & "add --wait --fullscreen --name litewebview", "", @SW_HIDE)
			GUICtrlSetState($applyb, $GUI_ENABLE)
			GUICtrlSetState($winStart, $GUI_ENABLE)
		EndIf
	EndIf
	FileChangeDir($oldwork)
EndFunc   ;==>setwallpaper


Func browsefiles()
	Local Const $sMessage = "Select the video for wallpaper"
	Local $sFileOpenDialog = FileOpenDialog($sMessage, @WorkingDir & "\VideosHere" & "\", "Videos (*.avi;*.mp4;*.gif;*.mkv;*.webm;*.mts;*.wmv;*.flv;*.mov)", BitOR($FD_FILEMUSTEXIST, $FD_PATHMUSTEXIST))
	If @error Then
		FileChangeDir(@ScriptDir)
	Else
		FileChangeDir(@ScriptDir)
		$sFileOpenDialog = StringReplace($sFileOpenDialog, "|", @CRLF)
		GUICtrlSetData($inputPath, $sFileOpenDialog)
		GUICtrlSetState($winStart, $GUI_ENABLE)
		GUICtrlSetState($winStart, $GUI_UNCHECKED)
	EndIf

EndFunc   ;==>browsefiles

Func reset()
    killAll()
    FileDelete(@AppDataDir & "\Microsoft\Windows\Start Menu\Programs\Startup\AutoWall.lnk")
    FileDelete(@AppDataDir & "\Microsoft\Windows\Start Menu\Programs\Startup\AutoWall*.lnk")

    GUICtrlSetState($winStart, $GUI_UNCHECKED)
    GUICtrlSetData($inputPath, "")
EndFunc   ;==>reset


Func killAll()
    Local $aProcesses = ['mpv.exe', 'wp.exe', 'litewebview.exe', 'Win32WebViewHost.exe', 'autopause.exe']

    For $sProcess In $aProcesses
        Do
            ProcessClose($sProcess)
        Until Not ProcessExists($sProcess)
    Next

    ; Refresh
    Run(@WorkingDir & "\weebp\wp.exe ls", "", @SW_HIDE)
EndFunc   ;==>killAll

