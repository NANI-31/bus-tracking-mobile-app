# Package Architecture Analysis

This document describes the architectural decisions for the package structure of the College Bus Tracking System.

## Flutter Frontend Architecture

The frontend is structured to ensure separation of concerns and reusability.

| Package    | Responsibility                                            | Dependencies                             |
| ---------- | --------------------------------------------------------- | ---------------------------------------- |
| `auth`     | Manages authentication state and flows (Login, Register). | `services`, `models`                     |
| `models`   | Defines data structures used across the app.              | None                                     |
| `screens`  | Contains the UI views for different user roles.           | `models`, `services`, `widgets`, `utils` |
| `services` | Handles all external communication (API, Socket, FCM).    | `models`, External APIs                  |
| `widgets`  | shared UI components to ensure design consistency.        | None                                     |
| `utils`    | Helper functions, constants, and permission handlers.     | None                                     |
| `l10n`     | Localization files for multi-language support.            | None                                     |

## Backend Server Architecture

The backend follows a standard layered architecture for Node.js/Express applications.

| Package       | Responsibility                                          | Dependencies                   |
| ------------- | ------------------------------------------------------- | ------------------------------ |
| `config`      | Centralized configuration for DB and external services. | None                           |
| `constants`   | Global constants to prevent magic strings/numbers.      | None                           |
| `models`      | Mongoose schemas representing the data layer.           | MongoDB                        |
| `controllers` | Business logic implementation.                          | `models`, `utils`, `constants` |
| `routes`      | API endpoint definitions mapping to controllers.        | `controllers`                  |
| `utils`       | functional utilities like JWT signing and hashing.      | None                           |
| `seeds`       | Scripts to populate the database with initial data.     | `models`                       |
| `index`       | Entry point bootstrapping the application.              | All packages                   |

## External Dependencies

- **MongoDB**: Primary data store for the backend.
- **Firebase FCM**: Used for sending push notifications to mobile devices.
- **Google Maps**: Visualizing bus locations on the mobile app.
- **Socket.IO**: Enabling real-time bidirectional communication for location updates.
