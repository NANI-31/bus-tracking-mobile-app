# College Bus Tracking - Mobile App Analysis

## 1. Project Overview

**Name:** CollegeBusTrackingFlutterApp
**Type:** Mobile Application (Flutter)
**Purpose:** Real-time bus tracking and management system for colleges, supporting students, drivers, and administrators.

## 2. Architecture & Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Navigation:** GoRouter
- **Maps:** Google Maps Flutter
- **Real-time Communication:** Socket.IO Client (`socket_io_client`)
- **Local Storage:** Shared Preferences
- **Styling:** VelocityX, Flutter Tailwind CSS Colors
- **Localization:** `flutter_localizations`, `intl` (Supports En, Hi, Te)

## 3. Directory Structure

`lib/`

- **auth/**: Authentication screens (Login, Register) and widgets.
- **l10n/**: Localization files (Auth, Home, etc.).
- **models/**: Data models (`UserModel`, `BusModel`, `RouteModel`, etc.) mirroring backend schemas.
- **screens/**:
  - **admin/**: Admin specific views.
  - **driver/**: `DriverDashboard`, Trip management.
  - **student/**: `StudentDashboard`, Profile, Tracking UI.
- **services/**:
  - `AuthService`: Authentication logic and user state.
  - `DataService`: API calls for buses, routes, stops.
  - `LocationService`: Geolocator handling.
  - `SocketService`: Real-time socket connection management.
  - `ThemeService`: Dark/Light mode handling.
  - `LocaleService`: Language switching.
- **widgets/**: Reusable UI components (`AppDrawer`, `CustomInputField`, `SuccessModal`).
- **utils/**: Constants and helper functions.

## 4. Key Features

- **Role-Based Access:** Distinct flows for Students, Drivers, and Admins.
- **Real-Time Tracking:** Drivers emit location; Students utilize it to see bus positions on map.
- **Notifications:** FCM integration for push notifications (Bus arriving, Delayed, etc.).
- **Multi-Language:** Full support for English, Hindi, and Telugu in Auth and Profile flows.
- **Bus & Route Selection:** Users can select colleges and specific routes/stops.
- **Theming:** Light/Dark mode toggles.

## 5. Recent Developments

- **Auth Localization:** Complete l10n support added for Login, Signup, Forgot Password, OTP, and Reset Password.
- **Driver Dashboard Refactor:** Modularized for better maintainability; fixed location streaming issues.
- **Language Persistence:** Language selection now syncs with the user's database profile.

## 6. Recommendations

- **Error Handling:** Standardize API error handling across `DataService`.
- **State Persistence:** Ensure critical state (like active trip) persists across app restarts effectively.
- **Testing:** Add unit and widget tests for critical flows (Auth, Tracking).
