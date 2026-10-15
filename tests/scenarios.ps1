# scenarios.ps1 - whole-program sessions, dot-sourced by run.ps1.
#
# Each scenario is a hashtable:
#
#   Name    what it establishes
#   Seed    lines of students.dat before the run (@() for an empty file)
#   RawSeed the exact contents of students.dat, for a file edited by hand
#   NoFile  $true to start with no students.dat at all
#   Keys    what is typed, one line per entry, Enter after each. The
#           welcome screen's key press is not needed: SLEEP is removed from
#           the test build. Every session ends by choosing 4, Exit.
#   Check   a script block given the session; it calls Expect for each
#           thing that must be true
#   Defect  set on a regression scenario: which defect in review.md it
#           pins. run.ps1 requires it to FAIL against the original.
#
# A session has .Out (everything printed), .Lines, .File (students.dat
# afterwards, or $null), .Records (its non-empty lines) and .ExitCode.

function Expect([bool] $ok, [string] $what) {
    if (-not $ok) { [void]$script:fails.Add($what) }
}

function Show($x) {
    if ($null -eq $x) { return '<nothing>' }
    return '[' + (@($x) -join '|') + ']'
}

# The value printed after "<label> :" on the report card, e.g. "Final Grade".
# All of them if the session viewed several cards.
function Get-Field($r, [string] $label) {
    $pat = '^\s+' + [regex]::Escape($label) + '\s*:\s(.*)$'
    return @($r.Lines | ForEach-Object { if ($_ -match $pat) { $matches[1] } })
}

# Rows of the class rank list, as objects.
function Get-RankRows($r) {
    return @($r.Lines | ForEach-Object {
        if ($_ -match '^  (\d+)\.   (.{22})(\d+)    (\d+)%   (\S+)$') {
            [pscustomobject]@{
                Rank = [int]$matches[1]; Name = $matches[2].TrimEnd()
                Total = [int]$matches[3]; Avg = [int]$matches[4]; Grade = $matches[5]
            }
        }
    })
}

# Subject rows of the report card: "Mathematics 95 A+ PASS".
function Get-SubjectRows($r) {
    return @($r.Lines | ForEach-Object {
        if ($_ -match '^  (.{14})  (\d+) / 100       (\S+)      (PASS|FAIL)$') {
            $matches[1].TrimEnd() + ' ' + $matches[2] + ' ' + $matches[3] + ' ' + $matches[4]
        }
    })
}

# Bar chart rows as "label full/empty": "Scienc 17/3".
function Get-Bars($r) {
    return @($r.Lines | ForEach-Object {
        if ($_ -match '^  (.{1,6}) \|([^|]*)\| (\d+)/100$') {
            $bar = $matches[2]
            $full = @($bar.ToCharArray() | Where-Object { $_ -eq [char]0xDB }).Count
            $empty = @($bar.ToCharArray() | Where-Object { $_ -eq [char]0xB0 }).Count
            "$($matches[1]) $full/$empty"
        }
    })
}

$Scenarios = @(

    @{  Name = 'the first run creates an empty students.dat'
        NoFile = $true
        Keys = @('3', '4')
        Check = {
            param($r)
            Expect ($null -ne $r.File) 'students.dat was not created'
            Expect ($r.Records.Count -eq 0) "students.dat is not empty: $(Show $r.Records)"
            Expect ($r.Out -match 'No student records found!') 'rank list did not say there are no records'
        }
    }

    @{  Name = 'adding a student writes one quoted record'
        Seed = @()
        Keys = @('1', 'Sita Rai', '90', '80', '70', '60', '50', '4')
        Check = {
            param($r)
            Expect ($r.Records.Count -eq 1 -and $r.Records[0] -eq '"Sita Rai",90,80,70,60,50') "records: $(Show $r.Records)"
            Expect ($r.Out -match "\[OK\] 'Sita Rai' has been saved successfully!") 'no confirmation'
        }
    }

    @{  Name = 'a new record goes after the existing ones'
        Seed = @('"Gita",50,50,50,50,50')
        Keys = @('1', 'Hari', '60', '60', '60', '60', '60', '4')
        Check = {
            param($r)
            Expect ((Show $r.Records) -eq '["Gita",50,50,50,50,50|"Hari",60,60,60,60,60]') "records: $(Show $r.Records)"
        }
    }

    @{  Name = 'spaces around a new name are trimmed'
        Seed = @()
        Keys = @('1', '   Gita Magar   ', '1', '2', '3', '4', '5', '4')
        Check = {
            param($r)
            Expect ((Show $r.Records) -eq '["Gita Magar",1,2,3,4,5]') "records: $(Show $r.Records)"
        }
    }

    @{  Name = 'an empty name is refused and nothing is written'
        Seed = @()
        Keys = @('1', '    ', '4')
        Check = {
            param($r)
            Expect ($r.Out -match 'Error: Name cannot be empty!') 'no error shown'
            Expect ($r.Records.Count -eq 0) "records: $(Show $r.Records)"
        }
    }

    # WRITE # cannot escape a quote: it wrote "Ram "Kale" Thapa", which
    # INPUT # reads back as "Ram ". The student was saved, and could never
    # be found by the name that was typed.
    @{  Name = 'a name with a double quote is refused, not saved as another name'
        Defect = 'D2'
        Seed = @('"Gita",50,50,50,50,50')
        Keys = @('1', 'Ram "Kale" Thapa', '60', '60', '60', '60', '60', '4')
        Check = {
            param($r)
            Expect ((Show $r.Records) -eq '["Gita",50,50,50,50,50]') "records: $(Show $r.Records)"
            Expect ($r.Out -match 'Error: Name cannot contain a double quote') 'no error shown'
        }
    }

    @{  Name = 'an apostrophe in a name is kept'
        Seed = @()
        Keys = @('1', "D'Souza", '60', '60', '60', '60', '60', '2', "d'souza", '4')
        Check = {
            param($r)
            Expect ((Show $r.Records) -eq "[`"D'Souza`",60,60,60,60,60]") "records: $(Show $r.Records)"
            Expect ((Show (Get-Field $r 'Name')) -eq "[D'Souza]") "report card name: $(Show (Get-Field $r 'Name'))"
        }
    }

    @{  Name = 'a mark outside 0-100 is asked for again'
        Seed = @()
        Keys = @('1', 'Hari', '101', '100', '-1', '0', '50', '50', '50', '4')
        Check = {
            param($r)
            $n = ([regex]::Matches($r.Out, 'Invalid! Marks must be between 0 and 100\.')).Count
            Expect ($n -eq 2) "expected 2 rejections, saw $n"
            Expect ((Show $r.Records) -eq '["Hari",100,0,50,50,50]') "records: $(Show $r.Records)"
        }
    }

    @{  Name = 'an empty mark is asked for again, not saved as 0'
        Defect = 'D1'
        Seed = @()
        Keys = @('1', 'Ram', '', '55', '60', '70', '80', '90', '4')
        Check = {
            param($r)
            Expect ((Show $r.Records) -eq '["Ram",55,60,70,80,90]') "records: $(Show $r.Records)"
            $n = ([regex]::Matches($r.Out, 'Invalid! Marks must be between 0 and 100\.')).Count
            Expect ($n -eq 1) "expected 1 rejection, saw $n"
        }
    }

    @{  Name = 'a mark with a decimal point is refused, not read as another number'
        Defect = 'D1'
        Seed = @()
        Keys = @('1', 'Ram', '8.5', '9', '60', '70', '80', '90', '4')
        Check = {
            param($r)
            Expect ((Show $r.Records) -eq '["Ram",9,60,70,80,90]') "records: $(Show $r.Records)"
        }
    }

    @{  Name = 'a mark with letters in it is refused, not read as another number'
        Defect = 'D1'
        Seed = @()
        Keys = @('1', 'Ram', '5O', 'abc', '50', '60', '70', '80', '90', '4')
        Check = {
            param($r)
            Expect ((Show $r.Records) -eq '["Ram",50,60,70,80,90]') "records: $(Show $r.Records)"
            $n = ([regex]::Matches($r.Out, 'Invalid! Marks must be between 0 and 100\.')).Count
            Expect ($n -eq 2) "expected 2 rejections, saw $n"
        }
    }

    @{  Name = 'spaces around a mark are accepted'
        Seed = @()
        Keys = @('1', 'Ram', '  75  ', ' 100', '0 ', '40', '99', '4')
        Check = {
            param($r)
            Expect ((Show $r.Records) -eq '["Ram",75,100,0,40,99]') "records: $(Show $r.Records)"
        }
    }

    # The original stored 007 as 0: QB64's INPUT drops a digit typed after
    # a leading zero, so the 0 was all it kept.
    @{  Name = 'a mark with a leading zero is read as the number it is'
        Defect = 'D1'
        Seed = @()
        Keys = @('1', 'Ram', '007', '05', '100', '0', '40', '4')
        Check = {
            param($r)
            Expect ((Show $r.Records) -eq '["Ram",7,5,100,0,40]') "records: $(Show $r.Records)"
        }
    }

    @{  Name = 'a name with a comma survives the round trip'
        Seed = @()
        Keys = @('1', 'Thapa, Hari', '70', '70', '70', '70', '70', '2', 'thapa, hari', '3', '4')
        Check = {
            param($r)
            Expect ((Show $r.Records) -eq '["Thapa, Hari",70,70,70,70,70]') "records: $(Show $r.Records)"
            Expect ((Show (Get-Field $r 'Name')) -eq '[Thapa, Hari]') "report card name: $(Show (Get-Field $r 'Name'))"
            $rows = @(Get-RankRows $r)
            Expect ($rows.Count -eq 1 -and $rows[0].Name -eq 'Thapa, Hari') "rank list: $(Show ($rows | ForEach-Object { $_.Name }))"
        }
    }

    @{  Name = 'report card: each subject, the totals, and the verdicts'
        Seed = @('"Sita Rai",95,82,71,64,39')
        Keys = @('2', 'Sita Rai', '4')
        Check = {
            param($r)
            $want = '[Mathematics 95 A+ PASS|Science 82 A PASS|English 71 B+ PASS|Social Studies 64 B PASS|Computer 39 F FAIL]'
            Expect ((Show (Get-SubjectRows $r)) -eq $want) "subjects: $(Show (Get-SubjectRows $r))"
            Expect ((Show (Get-Field $r 'Total Marks')) -eq '[351 / 500]') "total: $(Show (Get-Field $r 'Total Marks'))"
            Expect ((Show (Get-Field $r 'Percentage')) -eq '[70.2 %]') "percentage: $(Show (Get-Field $r 'Percentage'))"
            Expect ((Show (Get-Field $r 'Final Grade')) -eq '[B+]') "grade: $(Show (Get-Field $r 'Final Grade'))"
            Expect ((Show (Get-Field $r 'Passed')) -eq '[4 out of 5 subjects]') "passed: $(Show (Get-Field $r 'Passed'))"
            Expect ((Show (Get-Field $r 'Failed')) -eq '[1 subject(s)]') "failed: $(Show (Get-Field $r 'Failed'))"
            Expect ((Show (Get-Field $r 'Best Subject')) -eq '[Mathematics]') "best: $(Show (Get-Field $r 'Best Subject'))"
            Expect ((Show (Get-Field $r 'Weak Subject')) -eq '[Computer]') "weak: $(Show (Get-Field $r 'Weak Subject'))"
            Expect ((Show (Get-Field $r 'Remark')) -eq '[Good. Push harder to reach excellence!]') "remark: $(Show (Get-Field $r 'Remark'))"
        }
    }

    @{  Name = 'search ignores case and surrounding spaces'
        Seed = @('"Sita Rai",50,50,50,50,50')
        Keys = @('2', '   SITA rai  ', '4')
        Check = {
            param($r)
            Expect ((Show (Get-Field $r 'Name')) -eq '[Sita Rai]') "name: $(Show (Get-Field $r 'Name'))"
        }
    }

    @{  Name = 'an unknown name is reported, not shown'
        Seed = @('"Sita Rai",50,50,50,50,50')
        Keys = @('2', 'Sita', '4')
        Check = {
            param($r)
            Expect ($r.Out -match "Student 'Sita' was not found in records!") 'no not-found message'
            Expect (@(Get-Field $r 'Name').Count -eq 0) 'a report card was shown'
        }
    }

    @{  Name = 'percentage is rounded to one decimal, and the grade comes from the average'
        Seed = @('"Asha",90,90,90,90,89', '"Bina",40,40,40,40,39')
        Keys = @('2', 'Asha', '2', 'Bina', '4')
        Check = {
            param($r)
            Expect ((Show (Get-Field $r 'Percentage')) -eq '[89.8 %|39.8 %]') "percentage: $(Show (Get-Field $r 'Percentage'))"
            Expect ((Show (Get-Field $r 'Final Grade')) -eq '[A|F]') "grade: $(Show (Get-Field $r 'Final Grade'))"
        }
    }

    @{  Name = 'the remark follows the average'
        Seed = @('"A",90,90,90,90,90', '"B",75,75,75,75,75', '"C",60,60,60,60,60',
                 '"D",40,40,40,40,40', '"E",40,40,40,40,39')
        Keys = @('2', 'A', '2', 'B', '2', 'C', '2', 'D', '2', 'E', '4')
        Check = {
            param($r)
            $want = '[Outstanding! You are a star student!|Excellent work! Keep it up.|Good. Push harder to reach excellence!|Passed. Focus more on weak subjects.|Failed. Work harder and try again!]'
            Expect ((Show (Get-Field $r 'Remark')) -eq $want) "remarks: $(Show (Get-Field $r 'Remark'))"
        }
    }

    # Documented in the README, and left for the author: see review.md.
    @{  Name = 'a failed subject changes neither the final grade nor the remark'
        Seed = @('"Ram",100,100,100,100,0')
        Keys = @('2', 'Ram', '4')
        Check = {
            param($r)
            Expect ((Show (Get-Field $r 'Failed')) -eq '[1 subject(s)]') "failed: $(Show (Get-Field $r 'Failed'))"
            Expect ((Show (Get-Field $r 'Final Grade')) -eq '[A]') "grade: $(Show (Get-Field $r 'Final Grade'))"
            Expect ((Show (Get-Field $r 'Remark')) -eq '[Excellent work! Keep it up.]') "remark: $(Show (Get-Field $r 'Remark'))"
        }
    }

    @{  Name = 'bar chart: one block per five marks'
        Seed = @('"Ram",100,85,42,4,0')
        Keys = @('2', 'Ram', '4')
        Check = {
            param($r)
            $want = '[Mathem 20/0|Scienc 17/3|Englis 8/12|Social 0/20|Comput 0/20]'
            Expect ((Show (Get-Bars $r)) -eq $want) "bars: $(Show (Get-Bars $r))"
        }
    }

    @{  Name = 'a name entered twice shows its last record (documented in the README)'
        Seed = @('"Ram",50,50,50,50,50', '"Ram",80,80,80,80,80')
        Keys = @('2', 'ram', '4')
        Check = {
            param($r)
            Expect ((Show (Get-Field $r 'Total Marks')) -eq '[400 / 500]') "total: $(Show (Get-Field $r 'Total Marks'))"
        }
    }

    @{  Name = 'rank list: highest average first, with total, whole-number average and grade'
        Seed = @('"Chandra",60,60,60,60,60', '"Asha",90,90,90,90,89', '"Bina",75,75,75,75,76')
        Keys = @('3', '4')
        Check = {
            param($r)
            $rows = @(Get-RankRows $r)
            $got = Show ($rows | ForEach-Object { "$($_.Rank) $($_.Name) $($_.Total) $($_.Avg) $($_.Grade)" })
            Expect ($got -eq '[1 Asha 449 89 A|2 Bina 376 75 B+|3 Chandra 300 60 B]') "rows: $got"
            Expect ($r.Out -match 'Total Students in Record: 3') 'wrong count line'
        }
    }

    # The original numbered rows by position, so of two students with the
    # same average the one entered first was ranked above the other.
    @{  Name = 'rank list: equal averages share a rank, and the next rank is skipped'
        Defect = 'D4'
        Seed = @('"Bina",80,80,80,80,80', '"Dipak",70,70,70,70,70', '"Asha",80,80,80,80,80',
                 '"Chandra",75,75,75,75,75', '"Esha",70,70,70,70,70', '"Gopal",60,60,60,60,60')
        Keys = @('3', '4')
        Check = {
            param($r)
            $rows = @(Get-RankRows $r)
            $got = Show ($rows | ForEach-Object { "$($_.Rank) $($_.Name)" })
            Expect ($got -eq '[1 Bina|1 Asha|3 Chandra|4 Dipak|4 Esha|6 Gopal]') "rows: $got"
            Expect ($r.Out -match 'Total Students in Record: 6\b') 'wrong count line'
        }
    }

    @{  Name = 'rank list: a whole class on the same average all rank first'
        Defect = 'D4'
        Seed = @('"A",55,55,55,55,55', '"B",55,55,55,55,55', '"C",55,55,55,55,55')
        Keys = @('3', '4')
        Check = {
            param($r)
            $got = Show (@(Get-RankRows $r) | ForEach-Object { "$($_.Rank) $($_.Name)" })
            Expect ($got -eq '[1 A|1 B|1 C]') "rows: $got"
        }
    }

    @{  Name = 'rank list: fifty students, all listed'
        Seed = @(1..50 | ForEach-Object { '"Student {0:D2}",{0},{0},{0},{0},{0}' -f $_ })
        Keys = @('3', '4')
        Check = {
            param($r)
            $rows = @(Get-RankRows $r)
            Expect ($rows.Count -eq 50) "$($rows.Count) rows"
            Expect ($rows.Count -gt 0 -and $rows[0].Name -eq 'Student 50' -and $rows[-1].Name -eq 'Student 01') 'wrong order'
            Expect ($r.Out -match 'Total Students in Record: 50\b') 'wrong count line'
        }
    }

    # AddStudent appended without limit and ClassRankList read at most 50,
    # into fixed arrays, without saying so. The 51st student here is the
    # best in the class, so the original's rank list left out its topper.
    @{  Name = 'rank list: every student is listed past fifty'
        Defect = 'D3'
        Seed = @(1..50 | ForEach-Object { '"Student {0:D2}",{0},{0},{0},{0},{0}' -f $_ }) + '"Topper",99,99,99,99,99'
        Keys = @('3', '4')
        Check = {
            param($r)
            $rows = @(Get-RankRows $r)
            Expect ($rows.Count -eq 51) "$($rows.Count) rows"
            Expect ($rows.Count -gt 0 -and $rows[0].Name -eq 'Topper' -and $rows[0].Rank -eq 1) "first row: $(Show ($rows | Select-Object -First 1 | ForEach-Object { $_.Name }))"
            Expect ($rows.Count -gt 0 -and $rows[-1].Name -eq 'Student 01' -and $rows[-1].Rank -eq 51) 'wrong last row'
            Expect ($r.Out -match 'Total Students in Record: 51\b') 'wrong count line'
        }
    }

    @{  Name = 'rank list: a class of three hundred'
        Defect = 'D3'
        Seed = @(1..300 | ForEach-Object { '"S{0:D3}",{1},{1},{1},{1},{2}' -f $_, [int][Math]::Floor($_ / 3), ($_ % 3) })
        Keys = @('3', '4')
        Check = {
            param($r)
            $rows = @(Get-RankRows $r)
            Expect ($rows.Count -eq 300) "$($rows.Count) rows"
            Expect ($r.Out -match 'Total Students in Record: 300\b') 'wrong count line'
            $sorted = $true
            for ($i = 1; $i -lt $rows.Count; $i++) { if ($rows[$i].Total -gt $rows[$i - 1].Total) { $sorted = $false } }
            Expect $sorted 'rows are not in descending order of total'
        }
    }

    # The only way to correct or remove a record is to edit students.dat by
    # hand, and pressing Enter after the last line leaves a blank one. The
    # original then stopped with "Input past end of file" on both option 2
    # and option 3, every time, until the line was found and deleted.
    @{  Name = 'a blank line at the end of students.dat is skipped'
        Defect = 'D5'
        Seed = @('"Asha",80,80,80,80,80', '"Bina",70,70,70,70,70', '')
        Keys = @('3', '2', 'Bina', '4')
        Check = {
            param($r)
            $got = Show (@(Get-RankRows $r) | ForEach-Object { "$($_.Rank) $($_.Name)" })
            Expect ($got -eq '[1 Asha|2 Bina]') "rows: $got"
            Expect ($r.Out -match 'Total Students in Record: 2\b') 'wrong count line'
            Expect ((Show (Get-Field $r 'Total Marks')) -eq '[350 / 500]') "total: $(Show (Get-Field $r 'Total Marks'))"
        }
    }

    @{  Name = 'blank lines anywhere in students.dat are skipped, and adding still works'
        Defect = 'D5'
        Seed = @('', '"Asha",80,80,80,80,80', '   ', '', '"Bina",70,70,70,70,70', '', '')
        Keys = @('1', 'Chandra', '90', '90', '90', '90', '90', '3', '2', 'bina', '2', 'chandra', '4')
        Check = {
            param($r)
            $got = Show (@(Get-RankRows $r) | ForEach-Object { "$($_.Rank) $($_.Name)" })
            Expect ($got -eq '[1 Chandra|2 Asha|3 Bina]') "rows: $got"
            Expect ((Show (Get-Field $r 'Total Marks')) -eq '[350 / 500|450 / 500]') "totals: $(Show (Get-Field $r 'Total Marks'))"
        }
    }

    # Notepad does not add a line break at the end of a file. WRITE # does
    # not start a new line of its own, so the original joined the new
    # record onto the last one: "Bina",70,70,70,70,70"Chandra",90,...
    @{  Name = 'adding after a last line with no line break starts a new line'
        Defect = 'D6'
        RawSeed = "`"Asha`",80,80,80,80,80`r`n`"Bina`",70,70,70,70,70"
        Keys = @('1', 'Chandra', '90', '90', '90', '90', '90', '3', '2', 'bina', '4')
        Check = {
            param($r)
            Expect ((Show $r.Records) -eq '["Asha",80,80,80,80,80|"Bina",70,70,70,70,70|"Chandra",90,90,90,90,90]') "records: $(Show $r.Records)"
            $got = Show (@(Get-RankRows $r) | ForEach-Object { "$($_.Rank) $($_.Name)" })
            Expect ($got -eq '[1 Chandra|2 Asha|3 Bina]') "rows: $got"
            Expect ((Show (Get-Field $r 'Total Marks')) -eq '[350 / 500]') "total: $(Show (Get-Field $r 'Total Marks'))"
        }
    }

    @{  Name = 'a last line with no line break is read'
        RawSeed = "`"Asha`",80,80,80,80,80`r`n`"Bina`",70,70,70,70,70"
        Keys = @('3', '4')
        Check = {
            param($r)
            $got = Show (@(Get-RankRows $r) | ForEach-Object { "$($_.Rank) $($_.Name)" })
            Expect ($got -eq '[1 Asha|2 Bina]') "rows: $got"
        }
    }

    @{  Name = 'a file with Unix line endings is read and added to'
        RawSeed = "`"Asha`",80,80,80,80,80`n`"Bina`",70,70,70,70,70`n"
        Keys = @('1', 'Chandra', '90', '90', '90', '90', '90', '3', '4')
        Check = {
            param($r)
            $got = Show (@(Get-RankRows $r) | ForEach-Object { "$($_.Rank) $($_.Name)" })
            Expect ($got -eq '[1 Chandra|2 Asha|3 Bina]') "rows: $got"
        }
    }

    @{  Name = 'a name longer than the column is cut in the rank list, not in the file'
        Seed = @()
        Keys = @('1', 'Bishnu Prasad Shrestha Adhikari', '50', '50', '50', '50', '50', '3', '4')
        Check = {
            param($r)
            Expect ((Show $r.Records) -eq '["Bishnu Prasad Shrestha Adhikari",50,50,50,50,50]') "records: $(Show $r.Records)"
            $rows = @(Get-RankRows $r)
            Expect ($rows.Count -eq 1 -and $rows[0].Name -eq 'Bishnu Prasad Shrestha') "rank list: $(Show ($rows | ForEach-Object { $_.Name }))"
        }
    }

    @{  Name = 'an invalid menu choice is reported and the menu comes back'
        Seed = @('"Gita",50,50,50,50,50')
        Keys = @('9', '3', '4')
        Check = {
            param($r)
            Expect ($r.Out -match 'Invalid choice! Please enter a number from 1 to 4\.') 'no invalid-choice message'
            Expect (@(Get-RankRows $r).Count -eq 1) 'the rank list did not follow'
        }
    }

    @{  Name = 'Exit says goodbye and ends the program'
        Seed = @()
        Keys = @('4')
        Check = {
            param($r)
            Expect ($r.Out -match 'Goodbye!') 'no goodbye'
            Expect ($r.ExitCode -eq 0) "exit code $($r.ExitCode)"
        }
    }
)
