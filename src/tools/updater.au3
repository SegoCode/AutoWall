#include <MsgBoxConstants.au3>
#include <WinAPISys.au3>

Func GetLatestReleaseInfo($sRepoOwner, $sRepoName)
	Local $sURL = "https://api.github.com/repos/" & $sRepoOwner & "/" & $sRepoName & "/releases/latest"
	Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
	$oHTTP.Open("GET", $sURL, False)
	$oHTTP.Send()
	Local $sJSON = $oHTTP.ResponseText
	Return $sJSON
EndFunc

Func ParseJSON($sJSON, $sKey)
	Local $sPattern = '"' & $sKey & '":\s*"([^"]+)"'
	Local $aMatches = StringRegExp($sJSON, $sPattern, 1)
	Return $aMatches[0]
EndFunc

; Main script
Local $sRepoOwner = "SegoCode"
Local $sRepoName = "AutoWall"

; Get latest release info
Local $sJSON = GetLatestReleaseInfo($sRepoOwner, $sRepoName)

; Parse JSON
Local $sTagName = ParseJSON($sJSON, "tag_name")
Local $sBody = ParseJSON($sJSON, "body")
Local $sHtmlUrl = ParseJSON($sJSON, "html_url")

; Read local version
Local $sVersionFile = "tools\version.dat"
Local $sLocalVersion = FileRead($sVersionFile)

; Check version
If $sLocalVersion <> $sTagName Then
	Local $sMessage = "You are running an old version of AutoWall, the latest version is " & $sTagName & _
	@CRLF & "Changes in the latest version:" & @CRLF & @CRLF & $sBody & _
	@CRLF & @CRLF & "Do you want to download the latest version?"
	Local $iResponse = MsgBox($MB_YESNO, "AutoWall Updater, new version is available", $sMessage)
	If $iResponse = $IDYES Then
		ShellExecute($sHtmlUrl)
	EndIf
EndIf