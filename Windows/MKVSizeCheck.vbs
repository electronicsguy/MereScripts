' This script enables you to open .mkv files with different application, based in the 
' size of the file
'
' (C) Sujay Phadke, 2015
' Documentation here:
' http://superuser.com/questions/921488/windows-file-association-based-on-file-type-and-then-size/921502
'
Option Explicit
'
' Invoked from this registry entry:
' HKEY_CLASSES_ROOT\VLC.mkv\shell\Open\command
'
' Note: if you want the MsgBox to work, remove the
' "//B" switch from the data in the above registry key
'
Dim mediaSize
Dim objArgs
Dim objShell
Dim objFSO

' set 4GB limit
mediaSize = 4*1024*1024*1024

set objArgs = WScript.Arguments
set objShell = WScript.CreateObject("WScript.Shell")
set objFSO = WScript.CreateObject("Scripting.FileSystemObject")

if objFSO.GetFile(objArgs.Item(0)).Size <= mediaSize then
'	MsgBox "Lesser"
	objShell.Run """C:\Program Files\VideoLAN\VLC\vlc.exe"" """ &   objArgs.Item(0) & """", 3, false
else
'	MsgBox "Greater"
	objShell.Run """C:\Program Files (x86)\CyberLink\PowerDVD9\PowerDVD9.exe"" """ & objArgs.Item(0) & """", 3, false
end if


WScript.Quit 0
