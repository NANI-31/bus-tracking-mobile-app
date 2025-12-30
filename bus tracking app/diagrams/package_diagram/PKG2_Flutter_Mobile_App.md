# PKG2: Flutter Mobile App Packages

**Package Diagram ID:** PKG2  
**Module Group:** Flutter Mobile Application  
**Version:** 1.0  
**Date:** 2025-12-30

---

## 1. Purpose

This package diagram details the internal package structure of the Flutter mobile application, showing how different modules are organized and their interdependencies.

---

## 2. Packages / Modules

| Package   | Path             | Description                          |
| --------- | ---------------- | ------------------------------------ |
| screens   | `lib/screens/`   | UI screens organized by role         |
| services  | `lib/services/`  | Business logic and API communication |
| models    | `lib/models/`    | Data transfer objects                |
| providers | `lib/providers/` | State management                     |
| utils     | `lib/utils/`     | Helper functions and constants       |
| widgets   | `lib/widgets/`   | Reusable UI components               |
| l10n      | `lib/l10n/`      | Localization resources               |
| core      | `lib/core/`      | Theme, routes, config                |

---

## 3. Mermaid Diagram

```mermaid
flowchart TB
    subgraph FlutterApp["lib/"]
        subgraph Presentation["Presentation Layer"]
            screens["screens/"]
            widgets["widgets/"]
        end

        subgraph RoleScreens["screens/ by Role"]
            auth["auth/"]
            student["student/"]
            teacher["teacher/"]
            driver["driver/"]
            coordinator["coordinator/"]
            admin["admin/"]
            common["common/"]
        end

        subgraph BusinessLogic["Business Logic Layer"]
            services["services/"]
            providers["providers/"]
        end

        subgraph ServiceModules["services/"]
            api_service["api_service.dart"]
            auth_service["auth_service.dart"]
            socket_service["socket_service.dart"]
            location_service["location_service.dart"]
            firebase_service["firebase_service.dart"]
        end

        subgraph DataLayer["Data Layer"]
            models["models/"]
        end

        subgraph Core["Core / Config"]
            core["core/"]
            utils["utils/"]
            l10n["l10n/"]
        end
    end

    screens --> RoleScreens
    screens --> widgets
    screens --> providers

    RoleScreens --> services
    providers --> services

    services --> ServiceModules
    services --> models

    screens --> core
    screens --> utils
    screens --> l10n
```

---

## 4. Dependencies

| Source Package | Target Package | Dependency Type |
| -------------- | -------------- | --------------- |
| screens        | providers      | State Access    |
| screens        | widgets        | UI Components   |
| providers      | services       | API Calls       |
| services       | models         | Data Mapping    |
| screens        | l10n           | Localization    |
| services       | core           | Configuration   |

---

## 5. Actors / Roles

| Package      | Interacting Roles           |
| ------------ | --------------------------- |
| auth/        | All roles (login, register) |
| student/     | Students, Parents           |
| teacher/     | Teachers                    |
| driver/      | Drivers                     |
| coordinator/ | Bus Coordinators            |
| admin/       | System Administrators       |

---

## 6. Notes / Considerations

- **Role-Based Organization:** Screens are organized by user role for clarity.
- **Service Abstraction:** All API calls go through service layer.
- **Localization:** Supports English, Hindi, and Telugu.
- **State Management:** Uses Provider pattern for reactive state.
