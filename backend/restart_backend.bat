@echo off
echo ============================================
echo Restarting Dharma CMS Backend Server
echo ============================================
echo.

echo Stopping any running backend servers...
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *uvicorn*" 2>nul
timeout /t 2 /nobreak >nul

echo.
echo Starting backend server...
echo.
cd /d "%~dp0"
python -m uvicorn main:app --reload

pause
