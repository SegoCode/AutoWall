#NoTrayIcon
#include <Misc.au3>

If _Singleton("AutoWallService", 1) = 0 Then
	Exit
EndIf

$pause = False

While 1
	; Resolution might be changed
	$Pos = WinGetPos("[CLASS:Shell_TrayWnd]")
	$iW = @DesktopWidth
	$iH = @DesktopHeight
	if $Pos <> 0 And $Pos[3] > 0 Then $iH = $iH - $Pos[3]
	$Actwin = WinGetHandle("[active]")
	$aPos = WinGetPos($Actwin)
	$wText = WinGetTitle($Actwin)
	
	; check GUI fill the screen and real gui
	If $aPos <> 0 And $aPos[2] >= $iW And $aPos[3] >= $iH And StringLen($wText) > 0 Then
		If Not $pause Then
			; FullScreen
			Run(@ComSpec & " /c " & "echo cycle pause >\\.\pipe\mpvsocket", "", @SW_HIDE)
			$pause = True
		EndIf
	Else
		If $pause Then
			; not FullScreen
			Run(@ComSpec & " /c " & "echo cycle pause >\\.\pipe\mpvsocket", "", @SW_HIDE)
			$pause = False
		EndIf
	EndIf
	Sleep(2000)
WEnd
