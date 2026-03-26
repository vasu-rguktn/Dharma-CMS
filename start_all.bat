@echo off
REM ═══════════════════════════════════════════════════════════════
REM  Dharma CMS — Start All Services
REM  Backend (8000) + Citizen Frontend (5555) + Police Frontend (5556)
REM ═══════════════════════════════════════════════════════════════

echo Starting Dharma CMS services...
echo.

REM ── Kill any existing processes on our ports ──
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /C:":8000 " ^| findstr LISTENING 2^>nul') do taskkill /PID %%a /F >nul 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /C:":5555 " ^| findstr LISTENING 2^>nul') do taskkill /PID %%a /F >nul 2>nul
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /C:":5556 " ^| findstr LISTENING 2^>nul') do taskkill /PID %%a /F >nul 2>nul
timeout /t 2 /nobreak >nul

REM ── Start Backend ──
echo [1/3] Starting Backend (FastAPI) on port 8000...
start "DharmaCMS-Backend" cmd /k "cd /d %~dp0new_backend && venv\Scripts\python.exe main.py"

REM ── Start Citizen Frontend ──
echo [2/3] Starting Citizen Frontend on port 5555...
start "DharmaCMS-Citizen" cmd /k "cd /d %~dp0new_frontend\build\web && python -m http.server 5555"

REM ── Start Police Frontend ──
echo [3/3] Starting Police Frontend on port 5556...
start "DharmaCMS-Police" cmd /k "cd /d %~dp0new_police_frontend\build\web && python -m http.server 5556"

echo.
echo ═══════════════════════════════════════════════════════════
echo   All services starting...
echo   Backend:          http://localhost:8000
echo   Citizen Frontend: http://localhost:5555
echo   Police Frontend:  http://localhost:5556
echo   Backend API Docs: http://localhost:8000/docs
echo ═══════════════════════════════════════════════════════════
echo.
echo Waiting for services to be ready...
timeout /t 8 /nobreak >nul

REM ── Verify ──
curl -s http://localhost:8000/ >nul 2>nul && echo   [OK] Backend is running || echo   [!!] Backend NOT responding
curl -s http://localhost:5555/ >nul 2>nul && echo   [OK] Citizen Frontend is running || echo   [!!] Citizen Frontend NOT responding
curl -s http://localhost:5556/ >nul 2>nul && echo   [OK] Police Frontend is running || echo   [!!] Police Frontend NOT responding
echo.
echo Done. Press any key to close this window.
pause >nul
