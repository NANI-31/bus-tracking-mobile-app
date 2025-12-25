# College Bus Tracking - Backend Server Analysis

## 1. Project Overview

**Name:** Server (Node.js)
**Type:** REST API & Real-time Server
**Purpose:** Backend for College Bus Tracking system, handling data persistence, authentication, and real-time location updates.

## 2. Architecture & Tech Stack

- **Runtime:** Node.js
- **Framework:** Express.js
- **Language:** TypeScript
- **Database:** MongoDB (Mongoose ODM)
- **Real-time:** Socket.IO
- **Notification:** Firebase Admin SDK (FCM)
- **Authentication:** JWT (JSON Web Tokens)

## 3. Directory Structure

`src/`

- **config/**: Database connection, Firebase setup.
- **controllers/**: Business logic.
  - `authController`: Login, Register, User management.
  - `busController`: CRUD for buses.
  - `notificationController`: Send/Manage notifications.
  - `routeController`: Route and stop management.
- **models/**: Mongoose Schemas.
  - `User`: Users with roles, FCM tokens, and language preferences.
  - `Bus`: Bus details and current location.
  - `Route`: Path coordinates and stop sequences.
  - `Notification`: Stored notification history.
  - `College`: College entities.
- **routes/**: API definition files (`authRoutes`, `busRoutes`, etc.).
- **services/**: Background services (e.g., Socket handlers).
- **utils/**: Helper functions (Templates, FCM helpers).
- **constants/**: Enums and static data (Notification types, Templates).

## 4. Data Models & Schema Highlights

- **User:**
  - `role`: 'student', 'driver', 'admin'.
  - `language`: Enum ['en', 'hi', 'te'] (Default: 'en').
  - `fcmToken`: For push notifications.
- **Bus:** Handles `currentLocation` (Lat/Lng), `status`, `driverId`.
- **Notification:** Typed notifications with multi-language template support.

## 5. Key APIs

- **Auth:** `/api/auth/register`, `/api/auth/login`.
- **Notifications:**
  - `/api/notifications/test`: Send random test notification.
  - `/api/notifications/templated`: Send specific templated notification.
- **Sockets:**
  - Events: `update-location`, `bus-location-update`, `join-room`.

## 6. Recent Developments

- **Notification Templates:** Implemented multi-language templates (En, Hi, Te) for various scenarios (Delay, Arrival, Cancelled).
- **User Language:** Added `language` field to User schema to support localized notifications.
- **Refactoring:** Improved controller logic for notification dispatching.

## 7. Recommendations

- **Validation:** Add stricter request validation (e.g., using Joi or Zod).
- **Rate Limiting:** Implement rate limiting for public endpoints.
- **Logging:** Integrate a structured logger (like Winston) for better production monitoring.
