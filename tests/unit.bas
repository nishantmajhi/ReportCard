' ========================================================
'  unit.bas -- checks for REPORT.BAS's FUNCTIONs
'
'  Not a program on its own. tests\run.ps1 splices the part
'  above the PROCEDURES marker into a copy of REPORT.BAS in
'  place of its launch block (ShowWelcome / MainMenu / End),
'  and appends the part below the marker after REPORT.BAS's
'  own procedures. So every check here calls the real code,
'  with the real constants and subject table.
'
'  Each check prints one line: "ok - <label>" or
'  "not ok - <label>: got <x>, want <y>".
' ========================================================

Dim Shared checkCount As Integer
Dim Shared failCount As Integer
Dim m(1 To NSUBS) As Integer

' ---- GetGrade$: the bands in the README, at both edges of each ----
CheckStr "GetGrade$ 100", GetGrade$(100), "A+"
CheckStr "GetGrade$ 90", GetGrade$(90), "A+"
CheckStr "GetGrade$ 89.8", GetGrade$(89.8), "A"
CheckStr "GetGrade$ 80", GetGrade$(80), "A"
CheckStr "GetGrade$ 79.8", GetGrade$(79.8), "B+"
CheckStr "GetGrade$ 70", GetGrade$(70), "B+"
CheckStr "GetGrade$ 69", GetGrade$(69), "B"
CheckStr "GetGrade$ 60", GetGrade$(60), "B"
CheckStr "GetGrade$ 59.8", GetGrade$(59.8), "C+"
CheckStr "GetGrade$ 50", GetGrade$(50), "C+"
CheckStr "GetGrade$ 49", GetGrade$(49), "C"
CheckStr "GetGrade$ 40 (the pass mark)", GetGrade$(40), "C"
CheckStr "GetGrade$ 39.8", GetGrade$(39.8), "F"
CheckStr "GetGrade$ 0", GetGrade$(0), "F"

' ---- An average is total / NSUBS, so it moves in steps of 0.2 ----
' The step just below each band edge has to land in the lower band.
CheckStr "GetGrade$ of 449/5", GetGrade$(449 / NSUBS), "A"
CheckStr "GetGrade$ of 450/5", GetGrade$(450 / NSUBS), "A+"
CheckStr "GetGrade$ of 199/5", GetGrade$(199 / NSUBS), "F"
CheckStr "GetGrade$ of 200/5", GetGrade$(200 / NSUBS), "C"

' ---- CalcTotal% ----
SetMarks m(), 90, 80, 70, 60, 50
CheckInt "CalcTotal% 90+80+70+60+50", CalcTotal%(m()), 350
SetMarks m(), 100, 100, 100, 100, 100
CheckInt "CalcTotal% full marks", CalcTotal%(m()), NSUBS * FULL_MARK
SetMarks m(), 0, 0, 0, 0, 0
CheckInt "CalcTotal% all zero", CalcTotal%(m()), 0

' ---- FindMaxIdx% / FindMinIdx%: a tie goes to the first subject ----
SetMarks m(), 50, 90, 90, 10, 10
CheckInt "FindMaxIdx% first of two highest", FindMaxIdx%(m()), 2
CheckInt "FindMinIdx% first of two lowest", FindMinIdx%(m()), 4
SetMarks m(), 70, 70, 70, 70, 70
CheckInt "FindMaxIdx% all equal", FindMaxIdx%(m()), 1
CheckInt "FindMinIdx% all equal", FindMinIdx%(m()), 1
SetMarks m(), 10, 20, 30, 40, 100
CheckInt "FindMaxIdx% last subject", FindMaxIdx%(m()), 5
CheckInt "FindMinIdx% first subject", FindMinIdx%(m()), 1

' ---- CountPass%: PASS_MARK itself passes ----
SetMarks m(), 40, 39, 100, 0, 41
CheckInt "CountPass% 40 passes, 39 does not", CountPass%(m()), 3
SetMarks m(), 0, 0, 0, 0, 0
CheckInt "CountPass% none", CountPass%(m()), 0
SetMarks m(), 100, 100, 100, 100, 100
CheckInt "CountPass% all", CountPass%(m()), NSUBS

' ---- ParseMark%: a whole number from 0 to FULL_MARK, or -1 ----
CheckInt "ParseMark% 0", ParseMark%("0"), 0
CheckInt "ParseMark% 100", ParseMark%("100"), 100
CheckInt "ParseMark% 40", ParseMark%("40"), 40
CheckInt "ParseMark% spaces around", ParseMark%("  75  "), 75
CheckInt "ParseMark% leading zeros", ParseMark%("007"), 7
CheckInt "ParseMark% 0100", ParseMark%("0100"), 100
CheckInt "ParseMark% 101", ParseMark%("101"), -1
CheckInt "ParseMark% empty", ParseMark%(""), -1
CheckInt "ParseMark% only spaces", ParseMark%("   "), -1
CheckInt "ParseMark% negative", ParseMark%("-1"), -1
CheckInt "ParseMark% minus zero", ParseMark%("-0"), -1
CheckInt "ParseMark% plus sign", ParseMark%("+50"), -1
CheckInt "ParseMark% decimal", ParseMark%("8.5"), -1
CheckInt "ParseMark% trailing point", ParseMark%("85."), -1
CheckInt "ParseMark% letters", ParseMark%("abc"), -1
CheckInt "ParseMark% letter O for zero", ParseMark%("5O"), -1
CheckInt "ParseMark% exponent", ParseMark%("1E2"), -1
CheckInt "ParseMark% two numbers", ParseMark%("50,60"), -1
CheckInt "ParseMark% space inside", ParseMark%("5 0"), -1
CheckInt "ParseMark% past INTEGER", ParseMark%("65586"), -1
CheckInt "ParseMark% far past INTEGER", ParseMark%("99999999999999999999"), -1

' ---- The subject table the report card and file format rely on ----
CheckInt "NSUBS", NSUBS, 5
CheckStr "subject 1", LTrim$(RTrim$(subName(1))), "Mathematics"
CheckStr "subject 4", LTrim$(RTrim$(subName(4))), "Social Studies"
CheckStr "subject 5", LTrim$(RTrim$(subName(5))), "Computer"

Print "summary"; checkCount; failCount
System

' ==== PROCEDURES ====

Sub SetMarks (marks() As Integer, a As Integer, b As Integer, c As Integer, d As Integer, e As Integer)
    marks(1) = a: marks(2) = b: marks(3) = c: marks(4) = d: marks(5) = e
End Sub

Sub CheckInt (label As String, got As Integer, want As Integer)
    checkCount = checkCount + 1
    If got = want Then
        Print "ok - " + label
    Else
        failCount = failCount + 1
        Print "not ok - " + label + ": got" + Str$(got) + ", want" + Str$(want)
    End If
End Sub

Sub CheckStr (label As String, got As String, want As String)
    checkCount = checkCount + 1
    If got = want Then
        Print "ok - " + label
    Else
        failCount = failCount + 1
        Print "not ok - " + label + ": got [" + got + "], want [" + want + "]"
    End If
End Sub
