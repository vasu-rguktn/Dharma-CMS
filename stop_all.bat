@echo off
REM ═══════════════════════════════════════════════════════════════
REM  Dharma CMS — Stop All Services
REM ═══════════════════════════════════════════════════════════════

echo Stopping Dharma CMS services...

for /f "tokens=5" %%a in ('netstat -ano ^| findstr /C:":8000 " ^| findstr LISTENING 2^>nul') do (
    echo Killing Backend (PID %%a)...
    taskkill /PID %%a /F >nul 2>nul
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /C:":5555 " ^| findstr LISTENING 2^>nul') do (
    echo Killing Citizen Frontend (PID %%a)...
    taskkill /PID %%a /F >nul 2>nul
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /C:":5556 " ^| findstr LISTENING 2^>nul') do (
    echo Killing Police Frontend (PID %%a)...
    taskkill /PID %%a /F >nul 2>nul
)

echo All services stopped.
