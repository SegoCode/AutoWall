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
#Region ### START Koda GUI section ### Form=
$form = GUICreate("github.com/SegoCode", 513, 72, 183, 124)
$applyb = GUICtrlCreateButton("Apply", 432, 8, 75, 25)
$resetb = GUICtrlCreateButton("Reset", 432, 40, 75, 25)
$browseb = GUICtrlCreateButton("Browse", 352, 40, 75, 25)
$inputPath = GUICtrlCreateInput("Browse and select video", 8, 8, 417, 25)
$winStart = GUICtrlCreateCheckbox("Set on windows startup", 8, 40, 137, 25)
Opt("TrayMenuMode", 1)
Opt("TrayOnEventMode", 1)
GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###
GUICtrlSetState($winStart, $GUI_DISABLE)

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE
			Exit
		Case $applyb
			setwallpaper()
		Case $browseb
			browsefiles()
		Case $winStart
			onWinStart()
		Case $resetb
			reset()
	EndSwitch
WEnd

Func onWinStart()
	; I hate path quotation marks on batch
	If GUICtrlRead($winStart) = $GUI_CHECKED Then
		FileDelete(@AppDataDir & "\Microsoft\Windows\Start Menu\Programs\Startup\livewallpaper.bat")
		$file = FileOpen(@AppDataDir & "\Microsoft\Windows\Start Menu\Programs\Startup\livewallpaper.bat", 1)
		ConsoleWrite(@WorkingDir)
		FileWrite($file, "@echo off" & @CRLF)
		FileWrite($file, "cd " & '"' & @WorkingDir & "\weebp\" & '"' & @CRLF)
		FileWrite($file, "wp id > tmpFile" & @CRLF)
		FileWrite($file, "set /p wId= < tmpFile" & @CRLF)
		FileWrite($file, "del tmpFile" & @CRLF)
		FileWrite($file, "cd " & '"' & @WorkingDir & "\mpv\" & '"' & @CRLF)
		FileWrite($file, '"' & @WorkingDir & "\weebp\wp.exe" & '"' & " run mpv --wid=%wId% " & '"' & GUICtrlRead($inputPath) & '"' & " --loop=inf --player-operation-mode=pseudo-gui --force-window=yes --no-audio")
		FileClose($file)
	Else
		FileDelete(@AppDataDir & "\Microsoft\Windows\Start Menu\Programs\Startup\livewallpaper.bat")
	EndIf

EndFunc   ;==>onWinStart

Func setwallpaper()
	Do
		ProcessClose('mpv.exe')
	Until Not ProcessExists('mpv.exe')
	$weebp = @WorkingDir & "\weebp\wp.exe "
	$pid = Run($weebp & "id", "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
	ProcessWait($pid)
	$oldwork = @WorkingDir
	FileChangeDir(@WorkingDir & "\mpv\")
	Run($weebp & "run mpv --wid=" & StdoutRead($pid) & " " & '"' & GUICtrlRead($inputPath) & '"' & " --loop=inf --player-operation-mode=pseudo-gui --force-window=yes --no-audio")
	FileChangeDir($oldwork)
EndFunc   ;==>setwallpaper

Func browsefiles()

	Local Const $sMessage = "Select the video for wallpaper"
	Local $sFileOpenDialog = FileOpenDialog($sMessage, @WorkingDir & "\VideosHere" & "\", "Videos (*.avi;*.mp4;*.gif;*.mov)", BitOR($FD_FILEMUSTEXIST, $FD_PATHMUSTEXIST))
	If @error Then
		MsgBox($MB_SYSTEMMODAL, "", "No file were selected.")
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
	Do
		ProcessClose('mpv.exe')
	Until Not ProcessExists('mpv.exe')
	FileDelete(@AppDataDir & "\Microsoft\Windows\Start Menu\Programs\Startup\livewallpaper.bat")
	GUICtrlSetState($winStart, $GUI_UNCHECKED)
	GUICtrlSetData($inputPath, "")

EndFunc   ;==>reset


