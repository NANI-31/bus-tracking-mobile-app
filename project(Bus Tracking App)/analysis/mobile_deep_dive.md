# Mobile Deep Dive

-> rule 6 is executed

## Framework: Flutter

The mobile app is the primary interface for Drivers and Students.

## State Management: Riverpod (AsyncNotifier)

- Heavy use of reactive providers to manage live tracking state, auth, and notifications.
- Encourages a clean, testable codebase.

## Feature Modularity (`lib/features/`)

The app is extremely granular, with features for:

- **`driver`**: Location broadcasting, SOS triggers.
- **`student`**: Live maps, arrival notifications, payment.
- **`coordinator`**: Monitoring SOS alerts and bus statuses.
- **`super_admin`**: Global overview.

## Real-time & Maps

- **Socket.IO Client**: Maintains a persistent connection for location streaming.
- **Google Maps**: Visualizes live bus movement with custom markers and routes.
- **FCM**: Firebase Cloud Messaging for critical alerts (SOS, nearby arrival).

## Localization (`lib/l10n/`)

- Comprehensive support for English, Hindi, and Telugu, enabling wider accessibility.
