; LiteWebviewIDExtractor.au3
#include <File.au3>
#include <Array.au3>

Func GetLiteWebviewId()
    Local $sFilePath = @TempDir & "\output.txt"
    Local $sCommand = "C:\Users\SegoCode\Desktop\AutoWall\weebp\wp ls > " & $sFilePath
    Run(@ComSpec & " /c " & $sCommand, "", @SW_HIDE, $STDOUT_CHILD)

    ; Wait for the command to complete
    Sleep(2000)

    ; Read the file
    Local $aLines
    _FileReadToArray($sFilePath, $aLines)

    ; Define the regular expression pattern to match the LiteWebview line and extract the ID
    Local $sPattern = "\[\K[0-9A-F]+\b(?=].*LiteWebview)"

    ; Loop through each line to find and extract the LiteWebview ID
    For $i = 1 To $aLines[0]
        Local $sMatch = StringRegExp($aLines[$i], $sPattern, 1)
        If IsArray($sMatch) And UBound($sMatch) > 0 Then
            Return $sMatch[0]
        EndIf
    Next

    ; Return an error if the ID is not found
    Return SetError(1, 0, "LiteWebview ID not found")
EndFunc
