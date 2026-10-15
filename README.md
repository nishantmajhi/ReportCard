# Student Report Card System

A console program in QBasic that keeps a class's marks in five subjects,
prints a report card for any student, and ranks the class by average. It was
written as a showcase of the programming topics in the Grade 8 to Grade 10
Computer Science syllabus for the SEE in Nepal, and the source is annotated
with the grade each construct comes from.

## Running it

You need [QB64](https://qb64.com). It has been built and tested with QB64 2.1
on Windows.

- **In the QB64 editor:** open `REPORT.BAS` and press F5.
- **From a command line:** `qb64 -x REPORT.BAS -o REPORT.exe`, then run
  `REPORT.exe`.

The program was also meant to run in the original QBasic 1.1, but nobody has
checked that it does. Two things in it may stop QBasic 1.1 from running it: a
comma after a `LINE INPUT` prompt, and passing an INTEGER mark to `GetGrade$`,
which declares a SINGLE.

## Using it

Press any key at the welcome screen to reach the menu.

**1. Add New Student.** Type the name, then a mark for each subject.

- Spaces around the name are removed. A name cannot be empty, and cannot
  contain a double quote (`"`), because the data file has no way to store one.
- A mark must be a whole number from 0 to 100. Anything else, including an
  empty line, is rejected and asked for again.
- The record is added to the end of `students.dat` straight away.

**2. View Student Report Card.** Type a name. Case and surrounding spaces are
ignored. The card shows:

- each subject's mark, letter grade and PASS or FAIL
- the total out of 500, and the percentage to one decimal place
- a final letter grade, worked out from the percentage
- how many subjects were passed and failed
- the best and weakest subjects (if two subjects tie, the first in the list)
- a remark, also chosen from the percentage
- a bar chart with one block for every five marks

If the same name was entered more than once, the card shows the last record
entered.

**3. View Class Rank List.** Every student, highest average first, with total,
average and grade. The average is shown as a whole number, rounded down.
Students with the same average share a rank and the next rank is skipped, so
two students tied for first are followed by the third. The top three ranks are
shown in gold, cyan and magenta. Every record appears, including a name entered
twice.

**4. Exit.**

## Grades

| Mark or average | Grade |
| --- | --- |
| 90 to 100 | A+ |
| 80 to 89 | A |
| 70 to 79 | B+ |
| 60 to 69 | B |
| 50 to 59 | C+ |
| 40 to 49 | C |
| below 40 | F |

A subject is passed at 40. The same table grades each subject's mark, the
final grade and the rank list. The final grade and the remark depend only on
the average, so a student who failed one subject can still get an A and
"Excellent work!".

| Average | Remark |
| --- | --- |
| 90 and above | Outstanding! You are a star student! |
| 75 and above | Excellent work! Keep it up. |
| 60 and above | Good. Push harder to reach excellence! |
| 40 and above | Passed. Focus more on weak subjects. |
| below 40 | Failed. Work harder and try again! |

## The data file

Records are kept in `students.dat`, which the program creates the first time it
runs. It is always beside the executable, because a QB64 program changes to its
own folder when it starts. When you run from the QB64 editor, that folder is
the one `REPORT.BAS` is in.

Each student is one line, written by `WRITE #`: the name in quotes, then the
five marks in subject order.

```
"Sita Rai",95,82,71,64,39
"Thapa, Hari",70,70,70,70,70
```

There is no option to change or delete a record, so to fix a mistake, edit this
file in a text editor while the program is closed. Blank lines are ignored, and
so is a missing line break at the end. Every other line must have a name in
quotes and all five marks, or the program will stop with an error when it reads
the file.

## What the source demonstrates

**Grade 8.** `CONST` for the pass mark, full mark, subject count and layout
widths. `PRINT`, `INPUT`, `LINE INPUT` and `COLOR`. `IF ... ELSEIF` for the
grade bands, the remark, pass or fail, and validation.

**Grade 9.**

- `SELECT CASE` for the menu.
- `FOR ... NEXT` for the subjects, the borders and the bar chart.
- `DO WHILE ... LOOP` for the menu, re-asking for marks, and reading the file
  until `EOF`.
- One-dimensional arrays, including arrays sized at run time with `REDIM` for
  the rank list.
- Algorithms: summation (`CalcTotal%`), average, maximum and minimum
  (`FindMaxIdx%`, `FindMinIdx%`), counting (`CountPass%`), bubble sort on three
  parallel arrays, competition ranking, and proportion for the bar length.
- Patterns: the welcome screen borders, an alternating `=-` line, the report
  card box, and the bar chart in block characters `CHR$(219)` and `CHR$(176)`.

**Grade 10.**

- `SUB` procedures: `ShowWelcome`, `MainMenu`, `AddStudent`, `ViewReport`,
  `ClassRankList`, `DrawLine` and `DrawBarChart`.
- `FUNCTION`s that return a string (`GetGrade$`) and integers (`CalcTotal%`,
  `FindMaxIdx%`, `FindMinIdx%`, `CountPass%`, and `ParseMark%`, which checks a
  typed mark).
- Sequential files: `OPEN ... FOR APPEND`, `OPEN ... FOR INPUT`, `WRITE #`,
  `INPUT #`, `EOF` and `CLOSE`.
- A binary file: `OPEN ... FOR BINARY`, `LOF` and `GET`, used to check whether
  the data file ends with a line break before adding to it.

## Tests

```
powershell -NoProfile -ExecutionPolicy Bypass -File tests\run.ps1
```

This needs QB64, found on `PATH`, at `D:\qb64\qb64.exe` or `C:\qb64\qb64.exe`,
or at the path in the `QB64` environment variable. It takes about a minute,
mostly compiling.

`tests/unit.bas` checks the functions directly. `tests/scenarios.ps1` builds the
whole program as a console application and types sessions into it, then checks
what it printed and what it left in `students.dat`. If git is available, the
scenarios are also run against the first commit: those marked as regressions
must fail there, and all the others must pass. `-NoOriginal` skips that step.

## Files

| File | |
| --- | --- |
| `REPORT.BAS` | the program |
| `students.dat` | the class records; created on first run, not tracked by git |
| `tests/` | the test suite |
| `review.md` | a code review, and a record of what was fixed |

## Licence

Free for personal, non-commercial use. You may use, study and modify this
software for yourself, but you may not use it commercially, and you may not
share or publish it, in its original form or modified. See [LICENSE](LICENSE)
for the full terms.
