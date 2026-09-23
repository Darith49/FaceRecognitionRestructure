# Face Recognition Attendance System

A modern, cross-platform facial biometric attendance management application built with **Flutter**, an on-device biometric engine, a **native SQLite database**, and a lightweight local synchronization backend.

The biometric recognition engine is inspired by the architectural patterns of [kby-ai/FaceRecognition-Flutter](https://github.com/kby-ai/FaceRecognition-Flutter), engineered in pure Dart to run deterministically on **Web, Windows, macOS, Linux, Android, and iOS**.

---

## Key Features

### 1. Persistent SQLite Database & Local Backend
- **Real SQLite Database (`database/face_attendance.db`)**: Saves all user data, profile pictures, 128-dimensional biometric embeddings, reference images, attendance logs, and requests on local disk outside the browser sandbox.
- **Lightweight Dart Backend Server (`server/server.dart`)**: Zero external server runtime required. Uses standard library `dart:io` `HttpServer` and `sqlite3.dll` with full CORS support on `http://127.0.0.1:8080`.
- **Automatic Client Synchronization (`SqliteSyncService`)**: Hydrates the client on startup via `/api/bootstrap` and replicates registrations, profile updates, and attendance logs to SQLite in real time.
- **Full Offline Fallback**: If the backend server is offline, the app seamlessly runs with local cached storage (`GetStorage`) without interrupting the user.

### 2. High-Efficiency Image Compression & Biometric Vault
- **Automatic Image Compression (`ImageCompressor`)**: Resizes profile avatars to max 200×200 px (~4–10 KB) and face reference crops to max 160×160 px (~2–5 KB). Reduces storage footprint by >98% to prevent browser quota errors (`QuotaExceededError`).
- **Persistent User Account Vault**: Permanently binds biometric templates, face reference snapshots, and avatars to user email accounts across logins, logouts, and app reboots.

### 3. Biometric Face Recognition Engine
- **On-Device Feature Extraction**: Extracts standardized 128-dimensional spatial luminance gradient vectors with zero-mean contrast invariance.
- **High-Precision Cosine Similarity**: Computes cosine distance matching between candidate and enrolled biometric templates:
  $$\text{similarity} = \frac{\sum A_i B_i}{\sqrt{\sum A_i^2} \sqrt{\sum B_i^2}}$$
- **Liveness & Quality Metric**: Analyzes high-frequency Laplacian variance to ensure images are sharp, well-lit, and real before confirming enrollment or clocking.
- **Fast 1:N Identification & Attendance Marking**: Instantly compares candidate faces against enrolled staff, verifies threshold criteria ($\ge 72\%$), and logs attendance check-in / check-out with Cambodia (UTC+7) timestamps and GPS coordinates.
- **Face Login**: Employees can log into the application directly through biometric facial matching.

### 4. Executive & Role-Based Workflows
- **CEO Executive Dashboard**: Dedicated Executive Attendance Card with live status badge, shift times, today's worked hours, and interactive Clock In / Clock Out button.
- **CEO Control Panel**: Executive actions grid with quick-access Clock Attendance shortcuts and company management.
- **Request Screen Attendance**: All roles (CEO, Manager, Leader, Employee) can view and use the inline attendance card on the Request screen.
- **Self-Service Requests**: Leave applications, overtime requests, and employee suggestions with management approval workflows.
- **Modern Liquid Glass UI**: Built with `liquid_glass_widgets` for sleek glassmorphic aesthetics.

---

## Pre-Seeded Demo Accounts

You can log in directly using any of the following pre-configured credentials (password can be `password123` or any text in demo mode):

| Role | Full Name | Email | Default Status |
|---|---|---|---|
| **CEO** | Sonar Seang | `sonarseang@gmail.com` | Active |
| **Admin** | System Admin | `admin@gmail.com` | Active |
| **Manager** | Sarah Manager | `manager@gmail.com` | Active |
| **Team Leader** | David Team Leader | `leader@gmail.com` | Active |
| **Employee** | Alex Developer | `employee@gmail.com` | Active |

*New accounts entered at login are also automatically initialized and persisted in the database.*

---

## How to Run

### Quick Start (One-Click)

From the project root directory, run:

```powershell
.\run.bat
```

> **What `.\run.bat` does:**
> 1. Automatically checks and starts the SQLite backend server in the background.
> 2. Launches the Flutter application in Microsoft Edge (`flutter run -d edge`).

---

### Manual Start (Two Terminals)

If you prefer to run the backend and Flutter app separately:

#### Terminal 1 — Start SQLite Backend Server
```powershell
.\start_server.bat
# or:
cd face_recognition_attendance
dart run server/server.dart
```

#### Terminal 2 — Start Flutter App
```powershell
cd face_recognition_attendance
flutter run -d edge
```

To run as a **native Windows desktop app**:
```powershell
cd face_recognition_attendance
flutter run -d windows
```

---

## How to Stop

1. **Stop Flutter App**: Press `q` or `Ctrl + C` in the running Flutter terminal.
2. **Stop SQLite Server**: Run `.\stop.bat` (or close the server window).

```powershell
.\stop.bat
```

---

## Running Tests

All core layers (database, server, compression, face engine) include automated unit and integration tests:

```bash
cd face_recognition_attendance

# 1. SQLite Database Unit Tests (Table creation, biometrics, disk persistence)
dart test/sqlite_database_test.dart

# 2. SQLite Backend Server Integration Tests (REST API, CORS, face registration)
dart test/sqlite_server_test.dart

# 3. Vault & Image Compression Tests (Image size reduction & model serialization)
dart test/vault_and_image_compression_test.dart

# 4. Biometric Face Engine Tests (Cosine similarity, 128-d templates, liveness)
dart test/face_engine_test.dart

# 5. Static Code Analysis
flutter analyze
```

---

## Project Architecture

```
face_recognition_attendance/
├── database/
│   └── face_attendance.db            # Persistent SQLite database file
├── server/
│   ├── database.dart                 # AppSqliteDatabase (tables, migrations, CRUD)
│   └── server.dart                   # Lightweight Dart HTTP REST backend (port 8080)
├── lib/
│   ├── config/
│   │   ├── bindings/                 # Initial and screen controller bindings
│   │   ├── routes/                   # App routing definitions
│   │   └── theme/                    # App themes & color palettes
│   ├── core/
│   │   ├── services/
│   │   │   ├── face_recognition_engine.dart # 128-d biometrics & cosine similarity
│   │   │   ├── sqlite_sync_service.dart     # SQLite client sync & bootstrap
│   │   │   ├── local_database_service.dart  # Offline storage & cache repository
│   │   │   ├── local_auth_service.dart      # Authentication & session manager
│   │   │   ├── secure_storage_service.dart  # Encrypted session persistence
│   │   │   └── api_service.dart             # API router & multipart face handler
│   │   └── utils/
│   │       └── image_compressor.dart        # Avatar & reference image compressor
│   ├── features/
│   │   ├── auth/                            # Login, registration, role models
│   │   ├── face/                            # Face capture & biometric matching UI
│   │   ├── home_screen/                     # Executive & employee dashboards
│   │   ├── clock_screen/                    # Camera clock in/out scanning
│   │   ├── attendance_screen/               # Monthly records & attendance logs
│   │   ├── ceo_panel/                       # CEO executive control center
│   │   ├── employee/                        # Staff directory & team management
│   │   ├── department/ & branch/            # Organizational structure
│   │   ├── Leave_screen/ & Overtime_screen/ # Leave & overtime requests
│   │   └── profile_screen/                  # Profile & avatar management
│   └── main.dart                            # Application entry point
├── test/                                    # Automated unit & integration tests
├── run_with_database.bat                    # Inner one-click launcher
├── start_database_server.bat                # Inner server launcher
├── stop_database_server.bat                 # Inner server stop script
└── sqlite3.dll                              # Native SQLite library for Windows
```

---

## Supported Platforms

| Platform | Support | Storage / Database |
|---|---|---|
| **Web** (Edge, Chrome, Safari, Firefox) | Supported | SQLite Backend (`127.0.0.1:8080`) + Local Cache |
| **Windows Desktop** | Supported | Native SQLite (`face_attendance.db`) |
| **Android** | Supported | SQLite / Local Storage |
| **iOS** | Supported | SQLite / Local Storage |
| **macOS / Linux** | Supported | SQLite / Local Storage |
