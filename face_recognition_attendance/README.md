# Face Recognition Attendance Application

A cross-platform Flutter application for facial biometric attendance tracking with on-device recognition and native SQLite persistence.

---

## Quick Start

### 1. Launch App with Persistent Database (Recommended)
From this directory, run:
```powershell
.\run_with_database.bat
```
This automatically starts the SQLite backend server and runs the app on Microsoft Edge.

### 2. Manual Commands
- **Start SQLite Backend Server**:
  ```powershell
  dart run server/server.dart
  # or: .\start_database_server.bat
  ```
- **Stop SQLite Backend Server**:
  ```powershell
  .\stop_database_server.bat
  ```
- **Run Flutter on Edge**:
  ```powershell
  flutter run -d edge
  ```
- **Run Flutter on Windows Desktop**:
  ```powershell
  flutter run -d windows
  ```

---

## Seeded Demo Accounts

| Role | Email | Password |
|---|---|---|
| **CEO** | `sonarseang@gmail.com` | `password123` |
| **Admin** | `admin@gmail.com` | `password123` |
| **Manager** | `manager@gmail.com` | `password123` |
| **Team Leader** | `leader@gmail.com` | `password123` |
| **Employee** | `employee@gmail.com` | `password123` |

---

## Architecture Highlights
- **Persistent SQLite (`database/face_attendance.db`)**: Saves 128-d biometric vectors, profile pictures, and attendance logs permanently on disk.
- **Backend Server (`server/server.dart`)**: Lightweight Dart HTTP server on `http://127.0.0.1:8080`.
- **Image Compression Engine (`lib/core/utils/image_compressor.dart`)**: Compresses avatars and face reference snapshots to prevent browser storage exhaustion.
- **Biometric Face Recognition (`lib/core/services/face_recognition_engine.dart`)**: On-device 128-d feature extraction, Laplacian liveness checking, and cosine distance matching.

---

## Running Tests

```bash
dart test/sqlite_database_test.dart
dart test/sqlite_server_test.dart
dart test/vault_and_image_compression_test.dart
dart test/face_engine_test.dart
flutter analyze
```
