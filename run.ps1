# Starts the backend (uvicorn) then the frontend (flutter run), and cleans
# up the backend process tree when flutter run exits or you press Ctrl+C.

$ErrorActionPreference = "Stop"

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
