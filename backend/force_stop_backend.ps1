# force_stop_backend.ps1
Write-Host "Forcing stop of Python processes..."
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process uvicorn -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "All Python processes stopped. Now verify looking at ports..."
Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
Write-Host "Port 8000 cleared."
Write-Host "You can now start the backend normally."
