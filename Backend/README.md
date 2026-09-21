# Attendance System - MVP Django Backend

Clean, lightweight Django REST Framework backend designed for facial recognition and GPS geofenced attendance tracking.

---

## 🚀 Quick Start

### 1. Python & Virtual Environment
Use the pre-configured virtual environment containing Python 3.12, Django 5.2, DRF, DeepFace, TensorFlow, and Firebase Admin:

```bash
# Activate virtual environment
source "/home/seangsonar/DATA/User/Documents/Acleda/Acleda Year3 Sermister1/IOS/Test_Library/FaceTest/backend/env/bin/activate"

# Or use the python binary directly:
PYTHON="/home/seangsonar/DATA/User/Documents/Acleda/Acleda Year3 Sermister1/IOS/Test_Library/FaceTest/backend/env/bin/python"
```

### 2. Configure Environment (`.env`)
A `.env` file is present in `Backend/`. To use Firebase Admin SDK for user invitation:
1. Download your Firebase service account JSON from Firebase Console > Project Settings > Service Accounts.
2. Save it as `Backend/firebase-credentials.json` (or set `FIREBASE_CREDENTIALS_PATH` in `.env`).

### 3. Run Migrations & Tests
```bash
cd Backend

# Verify database migrations (SQLite)
$PYTHON manage.py migrate

# Run unit tests
$PYTHON manage.py test api
```

### 4. Start the Django Server
To allow access from mobile devices on the same Wi-Fi network:
```bash
$PYTHON manage.py runserver 0.0.0.0:8000
```

---

## 📡 API Endpoints (v1)

All endpoints reside under `/api/v1/` and require a valid Firebase ID token as `Authorization: Bearer <token>`:

| Method | Endpoint | Allowed Roles | Description |
|---|---|---|---|
| `GET` | `/api/v1/branches/` | All | List branches |
| `POST` | `/api/v1/branches/` | CEO | Create a branch with coordinates & radius |
| `GET, PATCH, DELETE` | `/api/v1/branches/<id>/` | CEO (modify/delete) | Manage branch details |
| `GET` | `/api/v1/departments/` | All | List departments (`?branch_id=` filter) |
| `POST` | `/api/v1/departments/` | CEO, Manager | Create a department under a branch |
| `GET, PATCH, DELETE` | `/api/v1/departments/<id>/` | CEO, Manager | Manage department details |
| `GET` | `/api/v1/employees/` | CEO, Manager, Leader | List employees |
| `POST` | `/api/v1/employees/` | CEO, Manager, Leader | Invite employee (Firebase + SQLite + Firestore sync) |
| `GET` | `/api/v1/employees/me/` | Authenticated | Profile & status of logged-in user |
| `POST` | `/api/v1/face/register/` | Authenticated | Upload face photo, extract ArcFace embedding |
| `GET` | `/api/v1/face/status/` | Authenticated | Check if face is registered |
| `POST` | `/api/v1/attendance/check-in/` | Manager, Leader, Employee | Face match + Haversine GPS geofence check-in (CEO exempt) |
| `POST` | `/api/v1/attendance/check-out/`| Manager, Leader, Employee | Face match + Haversine GPS geofence check-out (CEO exempt) |
| `GET` | `/api/v1/attendance/status/` | Authenticated | Today's check-in/out status |
| `GET` | `/api/v1/attendance/records/`| Authenticated | Historical attendance records |

---

## 📱 Connecting Flutter Client

In Flutter (`face_recognition_attendance/`), configure the host machine's LAN IP in:
`lib/core/config/api_config.dart`

```dart
static String serverHost = '10.143.129.83'; // Change to your local IP or 10.0.2.2 for Android Emulator
static int serverPort = 8000;
```
