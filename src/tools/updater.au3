#include <MsgBoxConstants.au3>
#include <WinAPISys.au3>

; Register a COM error handler
Global $oMyError = ObjEvent("AutoIt.Error", "MyErrFunc")

Func GetLatestReleaseInfo($sRepoOwner, $sRepoName)
    Local $sURL = "https://api.github.com/repos/" & $sRepoOwner & "/" & $sRepoName & "/releases/latest"
    Local $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
    If IsObj($oHTTP) Then
        $oHTTP.Open("GET", $sURL, False)
        $oHTTP.Send()
        If Not @error Then
            Local $sJSON = $oHTTP.ResponseText
            Return $sJSON
        EndIf
    EndIf
    Return SetError(1, 0, "")
EndFunc

Func MyErrFunc()
    ; Do nothing, just return to prevent the default COM error message
    Return SetError(1, 0, "")
EndFunc

Func ParseJSON($sJSON, $sKey)
    Local $sPattern = '"' & $sKey & '":\s*"([^"]+)"'
    Local $aMatches = StringRegExp($sJSON, $sPattern, 1)
    If @error Or Not IsArray($aMatches) Then Return SetError(1, 0, "")
    Return $aMatches[0]
EndFunc

; Main script
Local $sRepoOwner = "SegoCode"
Local $sRepoName = "AutoWall"

; Get latest release info
Local $sJSON = GetLatestReleaseInfo($sRepoOwner, $sRepoName)
If @error Then Exit ; Exit if there is an error in getting the latest release info

; Parse JSON
Local $sTagName = ParseJSON($sJSON, "tag_name")
If @error Then Exit ; Exit if there is an error in parsing the tag name
Local $sBody = ParseJSON($sJSON, "body")
If @error Then Exit ; Exit if there is an error in parsing the body
Local $sHtmlUrl = ParseJSON($sJSON, "html_url")
If @error Then Exit ; Exit if there is an error in parsing the html url

; Read local version
Local $sVersionFile = "tools\version.dat"
Local $sLocalVersion = FileRead($sVersionFile)
If @error Then Exit ; Exit if there is an error in reading the local version file

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
