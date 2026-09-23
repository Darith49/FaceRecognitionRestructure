@echo off
title Face Attendance SQLite Backend Server
cd "%~dp0face_recognition_attendance"
echo Starting SQLite Server from: %CD%
dart run server/server.dart
pause
