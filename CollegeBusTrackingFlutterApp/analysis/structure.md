# Directory Structure Analysis

## 1. Flutter Frontend (`/CollegeBusTrackingFlutterApp`)

- `lib/`: Main source code.
  - `auth/`: Authentication related screens and logic (e.g., `reset_password_screen.dart`).
  - `l10n/`: Localization files (arb).
  - `models/`: Data models (Student, Teacher, Driver, Bus, etc.).
  - `screens/`: UI screens organized by role or feature (Student Dashboard, Driver Map, etc.).
  - `services/`: API services, Socket services, and Firebase integration logic.
  - `utils/`: Common utilities, constants, and helpers.
  - `widgets/`: Reusable UI components.
  - `main.dart`: App entry point and configuration.
- `assets/`:
  - `images/`: Static images and icons.
  - `map_styles/`: JSON files for Google Maps styling.
- `android/`, `ios/`, etc.: Platform-specific configuration files.

## 2. Node.js Backend (`/server`)

- `src/`: Main source code.
  - `config/`: Configuration files (Database, Firebase).
  - `constants/`: Global constants and enums.
  - `controllers/`: Business logic for various endpoints (Auth, User, Bus, etc.).
  - `models/`: Mongoose schemas and models.
  - `routes/`: Express route definitions.
  - `seeds/`: Database seeding scripts for initial data.
  - `utils/`: Helper functions and utility classes.
  - `index.ts`: Server entry point and setup.
- `tests/`: Unit and integration tests.
- `public/`: Static files if any.
- `.env`: Environment variables (Database URI, Secrets, etc.).
- `tsconfig.json`: TypeScript configuration.
