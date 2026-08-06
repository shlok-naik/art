# Starts the backend (uvicorn) then the frontend (flutter run), and cleans
# up the backend process tree when flutter run exits or you press Ctrl+C.

$ErrorActionPreference = "Stop"

if (-not (Test-Path "backend\.venv")) {
    Write-Host "Creating backend virtualenv..."
    python -m venv backend\.venv
}

# .venv is gitignored (correctly — it's per-machine), so nothing else keeps
# it in sync with requirements.txt as dependencies get added. Re-running
# this each time is a no-op when nothing changed, and self-heals a stale
# venv (e.g. "ModuleNotFoundError: better_profanity") when it did.
Write-Host "Syncing backend dependencies..."
& backend\.venv\Scripts\pip install -q -r backend\requirements.txt

Write-Host "Starting backend (uvicorn)..."
$backend = Start-Process -FilePath "backend\.venv\Scripts\uvicorn.exe" `
    -ArgumentList "--app-dir", "backend", "main:app", "--reload", "--port", "8000" `
    -NoNewWindow -PassThru

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
}
