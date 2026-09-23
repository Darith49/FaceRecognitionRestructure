@echo off
title Face Attendance SQLite Backend Server
echo ======================================================================
echo    Starting Face Recognition Attendance SQLite Database Backend Server
echo    Database File: database\face_attendance.db
echo    Endpoint: http://127.0.0.1:8080
echo ======================================================================

dart run server/server.dart
pause
