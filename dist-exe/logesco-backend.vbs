Set WshShell = CreateObject("WScript.Shell")
strDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
WshShell.Run Chr(34) & strDir & "\node.exe" & Chr(34) & " " & Chr(34) & strDir & "\src\server.js" & Chr(34), 0, False
