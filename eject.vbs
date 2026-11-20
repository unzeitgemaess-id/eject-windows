Set objShell = CreateObject("WScript.Shell")
strScript = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))

strArgs = ""
If WScript.Arguments.Count > 0 Then
    strArgs = " -DriveLetter " & WScript.Arguments(0)
End If

objShell.Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & strScript & "eject-auto.ps1""" & strArgs, 0, False
