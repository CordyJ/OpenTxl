VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "MathLibrary"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Attribute VB_Ext_KEY = "SavedWithClassBuilder6" ,"Yes"
Attribute VB_Ext_KEY = "Top_Level" ,"Yes"
Option Explicit

Public Function Area(Radius As Single)
    Area = Pi * Radius * Radius
End Function

Public Function Circumference(Radius As Single)
    Circumference = 2 * Pi * Radius
End Function

Public Function Cot(ByVal Radians As Double) As Double
    Dim Sine As Single

    Sine = Sin(Radians)
    If Abs(Sine) <= 0.001 Then
        Cot = 9999.999999
    Else
        Cot = Cos(Radians) / Sine
    End If
End Function

Public Function Csc(ByVal Radians As Double) As Double
    Dim Sine As Single

    Sine = Sin(Radians)
    If Abs(Sine) <= 0.001 Then
        Csc = 9999.999999
    Else
        Csc = 1 / Sine
    End If
End Function

Public Function Degrees(ByVal Radians As Single) As Double
    Degrees = CDbl(Radians) * 180 / Pi
End Function

Public Function Diameter(Radius As Single)
    Diameter = 2 * Radius
End Function

Public Function Milliseconds(ByVal Seconds As Integer) As Single
    Milliseconds = Seconds * (1 / 1000)
End Function

Public Function Pi() As Double
    Pi = 4 * Atn(1)
End Function

Public Function pow(base As Double, expon As Double) As Double
    pow = Exp(expon * Log(base))
End Function

Public Function Radians(ByVal Degrees As Single) As Double
    Radians = CDbl(Degrees) * Pi / 180
End Function

Public Function Radius(X As Single, Y As Single) As Single
    Radius = Sqr(X * X + Y * Y)
End Function

Public Function Sec(ByVal Radians As Double) As Double
    Dim Cosine As Single
  
    Cosine = Cos(Radians)
    If Abs(Cosine) <= 0.001 Then
        Sec = 9999.999999
    Else
        Sec = 1 / Cosine
    End If
End Function

