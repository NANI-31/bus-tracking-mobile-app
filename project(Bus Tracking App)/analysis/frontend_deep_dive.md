# Frontend Deep Dive

-> rule 6 is executed

## Technology: React 19 + Vite

The web client is built on the latest React version, ensuring high performance and modern features.

## State Management: Redux Toolkit

- Centralized state for authentication, college data, and system-wide settings.
- RTK Query is likely used for API interactions (to be verified).

## Feature Structure (`client/src/features/`)

The frontend is split into clear administrative contexts:

- **`college-admin`**: Management of buses, routes, users, and live tracking for a specific institution.
- **`super-admin`**: Global system monitoring, college management, and audit logs.
- **`auth`**: Modular login/registration flows with role-based redirection.

## Styling: Tailwind CSS v4

- High-efficiency utility-first styling.
- Custom theme defined in `src/theme.js`.

## Real-time Integration

- Uses Socket.IO client to sync with the backend for live bus movement and dashboard updates (e.g., `user_list_updated`, `bus_list_updated`).
