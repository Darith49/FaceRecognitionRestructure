#!/bin/sh
set -e

# ==============================================================================
# Attendance System Backend - Container Entrypoint
# ==============================================================================

echo "=== Attendance Backend Container Starting ==="

# Ensure storage directories exist
mkdir -p /app/data /app/media /app/staticfiles /app/.deepface

# If persistent SQLite volume is empty but a seed database exists, copy it
if [ "${SQLITE_DB_PATH}" = "/app/data/db.sqlite3" ] && [ ! -f /app/data/db.sqlite3 ] && [ -f /app/db.sqlite3 ]; then
    echo "Initializing persistent SQLite database from bundled template..."
    cp /app/db.sqlite3 /app/data/db.sqlite3
fi

# Run database migrations
echo "Applying database migrations..."
python manage.py migrate --noinput

# Collect static files for WhiteNoise/Gunicorn
echo "Collecting static files..."
python manage.py collectstatic --noinput --clear 2>/dev/null || python manage.py collectstatic --noinput

echo "=== Initialization Complete. Launching Server ==="
exec "$@"
