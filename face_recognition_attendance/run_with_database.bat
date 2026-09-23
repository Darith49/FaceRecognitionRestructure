@echo off
title Face Attendance App with SQLite Persistence
echo ======================================================================
echo    Launching Face Attendance App with SQLite Persistence
echo ======================================================================

echo [1/2] Checking SQLite Backend Server...
powershell -Command "try { $res = Invoke-RestMethod -Uri 'http://127.0.0.1:8080/api/health' -TimeoutSec 1; Write-Host 'SQLite Server already running.' } catch { Start-Process cmd -ArgumentList '/k start_database_server.bat' -WindowStyle Minimized; Write-Host 'Started SQLite Server in background.' }"

timeout /t 2 /nobreak >nul

echo [2/2] Starting Flutter App in Edge...
flutter run -d edge
