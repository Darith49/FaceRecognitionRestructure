# Face Recognition Attendance System (Pure Flutter)

A modern, standalone, cross-platform facial biometric attendance management application built **100% in Flutter**.

This project operates completely client-side without any dependency on external Django REST backends or Firebase cloud services. The facial recognition engine is inspired by the architectural patterns of [kby-ai/FaceRecognition-Flutter](https://github.com/kby-ai/FaceRecognition-Flutter), engineered in pure Dart to run deterministically on **both Web and Native** platforms.

---

## Key Features

### 1. Biometric Face Recognition Engine (Inspired by kby-ai)
- **Person Profile Model**: Holds biometric templates (`templates`), facial crop images (`faceJpg`), employee metadata, and enrollment timestamps.
- **On-Device Feature Extraction**: Extracts standardized 128-dimensional spatial luminance gradient vectors with zero-mean contrast invariance.
- **High-Precision Cosine Similarity**: Computes cosine distance matching between candidate and enrolled biometric templates:
  $$\text{similarity} = \frac{\sum A_i B_i}{\sqrt{\sum A_i^2} \sqrt{\sum B_i^2}}$$
- **Liveness & Quality Metric**: Analyzes high-frequency Laplacian variance to ensure images are sharp, well-lit, and real before confirming verification.
- **Fast 1:N Identification & Attendance Marking**: Instantly compares candidate faces against enrolled staff, verifies threshold criteria ($\ge 72\%$), and logs attendance check-in / check-out with Cambodia (UTC+7) timestamps and GPS coordinates.

### 2. Standalone Offline Architecture (No Backend Needed)
- **Zero Django / Zero Firebase**: All server-side dependencies have been removed.
- **Cross-Platform Persistence**: Built with `GetStorage` for synchronous, instant data caching and local persistence across Web and Native.
- **Local Data & Auth Services**: Pre-seeded with realistic initial branches, departments, work schedules, leaves, and demo employee accounts.
- **Face Login**: Employees can log into the application directly through biometric facial matching.

---

## Pre-Seeded Demo Accounts

You can log in directly using any of the following pre-configured credentials:

| Role | Email | Password |
|---|---|---|
| **CEO** | `ceo@company.com` | `password123` (or any) |
| **Manager** | `manager@company.com` | `password123` (or any) |
| **Employee** | `employee@company.com` | `password123` (or any) |

*New accounts entered at login are also automatically initialized and activated in local storage.*

---

## Supported Platforms

- **Web**: Chrome, Edge, Safari, Firefox
- **Native Mobile**: Android, iOS
- **Desktop**: Windows, macOS, Linux

---

## How to Run

Navigate into the Flutter application folder:

```bash
cd face_recognition_attendance
```

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run on Web
```bash
flutter run -d chrome
# or
flutter run -d edge
```

### 3. Build Web Production Bundle
```bash
flutter build web --no-tree-shake-icons
```

### 4. Run Biometric Unit Tests
```bash
dart run test/face_engine_test.dart
```

---

## Architecture Overview

```
face_recognition_attendance/
├── lib/
│   ├── core/
│   │   ├── services/
│   │   │   ├── face_recognition_engine.dart  # 128-d biometrics & cosine similarity
│   │   │   ├── local_database_service.dart   # Offline GetStorage repository
│   │   │   ├── local_auth_service.dart       # Local session & authentication
│   │   │   └── api_service.dart              # Local router adapter
│   ├── features/
│   │   ├── face/
│   │   │   ├── model/person_model.dart       # Biometric Person representation
│   │   │   └── view/face_capture_screen.dart # On-device face capture & matching UI
│   │   ├── auth/                             # Login, remember-me, role routing
│   │   ├── attendance_screen/                # Attendance logs & summary
│   │   ├── employee/                         # Employee directory & CRUD
│   │   ├── department/ & branch/             # Organizational hierarchy
│   │   └── Leave_screen/ & Overtime_screen/  # Employee request workflows
│   └── main.dart                             # Application entry point
└── test/
    └── face_engine_test.dart                 # Biometric verification unit tests
```
