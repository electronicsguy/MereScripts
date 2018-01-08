Option Explicit

Sub CSV2ROWS_Extrapolated()
    ' Will take CSV values in a row-cell, convert it into multiple rows
    ' by inserting additional required rows below, and will copy
    ' the contents of the rest of the row into each created row
    ' eg: row1:   a  b  x1,x2,x3,x4  d
    ' becomes
    '     row1:   a  b  x1  d
    '     row2:   a  b  x2  d
    '     row3:   a  b  x3  d
    '     row4:   a  b  x4  d

    Dim InputRng As Range, OutRng As Range
    Dim xTitleId As String

    Dim arr() As String

    Dim count As Integer

    Dim i As Integer

    On Error Resume Next

    xTitleId = "CSV2ROWS_Extrapolated"

    Set InputRng = Application.InputBox("Range(single cell) :", xTitleId, Application.Selection.Range("A1").Address, Type:=8)

    ' https://stackoverflow.com/questions/32634800/cant-cancel-application-inputbox-properly
    If Err.Number = 424 Then
        ' Handle cancel button
        Debug.Print "User cancelled"
        Exit Sub
    ElseIf Err.Number <> 0 Then
        ' Handle unexpected error
        Debug.Print "Unexpected error"
    End If

    On Error GoTo 0

    ' Disable worksheet update for faster execution speed
    Application.ScreenUpdating = False

    ' Split the Cell CSV values into an array
    arr = VBA.Split(InputRng.Value, ",")
    count = UBound(arr) - LBound(arr) + 1

    ' Insert required number of rows below
    For i = 1 To (count - 1)
        Rows((InputRng.Row + 1)).EntireRow.Insert
    Next

    ' Copy this row to every inserted new row
    For i = 1 To (count - 1)
        Rows((InputRng.Row + i)).EntireRow.Value = Rows(InputRng.Row).EntireRow.Value
    Next

    ' Transpose the array and copy to destination column
    InputRng.Resize(UBound(arr) - LBound(arr) + 1).Value = Application.Transpose(arr)

    ' Clear clipboard
    Application.CutCopyMode = False
    ' Update worksheet
    Application.ScreenUpdating = True

End Sub
