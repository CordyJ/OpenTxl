Attribute VB_Name = "FileSearchMod"
'***This module is used to find files, and its path***'

Option Explicit
Public ReturnFileName() As String   'Holds an array of Filenames to later on be saved in db
Public ReturnPath() As String       'Holds an array of paths
Public noOfFiles As Long            'Holds the number of files found matching SearchStr

'***FileFinding API***'
Private Declare Function FindFirstFile Lib "kernel32" Alias "FindFirstFileA" (ByVal lpFileName As String, lpFindFileData As WIN32_FIND_DATA) As Long
Private Declare Function FindNextFile Lib "kernel32" Alias "FindNextFileA" (ByVal hFindFile As Long, lpFindFileData As WIN32_FIND_DATA) As Long
Private Declare Function GetFileAttributes Lib "kernel32" Alias "GetFileAttributesA" (ByVal lpFileName As String) As Long
Private Declare Function FindClose Lib "kernel32" (ByVal hFindFile As Long) As Long

Const MAX_PATH = 260
Const MAXDWORD = &HFFFF
Const INVALID_HANDLE_VALUE = -1
Const FILE_ATTRIBUTE_ARCHIVE = &H20
Const FILE_ATTRIBUTE_DIRECTORY = &H10
Const FILE_ATTRIBUTE_HIDDEN = &H2
Const FILE_ATTRIBUTE_NORMAL = &H80
Const FILE_ATTRIBUTE_READONLY = &H1
Const FILE_ATTRIBUTE_SYSTEM = &H4
Const FILE_ATTRIBUTE_TEMPORARY = &H100

Private Type FILETIME
    dwLowDateTime As Long
    dwHighDateTime As Long
End Type

Private Type WIN32_FIND_DATA
    dwFileAttributes As Long
    ftCreationTime As FILETIME
    ftLastAccessTime As FILETIME
    ftLastWriteTime As FILETIME
    nFileSizeHigh As Long
    nFileSizeLow As Long
    dwReserved0 As Long
    dwReserved1 As Long
    cFileName As String * MAX_PATH
    cAlternate As String * 14
End Type

Private Function StripNulls(OriginalStr As String) As String
If (InStr(OriginalStr, Chr(0)) > 0) Then
    OriginalStr = Left(OriginalStr, InStr(OriginalStr, Chr(0)) - 1)
End If
StripNulls = OriginalStr
End Function

Public Sub FindFiles(path As String, SearchStr As String)
Dim FileName As String
Dim DirName As String
Dim dirNames() As String
Dim nDir As Integer
Dim i As Integer
Dim hSearch As Long
Dim WFD As WIN32_FIND_DATA
Dim Cont As Integer
Dim g As Integer
Dim highNumber As Integer

If Right(path, 1) <> "\" Then path = path & "\"
' Search for subdirectories.
nDir = 0
ReDim dirNames(nDir)
Cont = True
hSearch = FindFirstFile(path & "*", WFD)
If hSearch <> INVALID_HANDLE_VALUE Then
    Do While Cont
    DirName = StripNulls(WFD.cFileName)
    If (DirName <> ".") And (DirName <> "..") Then
        ' Check for directory
        If GetFileAttributes(path & DirName) And FILE_ATTRIBUTE_DIRECTORY Then
            If DirName <> "RECYCLER" Then 'Do not list subdirs/files in recycle bin
                dirNames(nDir) = DirName
                nDir = nDir + 1
                ReDim Preserve dirNames(nDir)
            End If
        End If
    End If
    Cont = FindNextFile(hSearch, WFD) 'Get next subdirectory.
    DoEvents
    Loop
    Cont = FindClose(hSearch)
End If
' Walk through this directory.
hSearch = FindFirstFile(path & SearchStr, WFD)
Cont = True
If hSearch <> INVALID_HANDLE_VALUE Then
    While Cont
        FileName = StripNulls(WFD.cFileName)
        If (FileName <> ".") And (FileName <> "..") Then
            If Not GetFileAttributes(path & FileName) And FILE_ATTRIBUTE_DIRECTORY Then
                    On Error GoTo ErrHandler
                    noOfFiles = noOfFiles + 1
                    ReDim Preserve ReturnPath(noOfFiles)
                    ReDim Preserve ReturnFileName(noOfFiles)
                    ReturnPath(noOfFiles) = path
                    ReturnFileName(noOfFiles) = FileName
            End If
        End If
        Cont = FindNextFile(hSearch, WFD)
        DoEvents
    Wend
    Cont = FindClose(hSearch)
End If
' If there are sub-directories...
If nDir > 0 Then
    For i = 0 To nDir - 1
        Call FindFiles(path & dirNames(i) & "\", SearchStr)
    Next i
End If
ErrHandler:
If Err.Number <> 0 Then
    MsgBox Err.Number & " " & Err.Description
End If
End Sub


