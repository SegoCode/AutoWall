#NoTrayIcon
#include <Misc.au3>
#include <AutoItConstants.au3>

If _Singleton("AutoWallService", 1) = 0 Then
	Exit
EndIf

$pause = False

While 1
	; Resolution might be changed
	$iW = @DesktopWidth
	$iH = @DesktopHeight
	
	$Actwin = WinGetHandle("[active]")
	
	$aPos = WinGetPos($Actwin)
	$wText = WinGetTitle($Actwin)

	; Check if window should be excluded from detection
	$bExcludeWindow = False

	; Exclude "Program Manager"
	If $wText = "Program Manager" Then
		$bExcludeWindow = True
	EndIf

	; Exclude any mpv windows (containing "mpv" in title)
	If StringInStr($wText, "mpv") Then
		$bExcludeWindow = True
	EndIf

	; check GUI fill the screen and real gui, but only if it's not excluded
	If Not $bExcludeWindow And (($aPos <> 0 And $aPos[2] >= $iW And $aPos[3] >= $iH And StringLen($wText) > 0) Or BitAND(WinGetState($Actwin), $WIN_STATE_MAXIMIZED)) Then
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
	Sleep(100)
WEnd
