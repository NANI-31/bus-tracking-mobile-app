# Module Overview

## Frontend Modules

1.  **Authentication Module**: Handles user login, registration, and password recovery. Supports multiple roles (Student, Teacher, Driver).
2.  **Real-time Tracking Module**: Integrates Google Maps with Socket.io to display live bus locations and move markers in real-time.
3.  **Notification Module**: Manages push notifications using Firebase Cloud Messaging, ensuring users are alerted of bus arrivals or schedule changes.
4.  **Dashboard Module**: Role-specific dashboards providing relevant information (e.g., Student sees their bus, Driver sees their route).
5.  **Localization Module**: Multi-language support using `intl` and `l10n`.

## Backend Modules

1.  **API Gateway**: Built with Express.js to route incoming HTTP requests to appropriate controllers.
2.  **Authentication & Authorization**: Uses JWT for session management and middleware to protect routes based on user roles.
3.  **Real-time Logic Hub**: Socket.io server logic that manages rooms (e.g., per bus route) and broadcasts location updates.
4.  **Data Access Layer**: Mongoose models that interface with MongoDB for storing user and bus data.
5.  **Messaging Service**: Integrates with Firebase Admin SDK to send system-triggered notifications.
