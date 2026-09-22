# Attendance System - Django REST API Backend

Clean, modular Django REST Framework backend with ArcFace face recognition, GPS geofencing, and SQLite persistence, fully containerized with Docker and Docker Compose.

---

## 📁 Project Structure

```text
Backend/
├── Dockerfile                  # Multi-layer, production-ready Python 3.12 container
├── docker-compose.yml          # Single-service Django REST API setup with SQLite persistence
├── entrypoint.sh               # Container init: migrations, static files, and server boot
├── .dockerignore               # Ignores venv, host caches, and credentials during build
├── .env.example                # Environment configuration template
├── .env                        # Local / container environment secrets (not in git)
├── .gitignore                  # Git exclusions for sqlite, journals, media, and keys
├── requirements.txt            # Python dependencies (Django 5.2, DRF, DeepFace, etc.)
├── manage.py                   # Django CLI management script
├── config/                     # Django core project configuration
│   ├── settings.py             # App settings (SQLite path, CORS, Auth, Media)
│   ├── urls.py                 # Root URL router & /health/ endpoint
│   ├── wsgi.py                 # WSGI application entrypoint for Gunicorn
│   └── asgi.py                 # ASGI application entrypoint
├── api/                        # Modular API application package
│   ├── health.py               # Unauthenticated container & service health check
│   ├── models.py               # Aggregate model registry
│   ├── serializers.py          # Aggregate serializer registry
│   ├── views.py                # Aggregate view registry
│   ├── permissions.py          # Firebase token & role-based permissions
│   ├── urls.py                 # /api/v1/ endpoints router
│   ├── tests.py                # Comprehensive test suite (17 test cases)
│   ├── branch/                 # Branch CRUD & coordinates
│   ├── department/             # Department management
│   ├── employee/               # Employee profiles & team hierarchy
│   ├── face/                   # Face registration & ArcFace embeddings
│   ├── attendance/             # Attendance check-in / check-out with geofencing
│   ├── common/                 # Firebase Auth & shared utilities
│   └── migrations/             # Database migrations
├── data/                       # Persistent SQLite database volume mount (`db.sqlite3`)
└── media/                      # Persistent user-uploaded media files volume mount
```

---

## 🐳 Docker Quick Start (Recommended)

The backend is configured as a standalone **Django REST API** container with **SQLite** database persistence. No external database container (Postgres/MySQL) is required.

### 1. Configure Environment
Ensure `.env` exists in `Backend/`:
```bash
cp .env.example .env
```

### 2. Start the Backend with Docker Compose
```bash
cd Backend

# Build and start the container in the background
docker compose up -d --build
```

The container will automatically:
1. Initialize the persistent SQLite database in `./data/db.sqlite3`
2. Run any pending database migrations
3. Collect static files
4. Launch the Gunicorn production server on port `8000`

### 3. Verify Container Health
```bash
# Check container status
docker compose ps

# Test the health check endpoint
curl http://localhost:8000/api/v1/health/
# Output: {"status":"ok","database":"healthy","service":"attendance-backend-api"}
```

### 4. Useful Docker Commands
```bash
# View live container logs
docker compose logs -f backend

# Run migrations manually inside container
docker compose exec backend python manage.py migrate

# Run test suite inside container
docker compose exec backend python manage.py test api

# Create a Django superuser
docker compose exec backend python manage.py createsuperuser

# Stop the backend
docker compose down
```

---

## 💾 SQLite Database & Volume Persistence

SQLite and media uploads persist across container rebuilds:
- **`./data:/app/data`**: Houses `db.sqlite3` and SQLite WAL journal files on the host machine.
- **`./media:/app/media`**: Houses registered face photos and avatar uploads.
- **`deepface_cache:/app/.deepface`**: Docker volume that caches downloaded ArcFace and MTCNN neural network weights so they do not need to be re-downloaded when recreating containers.

---

## 💻 Local Development (Without Docker)

You can also run the backend directly on your host machine using Python 3.12:

```bash
cd Backend

# Using the pre-configured virtual environment:
env/bin/python manage.py migrate
env/bin/python manage.py test api
env/bin/python manage.py runserver 0.0.0.0:8000
```

---

## 📡 API Endpoints (v1)

### Health Check (Unauthenticated)
- `GET /health/` or `GET /api/v1/health/` - Container & SQLite status probe.

### Business Endpoints (Require `Authorization: Bearer <firebase_id_token>`)
| Method | Endpoint | Allowed Roles | Description |
|---|---|---|---|
| `GET, POST` | `/api/v1/branches/` | All (GET), CEO (POST) | List or create branch with GPS radius |
| `GET, PATCH, DELETE` | `/api/v1/branches/<id>/` | CEO (modify/delete) | Manage branch details |
| `GET, POST` | `/api/v1/departments/` | All (GET), CEO/Manager (POST) | List or create department |
| `GET, PATCH, DELETE` | `/api/v1/departments/<id>/` | CEO, Manager | Manage department details |
| `GET, POST` | `/api/v1/employees/` | CEO, Manager, Leader | List employees or send invitation |
| `GET` | `/api/v1/employees/me/` | Authenticated | Profile & status of logged-in user |
| `GET` | `/api/v1/employees/my-team/` | Authenticated | Team structure & colleagues |
| `POST` | `/api/v1/face/register/` | Authenticated | Upload face photo, extract ArcFace embedding |
| `GET` | `/api/v1/face/status/` | Authenticated | Check if face is registered |
| `POST` | `/api/v1/attendance/check-in/` | Manager, Leader, Employee | Face match + GPS geofence check-in |
| `POST` | `/api/v1/attendance/check-out/`| Manager, Leader, Employee | Face match + GPS geofence check-out |
| `GET` | `/api/v1/attendance/status/` | Authenticated | Today's check-in/out status |
| `GET` | `/api/v1/attendance/records/`| Authenticated | Historical attendance records |

---

## 📱 Connecting Mobile Clients (Flutter / iOS)

In Flutter (`face_recognition_attendance/lib/core/config/api_config.dart`):
```dart
static String serverHost = '10.143.129.83'; // Your host LAN IP, or 10.0.2.2 for Android Emulator
static int serverPort = 8000;
```
When running with Docker, ensure `ALLOWED_HOSTS=*` or includes your LAN IP in `.env`.
