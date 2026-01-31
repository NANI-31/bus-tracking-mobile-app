# Mobile App Architecture Review (Flutter)

## Overview

The Flutter app uses strict type safety and modern state management (Riverpod 2.6). It targets three distinct user personas (Student, Driver, Admin) within a single codebase.

## 1. State Management (Riverpod)

### Strengths

- **Provider Structure**: Use of `AsyncNotifier` (`AuthNotifier`, `BusService` as notifier) allows for robust loading/error states handling.
- **Dependecy Injection**: Riverpod handles DI for Repositories and Services cleanely.
- **Refactoring**: Recent migration from `ChangeNotifier` to `AsyncNotifier` has modernized the app significantly.

### Weaknesses

- **Service Lifetime**: Some providers (like the old `SocketService`) were causing rebuild loops because they were watched reactively (`ref.watch`) instead of read once (`ref.read`). This was fixed during debugging but indicates a need for careful `ref.listen` vs `ref.watch` usage.

---

## 2. Navigation & Routing

- **GoRouter**: Used for declarative routing.
- **Guards**: Redirect logic in `router.dart` handles auth state changes well.
- **Deep Linking**: GoRouter supports this out of the box, useful for "Share Ride" features.

---

## 3. Code Organization

### "Layer-by-Type" vs "Feature-First"

Currently, the app uses a mixed approach:

- `lib/screens/student/...`
- `lib/providers/...`
- `lib/repositories/...`

**Problem**: To change the "Bus Detail" feature, you touch 4 folders (`screens`, `providers`, `repos`, `models`).
**Recommendation**: Move to **Feature-First**.

```text
lib/features/bus_tracking/
  ├── presentation/
  │   ├── screens/
  │   └── widgets/
  ├── application/ (Providers/Notifiers)
  ├── domain/ (Models)
  └── data/ (Repositories/API)
```

This is the "Riverpod Recommended Architecture" (similar to Clean Architecture) and scales much better.

---

## 4. UI/UX & Theming

- **Theming**: `AppTheme` handles light/dark modes.
- **Responsiveness**: ensure `LayoutBuilder` is used if the app runs on Tablets.
- **Maps**: Google Maps implementation handles markers and polylines. Ensure strict memory management (dispose controllers) to prevent crashes on long sessions.

---

## 5. Performance

- **Rebuilds**: `ref.watch` is powerful but dangerous. Use `select` (e.g., `ref.watch(userProvider.select((u) => u.name))`) to avoid rebuilding a widget when unrelated data (e.g., `u.lastLogin`) changes.
- **List Views**: Ensure `ListView.builder` is used for long lists (Students, Logs).
- **Image Caching**: Use `cached_network_image` (already in pubspec) for all profile/bus photos.
