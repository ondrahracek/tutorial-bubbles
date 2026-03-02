# Ralph Loop: Iterative AI agent execution until PRD completion
# Runs Cursor CLI repeatedly, stopping when the agent signals COMPLETE.
# See: https://ralph-cli.dev/ | https://cursor.com/docs/cli/using
#
# Environment: Flutter package or app (pubspec.yaml). Android build supported.
# Prerequisites: Cursor CLI (agent) and Flutter SDK in PATH. Run from project root or ralph/.
# Usage: .\ralph.ps1 [iterations]

$ErrorActionPreference = 'Stop'

$Script:CompleteMarker = '<promise>COMPLETE</promise>'
$Script:PrdFile = 'ralph/prd.json'
$Script:ProgressFile = 'ralph/progress.txt'

function Set-ProjectRoot {
    $root = Resolve-Path (Join-Path $PSScriptRoot '..')
    if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
        Write-Error "pubspec.yaml not found in $root - this must be a Flutter project root"
    }
    Set-Location $root
}
Set-ProjectRoot

function Show-Usage {
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) [iterations]"
    Write-Host ""
    Write-Host "  iterations  Maximum number of agent iterations (default: prompts interactively)"
    Write-Host ""
    Write-Host "Ralph runs Cursor CLI in a loop. Each iteration implements the highest-priority"
    Write-Host "PRD feature. The loop stops when the agent outputs $Script:CompleteMarker"
    Write-Host "or when the iteration limit is reached."
    exit 1
}

function Get-Iterations {
    param([string]$Arg)
    if ($Arg) {
        $n = 0
        if ([int]::TryParse($Arg, [ref]$n) -and $n -gt 0) {
            return $n
        }
        Write-Error "iterations must be a positive integer"
    }
    while ($true) {
        $userInput = Read-Host "Enter number of iterations"
        $n = 0
        if ([int]::TryParse($userInput, [ref]$n) -and $n -gt 0) {
            return $n
        }
        Write-Host "Please enter a positive integer." -ForegroundColor Red
    }
}

function Invoke-AgentIteration {
    $prompt = "@$Script:PrdFile @$Script:ProgressFile

This is a Flutter package or app. Work on one PRD feature per iteration.

1. Find the highest-priority PRD feature to work on and work ONLY on that feature.
   Choose the one YOU decide has the highest priority - not necessarily the first in the list.
2. Before committing, run the feedback loops:
   - flutter analyze (must pass with no errors; address any warnings)
   - flutter test (must pass)
   - If the package has an example/ app: run 'flutter pub get' and 'flutter analyze' in example/
3. Update the PRD: set passes to true for the item(s) you completed.
4. Append your progress to the $Script:ProgressFile file. Keep it concise for the next iteration.
5. Make a git commit of that feature.
ONLY WORK ON A SINGLE FEATURE.

When the PRD is fully complete (all items have passes: true), output exactly this on its own line as the final signal:
$Script:CompleteMarker
Do NOT mention or reference this marker anywhere else in your response (e.g. do not write ""was not emitted"" or similar)."

    & agent -p $prompt --force --trust --workspace (Get-Location).Path 2>&1 | Out-String
}

# Main
if ($args[0] -eq '-h' -or $args[0] -eq '--help') {
    Show-Usage
}

$iterations = Get-Iterations -Arg $args[0]

Write-Host "Ralph Loop: up to $iterations iteration(s)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "Stopping when agent outputs: $Script:CompleteMarker"
Write-Host ""

for ($i = 1; $i -le $iterations; $i++) {
    Write-Host "========== Iteration $i / $iterations =========="
    Write-Host ""

    try {
        $result = Invoke-AgentIteration
    } catch {
        $result = $_.Exception.Message
    }
    Write-Host $result

    $resultLines = $result -split "`n" | ForEach-Object { $_.Trim() }
    $hasCompleteMarker = $resultLines -contains $Script:CompleteMarker
    $hasNegativePhrase = $result -notlike "*was not emitted*" -and $result -notlike "*did not emit*"

    if ($hasCompleteMarker -and $hasNegativePhrase) {
        Write-Host ""
        Write-Host "PRD complete after $i iteration(s). Exiting."
        exit 0
    }

    if ($i -lt $iterations) { Write-Host "" }
}

Write-Host ""
Write-Host "Reached iteration limit ($iterations). Run again to continue."
exit 0
