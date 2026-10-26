#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "======================================================================"
echo "   Launching Face Attendance App with SQLite Persistence (Linux/Brave)"
echo "======================================================================"

export PATH="$HOME/development/flutter/bin:$HOME/.local/bin:$PATH"
export CHROME_EXECUTABLE="/snap/bin/brave"

# 1. Check if SQLite server is running
if curl -s --connect-timeout 1 http://127.0.0.1:8080/api/health >/dev/null 2>&1; then
    echo "[1/2] SQLite Backend Server is already running."
else
    echo "[1/2] Starting SQLite Backend Server in background..."
    dart run server/server.dart &
    sleep 2
fi

# 2. Launch Flutter Web App
echo "[2/2] Starting Flutter App in Brave Browser..."
flutter run -d chrome
