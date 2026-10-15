' ========================================================
'        STUDENT REPORT CARD SYSTEM
'             A QBASIC Project
'
'  Topics Covered:
'    Syllabus of Grade 8, 9 & 10
'  Board:
'     SEE, Nepal
'
' ========================================================

DECLARE SUB ShowWelcome ()
DECLARE SUB MainMenu ()
DECLARE SUB AddStudent ()
DECLARE SUB ViewReport ()
DECLARE SUB ClassRankList ()
DECLARE SUB DrawLine (ch AS STRING, n AS INTEGER)
DECLARE SUB DrawBarChart (marks() AS INTEGER)
DECLARE FUNCTION GetGrade$ (avg AS SINGLE)
DECLARE FUNCTION CalcTotal% (marks() AS INTEGER)
DECLARE FUNCTION FindMaxIdx% (marks() AS INTEGER)
DECLARE FUNCTION FindMinIdx% (marks() AS INTEGER)
DECLARE FUNCTION CountPass% (marks() AS INTEGER)
DECLARE FUNCTION ParseMark% (text AS STRING)

' ========================================================
'  CONSTANTS  (Grade 8: Constants)
' ========================================================
' NSUBS is also the number of marks in every students.dat
' record. The WRITE #1 and INPUT #1 lines name m1 to m5 one
' by one, so a sixth subject means changing those lines too,
' and a file written with five marks would no longer load.
Const NSUBS = 5
Const PASS_MARK = 40
Const FULL_MARK = 100
Const DATAFILE = "students.dat"
Const BOXW = 50
Const MAX_BARS = 20

' ========================================================
'  SHARED GLOBAL ARRAY FOR SUBJECT NAMES  (Grade 9: Arrays)
' ========================================================
Dim Shared subName(1 To NSUBS) As String
subName(1) = "Mathematics   "
subName(2) = "Science       "
subName(3) = "English       "
subName(4) = "Social Studies"
subName(5) = "Computer      "

' ---- Ensure data file exists before reading ----
Open DATAFILE For Append As #1
Close #1

' ---- Launch Program ----
ShowWelcome
MainMenu
End


' ========================================================
'  SUB ShowWelcome
'  Displays welcome screen with decorative patterns
'  (Grade 9: Pattern Printing using Loops + IF-ELSE)
' ========================================================
Sub ShowWelcome
    Cls
    Color 14, 0
    Print
    ' Pattern 1: Double top border using FOR loop
    For i = 1 To 2
        Print String$(BOXW, "*")
    Next i
    Print "**"; Space$(BOXW - 4); "**"
    Print "**"; Tab(13); "STUDENT REPORT CARD SYSTEM"; Tab(BOXW - 1); "**"
    Print "**"; Tab(17); "A  QBASIC  PROJECT"; Tab(BOXW - 1); "**"
    Print "**"; Tab(12); "Grade 8-10 Learning Showcase"; Tab(BOXW - 1); "**"
    Print "**"; Space$(BOXW - 4); "**"
    For i = 1 To 2
        Print String$(BOXW, "*")
    Next i

    Print
    Color 11, 0

    ' Pattern 2: Alternating =-=  line (Loop + IF-ELSE)
    For i = 1 To BOXW
        If i Mod 2 = 0 Then
            Print "=";
        Else
            Print "-";
        End If
    Next i
    Print

    Color 7, 0
    Print
    Print "   Press any key to enter the system..."
    Sleep
End Sub


' ========================================================
'  SUB MainMenu
'  Main navigation menu using SELECT CASE
'  (Grade 9: SELECT CASE | Grade 9: DO-LOOP)
' ========================================================
Sub MainMenu
    Dim choice As Integer

    Do
        Cls
        Color 11, 0
        Print String$(BOXW, "=")
        Print "="; Tab(21); "MAIN MENU"; Tab(BOXW); "="
        Print String$(BOXW, "=")
        Color 7, 0
        Print
        Print "    1.  Add New Student"
        Print "    2.  View Student Report Card"
        Print "    3.  View Class Rank List"
        Print "    4.  Exit"
        Print
        DrawLine "-", BOXW
        Color 14, 0
        Print "    Your choice (1-4): ";
        Color 7, 0
        Input "", choice
        Print

        ' Grade 9: SELECT CASE for menu navigation
        Select Case choice
            Case 1
                AddStudent
            Case 2
                ViewReport
            Case 3
                ClassRankList
            Case 4
                Cls
                Print
                Color 14, 0
                Print "  Thank you for using Student Report Card System!"
                Print "  Goodbye!"
                Color 7, 0
                End
            Case Else
                Color 12, 0
                Print "  Invalid choice! Please enter a number from 1 to 4."
                Color 7, 0
                Sleep 2
        End Select
    Loop
End Sub


' ========================================================
'  SUB AddStudent
'  Takes student input, validates, and saves to file
'  (Grade 8: Variables, Input/Output, IF-ELSE)
'  (Grade 9: FOR Loop, DO-WHILE Loop, Arrays)
'  (Grade 10: SUB Procedures, File Handling - APPEND)
' ========================================================
Sub AddStudent
    Cls
    Dim sName As String
    Dim marks(1 To NSUBS) As Integer
    Dim markText As String
    Dim i As Integer
    Dim valid As Integer
    Dim needBreak As Integer
    Dim lastChar As String * 1

    Color 11, 0
    DrawLine "=", BOXW
    Print "  ADD NEW STUDENT"
    DrawLine "=", BOXW
    Color 7, 0
    Print

    ' --- Input student name (Grade 8: Variables, Input) ---
    Print "  Student Name : ";
    Line Input "", sName
    sName = LTrim$(RTrim$(sName))

    ' Validate: name cannot be empty (Grade 8: IF-ELSE)
    If sName = "" Then
        Color 12, 0
        Print "  Error: Name cannot be empty!"
        Color 7, 0
        Sleep 2
        Exit Sub
    End If

    ' WRITE # cannot escape a quote inside a name, so INPUT # would
    ' read such a record back as a different, shorter name
    If InStr(sName, Chr$(34)) > 0 Then
        Color 12, 0
        Print "  Error: Name cannot contain a double quote (" + Chr$(34) + ")."
        Color 7, 0
        Sleep 2
        Exit Sub
    End If

    Print
    Print "  Enter marks for each subject (0 to 100):"
    DrawLine "-", BOXW

    ' --- Input and validate marks (Grade 9: FOR Loop + Arrays) ---
    ' Read as text, not with INPUT into an INTEGER: that turns an empty
    ' line into 0, and QB64 drops a "." as it is typed, so 8.5 became 85.
    For i = 1 To NSUBS
        valid = 0
        Do While valid = 0
            Print "  " + subName(i) + " : ";
            Line Input "", markText
            marks(i) = ParseMark%(markText)
            ' Range validation (Grade 8: IF-ELSE)
            If marks(i) >= 0 And marks(i) <= FULL_MARK Then
                valid = 1
            Else
                Color 12, 0
                Print "  Invalid! Marks must be between 0 and 100."
                Color 7, 0
            End If
        Loop
    Next i

    ' --- Check the file ends with a line break (Grade 10: File Handling) ---
    ' A file edited in Notepad may not, and WRITE # would then join the
    ' new record onto the end of the last one
    needBreak = 0
    Open DATAFILE For Binary As #1
    If LOF(1) > 0 Then
        Get #1, LOF(1), lastChar
        If lastChar <> Chr$(10) Then needBreak = 1
    End If
    Close #1

    ' --- Save record to file using APPEND (Grade 10: File Handling) ---
    Open DATAFILE For Append As #1
    If needBreak = 1 Then Print #1, ""
    Write #1, sName, marks(1), marks(2), marks(3), marks(4), marks(5)
    Close #1

    Print
    Color 10, 0
    Print "  [OK] '" + sName + "' has been saved successfully!"
    Color 7, 0
    Print "  Press any key to return to menu..."
    Sleep
End Sub


' ========================================================
'  SUB ViewReport
'  Searches for student, loads data, shows report card
'  (Grade 8: IF-ELSE, String Functions)
'  (Grade 9: Loops, Arrays, Patterns, Algorithms)
'  (Grade 10: File Handling, SUBs, Functions)
' ========================================================
Sub ViewReport
    Cls
    Dim searchName As String
    Dim sName As String
    Dim marks(1 To NSUBS) As Integer
    Dim m1 As Integer, m2 As Integer, m3 As Integer
    Dim m4 As Integer, m5 As Integer
    Dim found As Integer
    Dim total As Integer
    Dim avg As Single
    Dim i As Integer
    Dim passCount As Integer
    Dim maxIdx As Integer
    Dim minIdx As Integer
    Dim grade As String
    Dim status As String

    Color 11, 0
    DrawLine "=", BOXW
    Print "  VIEW STUDENT REPORT CARD"
    DrawLine "=", BOXW
    Color 7, 0
    Print
    Print "  Enter student name to search: ";
    Line Input "", searchName
    searchName = LTrim$(RTrim$(searchName))

    found = 0

    ' --- Open file and search record (Grade 10: File Handling - INPUT) ---
    Open DATAFILE For Input As #1
    Do While Not EOF(1)
        Input #1, sName
        ' A blank line, left by editing the file by hand, is skipped
        If sName <> "" Then
            Input #1, m1, m2, m3, m4, m5
            ' Case-insensitive name matching (Grade 8: IF-ELSE + String Functions)
            If UCase$(LTrim$(RTrim$(sName))) = UCase$(searchName) Then
                found = 1
                marks(1) = m1: marks(2) = m2: marks(3) = m3
                marks(4) = m4: marks(5) = m5
            End If
        End If
    Loop
    Close #1

    ' --- Handle not found (Grade 8: IF-ELSE) ---
    If found = 0 Then
        Print
        Color 12, 0
        Print "  Student '" + searchName + "' was not found in records!"
        Color 7, 0
        Print "  Press any key to return..."
        Sleep
        Exit Sub
    End If

    ' --- Calculate results using Functions (Grade 10: Functions) ---
    total = CalcTotal%(marks())
    avg = total / NSUBS
    passCount = CountPass%(marks())
    maxIdx = FindMaxIdx%(marks())
    minIdx = FindMinIdx%(marks())

    ' ===========================================
    '   DISPLAY THE FORMATTED REPORT CARD
    ' ===========================================
    Cls
    Print
    Color 14, 0

    ' Pattern: Report card outer box border (Grade 9: Pattern Printing)
    Print String$(BOXW, "*")
    Print "*"; Space$(BOXW - 2); "*"
    Print "*"; Tab(16); "STUDENT REPORT CARD"; Tab(BOXW); "*"
    Print "*"; Space$(BOXW - 2); "*"
    Print String$(BOXW, "*")

    Color 7, 0
    Print
    Print "  Name        : " + sName
    DrawLine "=", BOXW

    Color 11, 0
    Print "  SUBJECT            MARKS      GRADE   STATUS"
    DrawLine "-", BOXW
    Color 7, 0

    ' --- Display each subject row (Grade 9: FOR Loop + Arrays) ---
    For i = 1 To NSUBS
        grade = GetGrade$(marks(i))

        ' Color and status based on pass/fail (Grade 8: IF-ELSE)
        If marks(i) >= PASS_MARK Then
            status = "PASS"
            Color 10, 0
        Else
            status = "FAIL"
            Color 12, 0
        End If

        Print "  " + subName(i) + "  " + LTrim$(Str$(marks(i))) + " / " + LTrim$(Str$(FULL_MARK)) + "       " + grade + "      " + status
        Color 7, 0
    Next i

    DrawLine "=", BOXW
    Color 14, 0
    Print "  Total Marks : " + LTrim$(Str$(total)) + " / " + LTrim$(Str$(NSUBS * FULL_MARK))
    Print "  Percentage  : " + LTrim$(Str$(Int(avg * 10 + .5) / 10)) + " %"
    Print "  Final Grade : " + GetGrade$(avg)
    Print "  Passed      : " + LTrim$(Str$(passCount)) + " out of " + LTrim$(Str$(NSUBS)) + " subjects"
    Print "  Failed      : " + LTrim$(Str$(NSUBS - passCount)) + " subject(s)"

    DrawLine "-", BOXW
    Color 11, 0
    ' Max/Min algorithm results (Grade 9: Algorithms)
    Print "  Best Subject  : " + LTrim$(RTrim$(subName(maxIdx)))
    Print "  Weak Subject  : " + LTrim$(RTrim$(subName(minIdx)))

    ' --- Remark using nested IF-ELSE (Grade 8: IF-ELSE) ---
    Print
    Color 13, 0
    If avg >= 90 Then
        Print "  Remark : Outstanding! You are a star student!"
    ElseIf avg >= 75 Then
        Print "  Remark : Excellent work! Keep it up."
    ElseIf avg >= 60 Then
        Print "  Remark : Good. Push harder to reach excellence!"
    ElseIf avg >= PASS_MARK Then
        Print "  Remark : Passed. Focus more on weak subjects."
    Else
        Print "  Remark : Failed. Work harder and try again!"
    End If

    DrawLine "=", BOXW
    Print

    ' --- Bar chart (Grade 9: Pattern Printing + Math Algorithm) ---
    Color 14, 0
    Print "  MARKS BAR CHART  (each block = 5 marks):"
    DrawLine "-", BOXW
    DrawBarChart marks()

    DrawLine "*", BOXW
    Color 7, 0
    Print
    Print "  Press any key to return to menu..."
    Sleep
End Sub


' ========================================================
'  SUB ClassRankList
'  Loads all students, sorts by average using Bubble Sort,
'  then displays ranked class list
'  (Grade 9: Arrays, Bubble Sort Algorithm, Loops)
'  (Grade 10: File Handling, SUB Procedures)
' ========================================================
Sub ClassRankList
    Cls
    Dim count As Integer
    Dim m1 As Integer, m2 As Integer, m3 As Integer
    Dim m4 As Integer, m5 As Integer
    Dim sName As String
    Dim i As Integer, j As Integer
    Dim tempName As String
    Dim tempTotal As Integer
    Dim tempAvg As Single
    Dim rank As Integer

    count = 0

    ' --- Count the records first, so the arrays hold every one ---
    Open DATAFILE For Input As #1
    Do While Not EOF(1)
        Input #1, sName
        ' A blank line, left by editing the file by hand, is skipped
        If sName <> "" Then
            Input #1, m1, m2, m3, m4, m5
            count = count + 1
        End If
    Loop
    Close #1

    ' --- Check if any records exist (Grade 8: IF-ELSE) ---
    If count = 0 Then
        Color 12, 0
        Print "  No student records found!"
        Print "  Please add students first using Option 1."
        Color 7, 0
        Print "  Press any key..."
        Sleep
        Exit Sub
    End If

    ' --- Dynamic arrays sized to the class (Grade 9: Arrays) ---
    ReDim names(1 To count) As String
    ReDim totals(1 To count) As Integer
    ReDim avgs(1 To count) As Single

    ' --- Load ALL students from file (Grade 10: File Handling) ---
    Open DATAFILE For Input As #1
    i = 0
    Do While Not EOF(1)
        Input #1, sName
        If sName <> "" Then
            Input #1, m1, m2, m3, m4, m5
            i = i + 1
            names(i) = sName
            totals(i) = m1 + m2 + m3 + m4 + m5
            avgs(i) = totals(i) / NSUBS
        End If
    Loop
    Close #1

    ' =====================================================
    '  BUBBLE SORT: Sort by average, DESCENDING
    '  Rank 1 = highest average
    '  (Grade 9: Sorting Algorithm - Bubble Sort)
    ' =====================================================
    For i = 1 To count - 1
        For j = 1 To count - i
            If avgs(j) < avgs(j + 1) Then
                ' Swap averages
                tempAvg = avgs(j)
                avgs(j) = avgs(j + 1)
                avgs(j + 1) = tempAvg
                ' Swap totals
                tempTotal = totals(j)
                totals(j) = totals(j + 1)
                totals(j + 1) = tempTotal
                ' Swap names
                tempName = names(j)
                names(j) = names(j + 1)
                names(j + 1) = tempName
            End If
        Next j
    Next i

    ' --- Display header box (Grade 9: Pattern Printing) ---
    Color 14, 0
    DrawLine "*", BOXW
    Print "*"; Tab(16); "CLASS RANK LIST"; Tab(BOXW); "*"
    Print "*"; Tab(10); "Sorted by Average (Highest First)"; Tab(BOXW); "*"
    DrawLine "*", BOXW
    Print
    Color 11, 0
    Print "  RANK  NAME                   TOTAL   AVG%  GRADE"
    DrawLine "-", BOXW

    ' --- Display each student with rank (Grade 9: FOR Loop) ---
    ' Equal averages share a rank and the next rank is skipped,
    ' so two students tied for first are 1, 1 and the next is 3
    rank = 1
    For i = 1 To count
        If i > 1 Then
            If avgs(i) < avgs(i - 1) Then rank = i
        End If

        ' Highlight top 3 with different colors (Grade 8: IF-ELSE)
        If rank = 1 Then
            Color 14, 0 ' Gold  - 1st place
        ElseIf rank = 2 Then
            Color 11, 0 ' Cyan  - 2nd place
        ElseIf rank = 3 Then
            Color 13, 0 ' Magenta - 3rd place
        Else
            Color 7, 0 ' White - rest
        End If

        Print "  "; LTrim$(Str$(rank)); ".   "; Left$(names(i) + Space$(22), 22); LTrim$(Str$(totals(i))); "    "; LTrim$(Str$(Int(avgs(i)))); "%   "; GetGrade$(avgs(i))
    Next i

    Color 7, 0
    DrawLine "=", BOXW
    Print "  Total Students in Record: " + LTrim$(Str$(count))
    DrawLine "=", BOXW
    Print
    Print "  Press any key to return to menu..."
    Sleep
End Sub


' ========================================================
'  SUB DrawLine
'  Draws a horizontal separator line of any character
'  (Grade 9: Pattern Printing using STRING$ function)
' ========================================================
Sub DrawLine (ch As String, n As Integer)
    Print String$(n, ch)
End Sub


' ========================================================
'  SUB DrawBarChart
'  Draws a horizontal bar chart using block characters
'  Math: bars = (marks / 100) * MAX_BARS
'  (Grade 9: Pattern Printing + Math Algorithm + Loops)
' ========================================================
Sub DrawBarChart (marks() As Integer)
    Dim i As Integer
    Dim j As Integer
    Dim bars As Integer
    Dim emptyBars As Integer

    For i = 1 To NSUBS
        ' Math algorithm: proportion of MAX_BARS to fill
        bars = Int((marks(i) / FULL_MARK) * MAX_BARS)
        emptyBars = MAX_BARS - bars

        ' Color based on performance level (Grade 8: IF-ELSE)
        If marks(i) >= 75 Then
            Color 10, 0 ' Green  - Distinction
        ElseIf marks(i) >= PASS_MARK Then
            Color 14, 0 ' Yellow - Pass
        Else
            Color 12, 0 ' Red    - Fail
        End If

        ' Print subject label
        Print "  " + Left$(LTrim$(subName(i)), 6) + " |";

        ' Print filled blocks (Grade 9: Loop pattern)
        For j = 1 To bars
            Print Chr$(219); ' Full block character: █
        Next j

        ' Print empty blocks
        Color 8, 0
        For j = 1 To emptyBars
            Print Chr$(176); ' Light shade character: ░
        Next j

        Color 7, 0
        Print "| " + LTrim$(Str$(marks(i))) + "/100"
    Next i
    Print
End Sub


' ========================================================
'  FUNCTION GetGrade$
'  Returns letter grade (A+, A, B+, B, C+, C, F)
'  based on marks or average value
'  (Grade 8: IF-ELSE | Grade 10: Functions)
' ========================================================
Function GetGrade$ (avg As Single)
    If avg >= 90 Then
        GetGrade$ = "A+"
    ElseIf avg >= 80 Then
        GetGrade$ = "A"
    ElseIf avg >= 70 Then
        GetGrade$ = "B+"
    ElseIf avg >= 60 Then
        GetGrade$ = "B"
    ElseIf avg >= 50 Then
        GetGrade$ = "C+"
    ElseIf avg >= PASS_MARK Then
        GetGrade$ = "C"
    Else
        GetGrade$ = "F"
    End If
End Function


' ========================================================
'  FUNCTION CalcTotal%
'  Returns sum of all subject marks
'  Math Algorithm: Summation using a loop
'  (Grade 9: Loops, Arrays | Grade 10: Functions)
' ========================================================
Function CalcTotal% (marks() As Integer)
    Dim total As Integer
    Dim i As Integer
    total = 0
    For i = 1 To NSUBS
        total = total + marks(i)
    Next i
    CalcTotal% = total
End Function


' ========================================================
'  FUNCTION FindMaxIdx%
'  Finds and returns the index of the highest marks
'  Math Algorithm: Linear search for maximum value
'  (Grade 9: Max-Finding Algorithm | Grade 10: Functions)
' ========================================================
Function FindMaxIdx% (marks() As Integer)
    Dim maxIdx As Integer
    Dim i As Integer
    maxIdx = 1
    For i = 2 To NSUBS
        If marks(i) > marks(maxIdx) Then
            maxIdx = i
        End If
    Next i
    FindMaxIdx% = maxIdx
End Function


' ========================================================
'  FUNCTION FindMinIdx%
'  Finds and returns the index of the lowest marks
'  Math Algorithm: Linear search for minimum value
'  (Grade 9: Min-Finding Algorithm | Grade 10: Functions)
' ========================================================
Function FindMinIdx% (marks() As Integer)
    Dim minIdx As Integer
    Dim i As Integer
    minIdx = 1
    For i = 2 To NSUBS
        If marks(i) < marks(minIdx) Then
            minIdx = i
        End If
    Next i
    FindMinIdx% = minIdx
End Function


' ========================================================
'  FUNCTION CountPass%
'  Counts the number of subjects where marks >= PASS_MARK
'  Math Algorithm: Counting algorithm using a loop
'  (Grade 9: Counting Algorithm | Grade 10: Functions)
' ========================================================
Function CountPass% (marks() As Integer)
    Dim count As Integer
    Dim i As Integer
    count = 0
    For i = 1 To NSUBS
        If marks(i) >= PASS_MARK Then
            count = count + 1
        End If
    Next i
    CountPass% = count
End Function


' ========================================================
'  FUNCTION ParseMark%
'  Reads a mark typed as text. Returns it if it is a whole
'  number from 0 to FULL_MARK, or -1 for anything else,
'  including nothing at all.
'  (Grade 8: String Functions | Grade 9: Loops)
'  (Grade 10: Functions)
' ========================================================
Function ParseMark% (text As String)
    Dim t As String
    Dim i As Integer
    Dim ch As String

    ParseMark% = -1
    t = LTrim$(RTrim$(text))
    If t = "" Then Exit Function

    ' Every character must be a digit: no sign, point or letter
    For i = 1 To Len(t)
        ch = Mid$(t, i, 1)
        If ch < "0" Or ch > "9" Then Exit Function
    Next i

    ' Compare before assigning, so a long number cannot overflow
    If Val(t) > FULL_MARK Then Exit Function
    ParseMark% = Val(t)
End Function
