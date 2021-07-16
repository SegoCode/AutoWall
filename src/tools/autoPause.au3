$pause = False

While 1
    ; Resolution might be changed
    $iW = @DesktopWidth
    $iH = @DesktopHeight
	$Actwin = WinGetHandle("[active]")
    $aPos = WinGetPos($Actwin)
    $sText = WinGetTitle($Actwin)
	
    ; check GUI fill the screen
    If $aPos[2] >= $iW And $aPos[3] >= $iH And StringLen($sText) > 0 Then
		If not $pause Then
			; FullScreen
			Run(@ComSpec & " /c " & "echo cycle pause >\\.\pipe\mpvsocket")
			$pause=True
		EndIf
    Else
		If $pause Then
			; not FullScreen
			Run(@ComSpec & " /c " & "echo cycle pause >\\.\pipe\mpvsocket")
			$pause=False
		EndIf
    EndIf

    Sleep(2000)
WEnd

