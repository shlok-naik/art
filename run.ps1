# Starts the backend (uvicorn) then the frontend (flutter run), and cleans
# up the backend process tree when flutter run exits or you press Ctrl+C.

$ErrorActionPreference = "Stop"

if (-not (Test-Path "backend\.venv")) {
    Write-Host "Creating backend virtualenv..."
    python -m venv backend\.venv
}

# .venv is gitignored (correctly - it's per-machine), so nothing else keeps
# it in sync with requirements.txt as dependencies get added. Re-running
# this each time is a no-op when nothing changed, and self-heals a stale
# venv (e.g. "ModuleNotFoundError: better_profanity") when it did.
#
# $ErrorActionPreference only makes *cmdlet* failures terminating - a
# non-zero exit code from a native exe like pip is silently ignored unless
# checked explicitly, so without this check a failed install would fall
# through and still launch uvicorn against the broken venv.
#
# pip's own stderr output (even a non-fatal notice, e.g. "a new release of
# pip is available") gets wrapped by PowerShell 5.1 into a terminating
# NativeCommandError under $ErrorActionPreference = "Stop", aborting the
# script before the exit-code check below ever runs - even though pip
# itself exited 0. Relax to "Continue" for just this call so stderr text
# doesn't kill the script; $LASTEXITCODE still catches a genuine failure.
Write-Host "Syncing backend dependencies..."
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& backend\.venv\Scripts\pip install -r backend\requirements.txt
$ErrorActionPreference = $previousErrorActionPreference
if ($LASTEXITCODE -ne 0) {
    Write-Error "pip install failed (exit code $LASTEXITCODE) - see output above."
    exit 1
}

Write-Host "Starting backend (uvicorn)..."
$backend = Start-Process -FilePath "backend\.venv\Scripts\uvicorn.exe" `
    -ArgumentList "--app-dir", "backend", "main:app", "--reload", "--port", "8000" `
    -NoNewWindow -PassThru

Write-Host "Opening league test-mode controller in a new window..."
# A separate window, not a forwarded keystroke inside this one: flutter run
# reads raw stdin itself for its own hot-keys (r/R/q/...), so splicing a
# custom key into that same stream would make it see a non-terminal stdin
# and silently disable its whole interactive hotkey set.
$simulator = Start-Process powershell -ArgumentList @(
    '-NoExit', '-Command', "Set-Location `"$PSScriptRoot`"; dart run tool/simulate_league.dart"
) -PassThru

try {
    Start-Sleep -Seconds 2
    Write-Host "Starting frontend (flutter run)..."
    flutter run
}
finally {
    if ($backend -and -not $backend.HasExited) {
        Write-Host "Stopping backend..."
        # uvicorn --reload forks a child worker process, so kill the whole
        # tree rather than just the parent PID.
        taskkill /PID $backend.Id /T /F | Out-Null
    }
    if ($simulator -and -not $simulator.HasExited) {
        taskkill /PID $simulator.Id /T /F | Out-Null
    }
}
