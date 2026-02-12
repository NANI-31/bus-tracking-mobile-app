# College Bus Tracking - Technical Architecture

-> rule 7 is executed

## System Overview

The College Bus Tracking system is a real-time monitoring platform for college transportation. It consists of a Node.js/TypeScript backend and a Flutter mobile application.

## Backend Architecture (Server)

The server is built with **Express.js** and **TypeScript**, using **MongoDB** as the primary database.

### Core Components

- **Real-time Tracking**: Uses **Socket.io** with a **Redis Adapter** for scalable real-time communication.
- **Location Buffering**: Implements a write-behind buffer to aggregate vehicle location updates in memory, flushing to MongoDB periodically (every 10s) to reduce database write load.
- **Authentication**: JWT-based authentication with role-specific login rules (e.g., Students/Teachers restricted to email login).
- **Caching**: **Redis** and **LRU Cache** are used to cache bus metadata and frequent API responses.
- **Notifications**: Integrated with **Firebase Admin SDK** for push notifications.

### Data Models

- **User**: High-flexibility schema supporting Students, Teachers, Drivers, Parents, and Admins. Includes GeoJSON support for bus stop locations.
- **Bus**: Tracks bus assignments, routes, and live location status.
- **BusLocation**: Historical and live location data with optimized indexing.

---

## Mobile Architecture (Flutter)

The mobile app is built using **Flutter** with a focus on Clean Architecture and modularity.

### Core Technologies

- **State Management**: **Riverpod** (AsyncNotifier) for robust, reactive state handling.
- **Navigation**: **GoRouter** for declarative routing.
- **Networking**: **Dio** with interceptors for auth token management and global error handling.
- **Real-time**: **Socket.io Client** with persistent connection management and offline event queuing.
- **Maps**: **Google Maps Flutter** for real-time vehicle visualization.

### Feature Modularity

The `lib/features` directory contains self-contained modules for:

- Authentication & User Profile
- Live Bus Tracking
- Route Management
- Notifications (FCM)
- SOS/Emergency Alerts
- Payment Integration (Razorpay)

---

## Key Features

1. **Live Tracking**: Smooth, real-time bus movement on the map.
2. **SOS System**: Drivers can trigger emergency alerts that are broadcast to coordinators in real-time.
3. **Nearby Notifications**: Automatic alerts when a bus is approaching a student's stop.
4. **Multilingual Support**: Supports English, Hindi, and Telugu.
