# Project Architecture Overview

## Executive Summary

The project is a robust, full-stack bus tracking solution composed of three modern applications:

1.  **Mobile App**: Flutter (Android/iOS) for Students, Drivers, and Coordinators.
2.  **Web Dashboard**: React 19 + Vite for College Admins and Super Admins.
3.  **Backend API**: Node.js + Express + TypeScript serving both client applications.

Overall, the project demonstrates a high level of maturity with modern tech choices (Riverpod 2.6, React 19, TypeScript everywhere). The architecture is generally clean, with clear separation of concerns, though there are opportunities to standardize layering, particularly in the Backend.

---

## 1. Technology Stack Analysis

### Mobile App (`CollegeBusTrackingFlutterApp`)

- **Framework**: Flutter 3.x
- **State Management**: Riverpod 2.6 (AsyncNotifiers, extensive use of providers)
- **Navigation**: GoRouter (Standard declarative routing)
- **Architecture**: Hybrid Layer-by-Type / Feature-based.
- **Key Libraries**: `google_maps_flutter`, `firebase_messaging`, `flutter_local_notifications`, `socket_io_client`.

### Backend (`server`)

- **Framework**: Express.js with TypeScript.
- **Database**: MongoDB (via Mongoose).
- **Real-time**: Socket.IO for live bus tracking and SOS alerts.
- **Security**: JWT Authentication, RBAC (Role-Based Access Control).
- **Architecture**: MVC (Model-View-Controller) with localized Service logic.

### Web App (`client`)

- **Framework**: React 19 (Latest stable features).
- **Build Tool**: Vite (Fast HMR and bundling).
- **State Management**: Redux Toolkit (Standard for complex React apps).
- **Styling**: Tailwind CSS v4.
- **Architecture**: Feature-first structure (`src/features/`).

---

## 2. Project Structure Review

### ✅ Strengths

- **Monorepo-style Organization**: Logical separation of `server`, `client`, and `FlutterApp` in one repository makes context switching easier.
- **TypeScript Everywhere**: Using TS in both Backend and Web Client ensures type safety across the full web stack.
- **Config Separation**: Usage of `.env` files (implied) and config/constant files is evident.

### ⚠️ Areas for Improvement

1.  **Backend "Service" Layer**:
    - _Current_: The `services/` folder exists but logic is heavily concentrated in `controllers/`.
    - _Recommendation_: Refactor heavy business logic (e.g., complex assignment rules, ride simulation steps) out of controllers into pure service classes. This makes unit testing easier.

2.  **Mobile Feature Grouping**:
    - _Current_: Code is split by type (`screens`, `providers`, `repositories`).
    - _Recommendation_: Consider a "Feature-first" structure (e.g., `lib/features/auth/` containing screens, providers, and repo for auth). This scales better as the app grows to 50+ screens.

3.  **Shared Types**:
    - _Current_: `server` and `client` are separate TS projects.
    - _Recommendation_: If using a workspace manager (like Yarn Workspaces or Nx), you could share DTOs/Interfaces between Backend and Frontend to prevent contract drift. Currently, `User` interface likely exists in both projects manually.

---

## 3. High-Level Data Flow

```mermaid
graph TD
    subgraph Mobile[Flutter Mobile App]
        M_UI[UI / Screens] --> M_Riverpod[Riverpod Providers]
        M_Riverpod --> M_Repo[Repositories]
        M_Repo --> M_API[API Client (Dio)]
        M_Repo --> M_Socket[Socket Service]
    end

    subgraph Web[React Web Dashboard]
        W_UI[React Components] --> W_Redux[Redux Slices]
        W_Redux --> W_API[Axios Client]
        W_Redux --> W_Socket[Socket Client]
    end

    subgraph Server[Node.js Backend]
        LoadBalancer --> API[Express API]
        LoadBalancer --> Socket[Socket.IO Server]
        API --> Controllers
        Controllers --> Services
        Services --> Database[(MongoDB)]
        Socket --> Redis[(Redis Adapter?)]
        Socket --> Database
    end

    M_API -- HTTPS --> API
    W_API -- HTTPS --> API
    M_Socket -- WSS --> Socket
    W_Socket -- WSS --> Socket
```

_Note: Redis is suggested for Socket.IO scaling (see Scalability section)._
