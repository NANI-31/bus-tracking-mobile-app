# Project Architecture

The College Bus Tracking System follows a modern client-server architecture with real-time capabilities.

## High-Level Architecture

```mermaid
graph TD
    subgraph Frontend [Flutter Mobile App]
        UI[User Interface]
        Provider[State Management - Provider]
        Services[API & Socket Services]
        Maps[Google Maps Integration]
    end

    subgraph Backend [Node.js/Express Server]
        Auth[Authentication Middleware]
        Controllers[Business Logic Controllers]
        Routes[API Routing]
        Sockets[Socket.io Real-time Engine]
    end

    subgraph Database [Storage & Cloud]
        Mongo[(MongoDB)]
        Firebase[Firebase Cloud Messaging]
    end

    UI <--> Provider
    Provider <--> Services
    Services <--> Routes
    Services <--> Sockets
    Routes <--> Controllers
    Controllers <--> Auth
    Controllers <--> Mongo
    Controllers <--> Firebase
    Sockets <--> Controllers
```

## Communication Flows

1.  **REST API (HTTP/Dio)**: Used for standard request-response actions such as user login, registration, and profile management.
2.  **WebSocket (Socket.io)**: Facilitates real-time bus location updates from driver to students/teachers.
3.  **Firebase Cloud Messaging (FCM)**: Handles push notifications for alerts, reminders, and updates.
4.  **Database (Mongoose)**: Manages persistent data including user profiles, bus routes, and schedules.
