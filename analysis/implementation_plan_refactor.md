# implementation_plan_refactor.md

# [Refactor] Mobile App to Feature-First Architecture

The current "Layer-by-Type" structure (`screens`, `providers`, `repos`) is hard to maintain. We will migrate to a "Feature-First" structure (`features/auth`, `features/student`) to group related code.

## User Review Required

> [!WARNING]
> This is a massive refactor that moves almost every file in `lib/`. It will break imports temporarily. I will fix them feature-by-feature.
> **Please do not edit files during this process.**

## Proposed Structure

We will create `lib/features/` and move code into these logical groups:

### 1. Auth (`lib/features/auth/`)

- **Screens**: Login, Register, Forgot Password
- **Data**: `AuthRepository`, `AuthService`
- **State**: `AuthProvider`

### 2. Core (`lib/core/`)

- **Services**: `ApiService`, `SocketService`, `PersistenceService`, `PermissionService`
- **Utils**: `AppLogger`, Constants, Theme
- **Widgets**: Shared/Common Widgets used globally

### 3. Bus (`lib/features/bus/`)

- **Data**: `BusRepository`
- **State**: `BusProvider`
- **Domain**: Bus-related logic

### 4. User (`lib/features/user/`)

- **Data**: `UserRepository`
- **State**: `UserProvider`

### 5. Personas (Screens & Feature-Specific Logic)

- **Student**: `lib/features/student/`
- **Driver**: `lib/features/driver/`
- **Coordinator**: `lib/features/coordinator/`
- **College Admin**: `lib/features/admin/college/`
- **Super Admin**: `lib/features/admin/super/`

## Migration Steps

### Step 1: Create Directories

Create the new folder structure.

### Step 2: Migrate Core & Shared

Move utility services, constants, and common widgets to `lib/core`.
Update imports for these (high impact).

### Step 3: Migrate Auth (Priority)

Move Auth screens, repos, and providers.
Fix imports in `main.dart` and `router.dart`.

### Step 4: Migrate Domain Features (Bus, User, College)

Move Repositories and Providers that are shared across personas.

### Step 5: Migrate Persona Screens

Move `screens/student` -> `features/student/screens`, etc.

### Step 6: Cleanup

Remove empty old directories (`lib/screens`, `lib/providers`, etc.).

## Verification Plan

1.  **Analyze**: Run `flutter analyze` after each step to catch broken imports.
2.  **Run**: Launch app to verify `main.dart` and routing still work.
3.  **Test**: Verify Login flow (Auth) and Dashboard load (Data).
