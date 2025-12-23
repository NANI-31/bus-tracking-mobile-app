adb tcpip 5555
adb connect 192.168.29.181:5555
adb devices

# Project Architecture Overview

## 1. High-Level Architecture

The project is a **College Bus Tracking System** consisting of:

- **Mobile App**: Flutter (iOS/Android).
- **Backend API**: Node.js (Express, TypeScript).
- **Database**: MongoDB (via Mongoose).

## 2. Directory Structure

### Frontend (`/lib`)

| Directory | Purpose |
|OB|---|---|
| `screens/` | UI screens organized by role (`student`, `teacher`, `driver`, `coordinator`, `admin`). |
| `services/` | Data and business logic layer (`ApiService`, `AuthService`). |
| `models/` | Data classes mirroring database schemas (`User`, `Bus`, `Route`). |
| `utils/` | Helpers, Constants, and Routing configuration (`GoRouter`). |

### Backend (`/server/src`)

| Directory      | Purpose                                                   |
| -------------- | --------------------------------------------------------- |
| `controllers/` | Request handling logic (CRUD, Auth).                      |
| `models/`      | Mongoose schemas defining MongoDB collections.            |
| `routes/`      | API endpoint definitions mapping to controllers.          |
| `config/`      | Database connection (`db.ts`) and environment setup.      |
| `index.ts`     | Server entry point, middleware setup, and route mounting. |

## 3. Key Data Flows

### Authentication (Custom Implementation)

1.  **User Input**: Login/Register forms.
2.  **Frontend**: `AuthService` calls `ApiService` -> `/api/auth/*`.
3.  **Backend**: `authController` hashes passwords (bcrypt) and issues JWTs.
4.  **Session**: JWT is stored in `SharedPreferences` on the device.

### Data Fetching (Post-Migration)

- **Previous**: Direct connection to Firebase Firestore (Streams).
- **Current**: `FirestoreService` acts as a facade wrapper.
  - _Reads_: Calls `ApiService` REST endpoints.
  - _Real-time_: Uses **Polling** (`Stream.periodic`) to simulate streams (e.g., waiting 4s between location updates).

### Navigation

- **Router**: `GoRouter` manages navigation.
- **Guards**: `redirect` logic in `AppRouter` checks `AuthService` state to protect routes and redirect based on `UserRole`.

## 4. Current Status (Migration Complete)

- **Firebase**: Completely removed (Imports deleted, `main.dart` updated).
- **Dependencies**: Backend libraries (`bcryptjs`, `jsonwebtoken`) installed.
- **APIs**:
  - `/api/auth`: Functional.
  - `/api/users`, `/api/buses`: Functional (CRUD).
- **Gap Analysis**:
  - _Live Updates_: Polling is less efficient than WebSockets/Firestore Streams for live bus tracking.
  - _Notifications_: Currently local-only stubs (Firebase Messaging removed).

## 5. Next Recommended Steps

1.  **Profile Enhancements**: Allow editing of profile details.
2.  **Optimized Tracking**: Switch from Polling to **WebSockets (Socket.io)** for real-time bus location to reduce server load and latency.
