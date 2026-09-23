@echo off
title Stop Face Attendance Services
echo Stopping Flutter and SQLite Backend Server...

:: Kill any process listening on port 8080 (SQLite Backend Server)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8080') do (
    taskkill /F /PID %%a 2>nul
)

echo SQLite Backend Server stopped.
echo Done.
pause
