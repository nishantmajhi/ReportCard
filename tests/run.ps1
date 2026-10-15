# run.ps1 - build REPORT.BAS with QB64 and run every check in this folder.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\run.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File tests\run.ps1 -NoOriginal
#
# Two layers:
#
#   1. unit.bas, spliced into a copy of REPORT.BAS in place of its launch
#      block, so it calls the real FUNCTIONs with the real constants.
#   2. scenarios.ps1: the whole program, built as a console application,
#      driven through stdin. Each scenario seeds students.dat, types a
#      session at the menu, and asserts on what was printed and on what the
#      file holds afterwards. A passing unit layer says nothing about what
#      the program writes to its own file, which is where most of the
#      defects in review.md were.
#
# The same scenarios are then run against REPORT.BAS as it was at the
# baseline commit, fetched with `git show`. A scenario tagged with a Defect
# must fail there (otherwise it tests nothing), and every untagged scenario
# must pass there too (otherwise it describes a behaviour this pass changed
# without saying so). -NoOriginal skips that half; it is skipped anyway,
# with a note, when git or the baseline commit is unavailable.
#
# The console build differs from REPORT.BAS in four mechanical ways, all
# made by Convert-ToConsole below and applied identically to both versions:
# $CONSOLE:ONLY is added so stdin and stdout are pipes; each "Press any key"
# SLEEP is removed, because SLEEP waits on the keyboard and never on stdin;
# END becomes SYSTEM, because END in a console program waits for a key; and
# an ON ERROR handler prints a runtime error and exits, where QB64 would
# otherwise open a dialog and wait.

[CmdletBinding()]
param(
    [switch] $NoOriginal,
    [string] $Baseline = 'main',
    [switch] $KeepBuild
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$tests = Join-Path $root 'tests'

# Checked so that a moved branch fails loudly instead of measuring the
# wrong code.
$BaselineSubject = 'Initial commit'

function Find-Qb64 {
    if ($env:QB64 -and (Test-Path $env:QB64)) { return $env:QB64 }
    $c = Get-Command qb64 -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    foreach ($p in @('D:\qb64\qb64.exe', 'C:\qb64\qb64.exe')) {
        if (Test-Path $p) { return $p }
    }
    throw 'QB64 not found: put qb64.exe on PATH or set $env:QB64 to its full path'
}

$qb64 = Find-Qb64
$build = Join-Path $env:TEMP ('reportcard-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $build | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding $false
$latin1 = [System.Text.Encoding]::GetEncoding(28591)

$script:total = 0
$script:failed = 0

function Report([bool] $ok, [string] $label, [string] $detail) {
    $script:total++
    if ($ok) { return }
    $script:failed++
    Write-Host "FAIL  $label" -ForegroundColor Red
    if ($detail) { Write-Host "      $detail" }
}

# ------------------------------------------------------------------ #
# Building                                                            #
# ------------------------------------------------------------------ #

function Convert-ToConsole([string] $src) {
    $lines = $src -split "`r?`n"
    $sleeps = 0; $ends = 0
    $out = New-Object System.Collections.ArrayList
    # An unhandled runtime error opens a QB64 dialog and waits, so a session
    # would only end at the timeout. This handler prints the error and the
    # line instead. It is jumped over on the way in, and the lines in front
    # of REPORT.BAS's own are exactly $script:Prelude of them.
    foreach ($l in @('$CONSOLE:ONLY', 'On Error GoTo TestHarnessError', 'GoTo TestHarnessStart',
                     'TestHarnessError:', 'Print "RUNTIME ERROR"; Err; "AT LINE"; _ErrorLine',
                     'System 3', 'TestHarnessStart:')) { [void]$out.Add($l) }
    $script:Prelude = $out.Count
    foreach ($line in $lines) {
        if ($line -match '^\s*Sleep(\s+\d+)?\s*$') {
            [void]$out.Add("' (Sleep removed for the test build)"); $sleeps++
        } elseif ($line -match '^\s*End\s*$') {
            [void]$out.Add('System'); $ends++
        } else {
            [void]$out.Add($line)
        }
    }
    if ($sleeps -eq 0 -or $ends -eq 0) {
        throw "console conversion found $sleeps SLEEP and $ends END lines; REPORT.BAS has changed shape"
    }
    # A SLEEP left anywhere else would hang the build on the first run.
    foreach ($line in $out) {
        $code = ($line -replace '"[^"]*"', '') -replace "'.*$", ''
        if ($code -match '\bSleep\b') { throw "console conversion missed a SLEEP: $line" }
    }
    return ($out -join "`r`n")
}

function Build-Qb64([string] $name, [string] $source) {
    $bas = Join-Path $build "$name.bas"
    $exe = Join-Path $build "$name.exe"
    [System.IO.File]::WriteAllText($bas, $source, $utf8)
    $log = & $qb64 -x $bas -o $exe 2>&1 | Out-String
    if (-not (Test-Path $exe)) {
        throw "QB64 could not build $name.bas:`n$log"
    }
    return $exe
}

# ------------------------------------------------------------------ #
# Running                                                             #
# ------------------------------------------------------------------ #

# Runs $exe in a fresh directory, with students.dat seeded from $seed
# ($null for no file at all), typing each of $keys followed by Enter.
# Returns what it printed (form feeds from CLS removed), the file it left,
# and whether it had to be killed.
#
# The exe is copied into that directory rather than run from where it was
# built: a QB64 program changes to its own folder at startup, whatever the
# working directory, so students.dat always lands beside the .exe.
function Invoke-Session([string] $exe, $seed, [string[]] $keys, [int] $timeoutMs = 20000) {
    $dir = Join-Path $build ('run-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory $dir | Out-Null
    Copy-Item $exe $dir
    $exe = Join-Path $dir (Split-Path $exe -Leaf)
    $dat = Join-Path $dir 'students.dat'
    if ($seed -is [string]) {
        # Exact file contents, for a file edited by hand
        [System.IO.File]::WriteAllText($dat, $seed, $latin1)
    } elseif ($null -ne $seed) {
        $body = ''
        foreach ($l in $seed) { $body += $l + "`r`n" }
        [System.IO.File]::WriteAllText($dat, $body, $latin1)
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $exe
    $psi.WorkingDirectory = $dir
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.StandardOutputEncoding = $latin1
    $p = [System.Diagnostics.Process]::Start($psi)
    $read = $p.StandardOutput.ReadToEndAsync()

    $typed = ''
    foreach ($k in $keys) { $typed += $k + "`r`n" }
    $bytes = $latin1.GetBytes($typed)
    try {
        $p.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
        $p.StandardInput.Close()
    } catch { }   # the program may already have stopped reading

    $timedOut = -not $p.WaitForExit($timeoutMs)
    if ($timedOut) { try { $p.Kill() } catch { }; $p.WaitForExit() }
    $out = $read.Result -replace "`f", ''

    $file = $null
    if (Test-Path $dat) {
        $file = [System.IO.File]::ReadAllText($dat, $latin1)
    }
    return [pscustomobject]@{
        Out      = $out
        Lines    = @($out -split "`r?`n")
        File     = $file
        Records  = @(if ($file) { $file -split "`r`n" | Where-Object { $_ -ne '' } })
        TimedOut = $timedOut
        ExitCode = $(if ($timedOut) { $null } else { $p.ExitCode })
    }
}

# ------------------------------------------------------------------ #
# Layer 1: unit.bas                                                   #
# ------------------------------------------------------------------ #

$current = [System.IO.File]::ReadAllText((Join-Path $root 'REPORT.BAS'), $utf8)

$unit = [System.IO.File]::ReadAllText((Join-Path $tests 'unit.bas'), $utf8)
$marker = "' ==== PROCEDURES ===="
$at = $unit.IndexOf($marker)
if ($at -lt 0) { throw "unit.bas has no '$marker' line" }
$unitMain = $unit.Substring(0, $at)
$unitProcs = $unit.Substring($at)

$launch = '(?m)^ShowWelcome\r?\nMainMenu\r?\nEnd\r?$'
if ($current -notmatch $launch) { throw 'REPORT.BAS launch block (ShowWelcome / MainMenu / End) not found' }
$spliced = [regex]::Replace($current, $launch, { param($m) $unitMain })
$spliced = $spliced.TrimEnd() + "`r`n`r`n" + $unitProcs

Write-Host 'Building unit checks...'
$unitExe = Build-Qb64 'unit' (Convert-ToConsole $spliced)
$r = Invoke-Session $unitExe @() @()
Report (-not $r.TimedOut) 'unit: finished' 'unit.exe did not exit'
$unitRan = 0
foreach ($line in $r.Lines) {
    if ($line -match '^ok - (.*)$') { $unitRan++; Report $true $matches[1] '' }
    elseif ($line -match '^not ok - ([^:]*): (.*)$') { $unitRan++; Report $false "unit: $($matches[1])" $matches[2] }
}
$summary = $r.Lines | Where-Object { $_ -match '^summary\s+(\d+)\s+(\d+)' } | Select-Object -Last 1
if ($summary -match '^summary\s+(\d+)\s+(\d+)') {
    Report ([int]$matches[1] -eq $unitRan) 'unit: every check reported' "summary says $($matches[1]), parsed $unitRan"
} else {
    Report $false 'unit: summary line' ($r.Out.Substring([Math]::Max(0, $r.Out.Length - 400)))
}
Write-Host "  $unitRan unit checks"

# ------------------------------------------------------------------ #
# Layer 2: scenarios                                                  #
# ------------------------------------------------------------------ #

. (Join-Path $tests 'scenarios.ps1')

# Runs one scenario and returns the list of expectations it failed.
function Get-ScenarioFailures($exe, $s) {
    $seed = $null
    if ($s.RawSeed) { $seed = [string]$s.RawSeed }
    elseif (-not $s.NoFile) { $seed = @($s.Seed) }
    $r = Invoke-Session $exe $seed @($s.Keys)
    $script:fails = New-Object System.Collections.ArrayList
    if ($r.Out -match 'RUNTIME ERROR\s*(\d+)\s*AT LINE\s*(\d+)') {
        [void]$script:fails.Add("runtime error $($matches[1]) at line $([int]$matches[2] - $script:Prelude) of REPORT.BAS")
    } elseif ($r.TimedOut) {
        [void]$script:fails.Add('timed out: the program stopped, waiting for input')
    } else {
        & $s.Check $r
    }
    return ,$script:fails
}

Write-Host 'Building the program...'
$appExe = Build-Qb64 'report' (Convert-ToConsole $current)
foreach ($s in $Scenarios) {
    $f = Get-ScenarioFailures $appExe $s
    Report ($f.Count -eq 0) "scenario: $($s.Name)" ($f -join "`n      ")
}
Write-Host "  $($Scenarios.Count) scenarios"

# ------------------------------------------------------------------ #
# The same scenarios against the baseline                             #
# ------------------------------------------------------------------ #

$origNote = $null
if ($NoOriginal) {
    $origNote = 'skipped (-NoOriginal)'
} elseif (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    $origNote = 'skipped: git is not on PATH'
} else {
    # Under Stop, Windows PowerShell turns git's complaint about a missing ref
    # into a terminating error even with 2>$null, so a clone with no local
    # 'main' crashed here instead of skipping.
    $ErrorActionPreference = 'Continue'
    $subject = (& git -C $root log -1 --format=%s $Baseline 2>$null)
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -ne 0 -or $subject -ne $BaselineSubject) {
        $origNote = "skipped: '$Baseline' is not the baseline commit ('$BaselineSubject')"
    }
}

if ($origNote) {
    Write-Host "Against the original: $origNote" -ForegroundColor Yellow
} else {
    $prev = [Console]::OutputEncoding
    [Console]::OutputEncoding = $utf8
    try { $orig = (& git -C $root show "${Baseline}:REPORT.BAS") -join "`r`n" }
    finally { [Console]::OutputEncoding = $prev }

    Write-Host 'Building the original...'
    $origExe = Build-Qb64 'original' (Convert-ToConsole $orig)
    $reproduced = 0; $tagged = 0
    foreach ($s in $Scenarios) {
        $f = Get-ScenarioFailures $origExe $s
        if ($s.Defect) {
            $tagged++
            if ($f.Count -gt 0) { $reproduced++ }
            Report ($f.Count -gt 0) "original: $($s.Name)" "tagged $($s.Defect) but passes against $Baseline, so it tests nothing"
        } else {
            Report ($f.Count -eq 0) "original: $($s.Name)" ("untagged but fails against ${Baseline}:`n      " + ($f -join "`n      "))
        }
    }
    Write-Host "  $reproduced of $tagged regression scenarios fail against $Baseline, as they should"
}

if (-not $KeepBuild) { Remove-Item -Recurse -Force $build -ErrorAction SilentlyContinue }
else { Write-Host "Build kept in $build" }

Write-Host ''
if ($script:failed -eq 0) {
    Write-Host "$($script:total) checks, all passed" -ForegroundColor Green
    exit 0
}
Write-Host "$($script:total) checks, $($script:failed) failed" -ForegroundColor Red
exit 1
