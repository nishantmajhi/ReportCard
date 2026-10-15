# Student Report Card System (QBasic) — review and cleanup record

First reviewed 2026-09-04. Remediated 2026-09-30 on branch `cleanup/2026-09-30`.
Nothing pushed.

**129 checks, all passing.** `powershell -NoProfile -ExecutionPolicy Bypass -File tests\run.ps1`,
with QB64 2.1 at `D:\qb64\qb64.exe`. That is 55 unit checks, 36 whole-program
scenarios, the same 36 run against the first commit, and two checks on the
runner itself. About a minute, most of it three QB64 compiles. The suite was
green before each commit was made, and every commit was checked out into its
own worktree and tested there.

---

## Corrections to the first review

The first review judged the project "very good work" that "needs almost
nothing", and said "the file handling is correct". The code is well organised
and easy to read, as the review said. But the review read the file handling one
statement at a time. It never asked what reaches those statements: what a
person actually types, and what the file looks like after someone has edited
it. Four of the six defects below were there.

**It missed that a mark could be saved as something nobody typed.** Marks were
read with `INPUT` into an INTEGER. An empty line is 0, so pressing Enter once
too often recorded a failing mark with no message, and moved every later mark
up one subject. Under QB64, `INPUT` also drops keystrokes a number cannot
contain rather than rejecting the line: `8.5` was saved as 85, `5O` (letter O)
as 5, and `007` as 0. In a program whose whole job is to report marks, this is
the most serious defect here.

**Its round-trip note was right about commas and wrong as a conclusion.**
"`WRITE` quotes strings, so names containing commas survive a round trip
correctly" is true. A name containing a double quote does not survive:
`WRITE #` cannot escape it, and `INPUT #` read `Ram "Kale" Thapa` back as
`Ram `. The student was reported saved and could never be found again.

**It said the file handling was correct, and the program could corrupt its own
file.** The review itself points out that editing `students.dat` by hand is the
only way to correct a record. Two ordinary results of doing that broke the
program. A blank line made options 2 and 3 stop with runtime error 62 every
time. A last line with no line break, which Notepad does not add for you, made
the next student added be joined onto it. After that, options 2 and 3 failed
with error 62 as well.

**It missed tied ranks.** Students with the same average were ranked by the
order they had been entered in.

**Its P2 about 50 students was right**, and it is fixed a third way: see D3.

**It called the README "genuinely excellent"**, and the README promised that
the program runs in QBasic 1.1. Nobody had checked that, and it still has not
been checked. See "Not verified".

---

## Fixed

Each defect has regression scenarios tagged with its number in
`tests/scenarios.ps1`. `run.ps1` requires every tagged scenario to **fail**
against the first commit, and all 12 do. It also requires every untagged
scenario to **pass** there. That is how it catches a change in behaviour this
pass did not mean to make, and it caught one: see D1.

| | Defect | Fix |
| --- | --- | --- |
| D1 | An empty mark saved as 0; `8.5` saved as 85, `5O` as 5, `007` as 0 | Marks read with `LINE INPUT` and checked by a new `ParseMark%`: a whole number from 0 to 100, or -1. The existing range check and "Invalid!" message are unchanged. |
| D2 | A name containing `"` saved in a form that reads back as another name | Refused at entry, like an empty name |
| D3 | The rank list silently showed only the first 50 records in the file | Records counted first, and the arrays sized to fit with `REDIM`. There is no limit now. |
| D4 | Equal averages given different ranks, in the order they were entered | Competition ranking (1, 1, 3). The top-three colours follow the rank. |
| D5 | A blank line in `students.dat` made options 2 and 3 fail with error 62 | The name is read first, and the record skipped if it is empty |
| D6 | Adding after a last line with no line break joined the new record onto it | `AddStudent` checks the file's last byte (`OPEN ... FOR BINARY`, `GET`) and writes a line break first if one is missing |

D1's `007` case was found by the harness rather than by reading. A scenario that
typed `007` was first written as an untagged "leading zeros are accepted"
check. It failed against the original, so it became a D1 regression instead.

Also from the review's list:

- **P2, untrack `REPORT.exe` and `students.dat`, add a `.gitignore`.** Done.
  `REPORT.exe` was deleted as well as untracked, since it was a build of the
  code that has now changed. `students.dat` is still on disk. It held one
  record in the author's name.
- **P3, comment that the record format is fixed at five subjects.** Done, on
  `Const NSUBS`, which is where someone would go to add a subject.

### What you will see differently

- **One new line of text.** A name with a `"` in it gets "Error: Name cannot
  contain a double quote (")." in the same red, and with the same pause, as the
  existing empty-name error. There was no other way to say why the name was
  refused.
- **Typing a mark no longer filters keystrokes.** Letters and full stops now
  appear as they are typed and are rejected when Enter is pressed, with the
  existing message. Before, QB64 silently refused to show them. That filtering
  was how `8.5` became 85.
- **With ties, rank numbers repeat** and two students can share a colour.
  Without ties, the rank list is exactly as it was.

---

## Deliberately not done

- **P3, a delete option.** It would be a fifth menu item, which is a change to
  the interface. The README now explains how to edit the file by hand, and D5
  and D6 make the two usual results of doing so harmless.
- **P3, duplicate names.** Still stored twice. The report card shows the last
  one, which the old README documented, and the rank list shows both. That
  inconsistency is real, but the fix depends on what a repeated name means.
  If it is a correction, the rank list should show only the latest record. If
  it is two students with the same name, the report card should show both.
  That is the author's decision (see below), and a scenario pins the current
  behaviour.
- **Records a person has written badly.** A line with a mark missing, or a file
  saved with a byte-order mark, still stops the program or misreads the first
  name. Handling those needs a hand-written parser in place of `INPUT #`, and
  `INPUT #` is one of the syllabus items this project exists to show. D5 and D6
  cover what an ordinary edit produces. The README says every line needs a
  quoted name and five marks.
- **The rank list rounds the average down** (`89%`) while the report card shows
  it to one decimal (`89.8 %`). This is how it is presented, not an error, so
  it is left alone and the README says so.
- **The menu's own `INPUT`** still filters keystrokes, so `3x` is read as 3.
  That is harmless there: what is kept is visible on screen, and every value
  leads either to a menu option or to "Invalid choice".
- **The review's small observations**: subject names padded inside their
  strings, and colours as bare numbers. The review said to leave them, and
  they are left.

## Not verified

- **QBasic 1.1.** Nothing here can run it. Two things in the source may stop
  it, and both are in the original. One is `LINE INPUT "", x`: QBasic 1.1's
  documented syntax puts a semicolon after the prompt, and QB64 also accepts a
  comma. The other is `GetGrade$(marks(i))`, which passes an INTEGER array
  element to a parameter declared SINGLE. QBasic may reject that as a
  parameter type mismatch. The new code uses only QBasic 1.1 statements
  (`REDIM`, `OPEN ... FOR BINARY`, `GET`, `LOF`, `INSTR`, `MID$`, `VAL`), but it
  has not been run there either. The README no longer promises that it works.
- **Colour.** A QB64 console build does not output colour, so no test can see
  it. The one colour change (D4) replaces `i` with `rank` in three places.

---

## Structure

One source file, as before. The review asked for the project not to be
rewritten, because its value is as a record of what the author knew at that
point. The new code follows the existing style, with the same "(Grade N: ...)"
annotations. The decisions a unit test can reach are `FUNCTION`s. The rest is
tested through the whole program.

```
REPORT.BAS           the program
tests/run.ps1        builds with QB64 and runs everything
tests/unit.bas       checks on the FUNCTIONs, spliced into a copy of REPORT.BAS
tests/scenarios.ps1  whole-program sessions typed through stdin
```

## Notes for whoever is next

Six QB64 behaviours cost time to find. The first four shape the harness. The
first is why each scenario copies the exe. The other three are why the test
build differs from `REPORT.BAS`, along with `$CONSOLE:ONLY` itself.

- **A QB64 program changes to its own folder at startup**, whatever the working
  directory. `students.dat` always lands beside the `.exe`, so each scenario
  copies the exe into its own directory.
- **`SLEEP` reads the keyboard, never stdin**, even with `$CONSOLE:ONLY`. A
  console build given piped input hangs at the first "Press any key". The test
  build removes each `SLEEP` line, and refuses to run if one is left anywhere.
- **`END` in a console program waits for a key.** The test build turns it into
  `SYSTEM`.
- **An unhandled runtime error opens a dialog and waits.** The test build adds
  an `ON ERROR` handler that prints the error number and `_ERRORLINE`, so a
  failure reads "runtime error 62 at line 414 of REPORT.BAS" rather than
  timing out.
- **`INPUT` into a numeric variable filters keystrokes rather than rejecting
  the line**, in both the window and the console. It is one routine,
  `qbs_input` in `internal/c/libqb.cpp`.
- **QB64 compiles through `internal/temp` in its own folder**, so two compiles
  at once collide. Run one suite at a time.

## For the author

- **Two decisions** described under "Deliberately not done". First, what a
  repeated name means. Second, whether a student who fails a subject should be
  able to get a final grade of A and the remark "Excellent work!", as they can
  now. That depends on which grading rules the program is meant to follow,
  which only you can say. It is left as it is, the README describes it, and a
  scenario pins it.
- **The remote is public** (`github.com/nishantmajhi/ReportCard`). The old
  `students.dat`, one record in your name with a set of marks, and a 2 MB
  `REPORT.exe` are in its history. Neither is sensitive as far as can be told,
  and untracking them does not remove them from history.
- **There is no licence.** The old README did not claim one, and the new one
  does not either.

## Five minutes at a real keyboard

Everything above was tested through a console build. The window build, which
is what F5 produces, compiles cleanly with warnings on and was started here: it
opened its window and created `students.dat` beside itself. Nobody has typed
into it. Worth doing once:

1. Add a student, and press Enter on an empty mark. It should say "Invalid!"
   and ask again.
2. Type `8.5` for a mark. It should appear as typed, and be rejected.
3. Add two students with identical marks and open the rank list. Both should be
   "1." and both gold.

## Licence, 2026-10-02

The author chose one licence for all of their projects: free for personal,
non-commercial use, modifiable for the user's own use, and not to be
distributed, original or modified. No standard licence says that, so `LICENSE`
is a short custom text, the same in every project apart from the year and what
it excludes. The README's licence section says the same. Anything above that
calls the licence an open question, or calls the project MIT, is superseded.

## CI, 2026-10-02

`.github/workflows/ci.yml` downloads QB64 2.0.2 (checked against the SHA-256
recorded in it) and runs `tests\run.ps1` under Windows PowerShell on
`windows-latest`, naming the root commit as the baseline. Nothing has been
pushed, so it has not run on GitHub yet. Every job was run before committing,
from a fresh clone of this branch, the way a runner would run it: Windows jobs
here, in PowerShell 7 or the shell the step names, with only the tools the job
sets up on `PATH`. 129, and 12 of 12 regression scenarios failing against the
original. QB64 here is a 2.1 development build; 2.0.2 is the nearest release,
and passes.

**Fixed on the way:** with no local `main`, which is what a CI checkout has,
`run.ps1` crashed at its first `git log` instead of saying the baseline half
was skipped: the script sets `$ErrorActionPreference = 'Stop'`, and Windows
PowerShell 5.1 makes a native command's stderr terminating even under
`2>$null`. The probe now runs under `Continue`.
