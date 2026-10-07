# Comprehensive Errors & Corrections Report

This document specifies all critical architectural flaws, session/token management bugs, and tracking lifecycle errors identified in the **Mobile (Flutter)** and **Server (Node.js)** codebases, along with exact code-level corrections.

---

## 1. Authentication, Token Expiry & Session Management Errors

### ✅ Error 1: Socket.IO Auth Failure Bypasses Silent Token Refresh [RESOLVED]
* **Severity**: Critical (Resolved)
* **Status**: ✅ **Implemented & Verified**
* **Files Modified**:
  * [`mobile/lib/core/services/socket_service.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/core/services/socket_service.dart)
  * [`mobile/lib/core/providers/socket_provider.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/core/providers/socket_provider.dart)
  * [`mobile/lib/features/auth/application/auth_provider.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/features/auth/application/auth_provider.dart)
* **Root Cause**:
  When an access token expires (after 2 hours) and the WebSocket connection reconnects (e.g. network transition or app resume), the server rejects the handshake with `Authentication error: Invalid token`.
  `SocketService.onConnectError` previously caught this and immediately executed `updateAuth(null)` and `onSessionExpired?.call()`, popping `SessionExpiryDialog` and forcing logout while ignoring the 7-day refresh token.
* **Resolution**:
  1. Added `SocketService.onTokenRefreshRequired` callback and `_isRefreshingToken` lock flag in `SocketService`.
  2. Implemented `refreshToken()` on `AuthNotifier` to request a new access token via `/auth/refresh-token` using the persisted refresh token.
  3. When `onConnectError` catches an auth failure, it invokes `onTokenRefreshRequired!()`. If refreshed successfully, it seamlessly reconnects the socket with the new token via `updateAuth(newToken)`.
  4. Only falls back to `_handlePermanentSessionExpiry()` if the refresh token is also invalid or expired.

---

### ✅ Error 2: Silent HTTP Token Refresh Fails to Propagate to Riverpod & Socket [RESOLVED]
* **Severity**: Critical (Resolved)
* **Status**: ✅ **Implemented & Verified**
* **Files Modified**:
  * [`mobile/lib/core/data/base_repository.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/core/data/base_repository.dart)
  * [`mobile/lib/features/auth/application/auth_provider.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/features/auth/application/auth_provider.dart)
* **Root Cause**:
  When Dio caught a 401 error and called `/auth/refresh-token`, it updated `PersistenceService.setAuthToken(newToken)` and retried the HTTP request. However, it did not update `AuthState.token` inside Riverpod's `authProvider`. Because `SocketService` observes `authProvider.select((s) => s.value?.token)`, the WebSocket client kept holding the old expired JWT.
* **Resolution**:
  1. Added `BaseRepository.onTokenRefreshed` callback invoked immediately when Dio successfully refreshes a token.
  2. Implemented `updateToken(String newToken)` on `AuthNotifier` to update `AuthState(token: newToken)`.
  3. Bound `BaseRepository.onTokenRefreshed = updateToken` in `AuthNotifier.build()`.
  4. Now, any silent HTTP token refresh instantly propagates to Riverpod and dynamically updates `SocketService.updateAuth(newToken)`.

---

### ✅ Error 3: Concurrent HTTP 401 Race Condition [RESOLVED]
* **Severity**: High (Resolved)
* **Status**: ✅ **Implemented & Verified**
* **Files Modified**:
  * [`mobile/lib/core/data/base_repository.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/core/data/base_repository.dart)
* **Root Cause**:
  When multiple HTTP requests failed concurrently with 401 (e.g. loading routes, schedule, and student profile simultaneously on startup or token expiration), each request independently fired a duplicate `POST /auth/refresh-token` call. This caused server stampedes, race conditions on token storage, and premature user logouts if one of the redundant requests failed.
* **Resolution**:
  1. Added a shared static `Completer<String?>? _refreshCompleter` mutex lock in `BaseRepository`.
  2. Implemented pre-flight token check: If a request receives a 401 but the persisted token is already newer than the request's Authorization header, it retries immediately without firing a refresh.
  3. If another refresh is already in progress (`_refreshCompleter != null`), incoming 401 requests await `_refreshCompleter!.future` rather than firing duplicate requests.
  4. The first 401 request acquires the lock, executes a single `/auth/refresh-token` call, resolves the Completer with the new token to unlock all awaiting requests, and safely clears `_refreshCompleter` in a `finally` block.

---

### ✅ Error 4: Server Logout Fails to Terminate Active WebSockets [RESOLVED]
* **Severity**: High (Resolved)
* **Status**: ✅ **Implemented & Verified**
* **Files Modified**:
  * [`server/src/socket/index.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/socket/index.ts)
  * [`server/src/controllers/auth/logout.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/controllers/auth/logout.ts)
  * [`mobile/lib/core/services/socket_service.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/core/services/socket_service.dart)
* **Root Cause**:
  When a user logged out via `POST /api/v1/auth/logout`, the server updated MongoDB (`isLoggedIn: false`, `tokenVersion += 1`), but did not disconnect the user's active WebSocket connection in Socket.IO. Secondary devices or ghost browser sessions remained connected, receiving live bus coordinates, student SOS alerts, and college broadcasts.
* **Resolution**:
  1. Implemented `disconnectUserSockets(userId)` in `server/src/socket/index.ts`. It emits a `session_terminated` event to the user's room (`user.id`) and calls `io.in(userRoom).disconnectSockets(true)` (with an in-memory socket fallback).
  2. Integrated `disconnectUserSockets(userId)` into `logout` controller in `server/src/controllers/auth/logout.ts`.
  3. Added client-side listener for `session_terminated` event in `SocketService` (`mobile/lib/core/services/socket_service.dart`), which invokes `_handlePermanentSessionExpiry()` and prompts the user to re-authenticate without reconnection loops.

---

### ✅ Error 5: Socket.IO Handshake Does Not Check `tokenVersion` [RESOLVED]
* **Severity**: Medium (Resolved)
* **Status**: ✅ **Implemented & Verified**
* **Files Modified**:
  * [`server/src/utils/socketAuth.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/utils/socketAuth.ts)
* **Root Cause**:
  While `authMiddleware.ts` queried MongoDB on every HTTP request to verify `decoded.tokenVersion === user.tokenVersion`, `socketAuth.ts` previously only verified the cryptographic JWT signature. As a result, invalidated sessions (from logins on newer devices or remote logouts) were allowed to reconnect to Socket.IO and stream live tracking data as long as the 2-hour JWT had not expired.
* **Resolution**:
  1. Updated `authenticateSocket` in `server/src/utils/socketAuth.ts` to be asynchronous.
  2. Queried `User.findById(decoded.id).select('tokenVersion approved isLoggedIn')`.
  3. Validated that `decoded.tokenVersion === user.tokenVersion`, rejecting outdated handshakes with `Authentication error: Session expired`.
  4. Integrated forensic audit logging via `logSessionExpiry` with `SessionExpiryReason.TokenVersionMismatch` and `SessionExpiryReason.UserDeleted`.

---

### ✅ Error 6: JWT Lifespan Discrepancy Between Docs and Code [RESOLVED]
* **Severity**: Low (Resolved)
* **Status**: ✅ **Implemented & Verified**
* **Files Modified**:
  * [`server/src/controllers/auth/login.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/controllers/auth/login.ts)
  * [`server/src/controllers/auth/refresh.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/controllers/auth/refresh.ts)
  * [`server/src/controllers/auth/register.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/controllers/auth/register.ts)
* **Root Cause**:
  Inline comments previously claimed `"Access Token (Short-lived: 15 minutes)"` while the hardcoded parameter was `{ expiresIn: "2h" }`. The lifespan was not configurable via environment variables, leading to configuration confusion and inability to tune session lengths per deployment.
* **Resolution**:
  1. Updated `login.ts`, `refresh.ts`, and `register.ts` to dynamically source expiration from `process.env.ACCESS_TOKEN_EXPIRY || "2h"` for access tokens and `process.env.REFRESH_TOKEN_EXPIRY || "7d"` for refresh tokens.
  2. Aligned all docstrings and inline comments to accurately describe configurable token lifespans.

---

## 2. Live Tracking, Override & Driver Session Errors

### ✅ Error 7: Permanent Lock on Unhandled Teacher/Driver Override (Ghost Sessions) [RESOLVED]
* **Severity**: Critical (Resolved)
* **Status**: ✅ **Implemented & Verified**
* **Files Modified**:
  * [`server/src/models/Bus.model.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/models/Bus.model.ts)
  * [`server/src/services/teacherOverrideService.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/services/teacherOverrideService.ts)
  * [`server/src/cron/trackingCleanup.cron.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/cron/trackingCleanup.cron.ts)
  * [`server/src/index.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/index.ts)
  * [`server/src/socket/handlers/location.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/socket/handlers/location.ts)
  * [`server/src/socket/handlers/disconnect.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/socket/handlers/disconnect.ts)
  * [`server/src/controllers/transport/teacherOverride.controller.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/controllers/transport/teacherOverride.controller.ts)
  * [`mobile/lib/core/services/socket_service.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/core/services/socket_service.dart)
  * [`mobile/lib/features/teacher/presentation/teacher_dashboard.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/features/teacher/presentation/teacher_dashboard.dart)
* **Root Cause**:
  When a teacher initiates a location override on a bus, `bus.trackingTeacherId` is stored in MongoDB. If the teacher's phone runs out of battery, the app crashes, or the OS kills the process in the background, the override was never cancelled. The bus was left permanently locked in `accepted` override state, preventing the assigned driver from starting trips and displaying a frozen or stale bus on student and coordinator maps.
* **Resolution**:
  1. **Schema & Indexing**: Added `lastTrackingHeartbeat?: Date;` to `IBus` and `BusSchema` in `server/src/models/Bus.model.ts`, indexed via `{ trackingTeacherId: 1, lastTrackingHeartbeat: 1 }`.
  2. **Centralized Release Service**: Implemented `releaseTeacherOverride(busId, reason)` in `server/src/services/teacherOverrideService.ts` which safely clears `trackingTeacherId`, resets `driverId = ""`, sets `assignmentStatus = "unassigned"` and `status = "not-running"`, invalidates Redis caches (`buses:all`, `buses:${collegeId}`), updates `TeacherOverrideRequest` records to `"ended"`, resets GPS outlier guard anchor via `clearLastKnownPosition(busId)`, and broadcasts `bus_list_updated`, `bus_updated`, and `location_override_ended` socket events.
  3. **Automated Server TTL Cleaner**: Created `server/src/cron/trackingCleanup.cron.ts` running every 30 seconds to automatically query and release any bus with an active override whose `lastTrackingHeartbeat` is older than 2 minutes (120,000 ms), registered in `server/src/index.ts`.
  4. **Socket Handshake & Disconnect Grace**:
     - In `server/src/socket/handlers/location.ts`, added `tracking_heartbeat` and `end_location_override` socket listeners, and updated `handleLocationUpdate` to refresh `lastTrackingHeartbeat`.
     - In `server/src/socket/handlers/disconnect.ts`, added teacher disconnect detection: after a 30-second reconnect grace period, automatically invokes `releaseTeacherOverride` if the teacher has not reconnected.
  5. **Mobile Periodic Heartbeat**:
     - Added `emitTrackingHeartbeat` in `mobile/lib/core/services/socket_service.dart`.
     - Integrated a 30-second periodic heartbeat timer in `mobile/lib/features/teacher/presentation/teacher_dashboard.dart` active during live tracking, properly disposed on cancel or unmount.

---

### ✅ Error 8: Concurrent Location Emission Conflicts [RESOLVED]
* **Severity**: High (Resolved)
* **Status**: ✅ **Implemented & Verified**
* **Files Modified**:
  * [`server/src/socket/handlers/location.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/socket/handlers/location.ts)
  * [`server/src/controllers/transport/teacherOverride.controller.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/controllers/transport/teacherOverride.controller.ts)
  * [`server/src/services/BusService.ts`](file:///d:/Data/GitHub/bus-tracking-mobile-app/server/src/services/BusService.ts)
* **Root Cause**:
  There was no server-side concurrency check preventing a driver and an overriding teacher from emitting `update_location` simultaneously for the same `busId`. If a driver continued driving or had an active background location service after an override was approved, the server accepted and broadcasted packets from both actors, causing the bus marker on student and coordinator maps to oscillate violently between two different geographic locations. Additionally, the server never broadcasted `location_override_approved` upon approving a teacher override request, preventing the driver dashboard from automatically pausing location sharing.
* **Resolution**:
  1. **Server-Side Concurrency Guard (Socket)**: In `server/src/socket/handlers/location.ts`, added a strict actor validation and lock check on `update_location`:
     - If `user.role === 'driver'` and `bus.trackingTeacherId` is set, the packet is immediately rejected and discarded before GPS outlier checks, throttle buffer, and broadcast.
     - Specifically emits `location_override_approved` to the driver's socket so the driver app immediately pauses background location tracking.
     - Verifies driver assignment (`bus.driverId === user.id`) and assignment status (`bus.assignmentStatus === 'accepted'`).
     - In `tracking_heartbeat`, verifies that heartbeats from drivers are ignored if a teacher override is active, and teacher heartbeats are verified against `bus.trackingTeacherId`.
  2. **Approval Broadcast**: In `server/src/controllers/transport/teacherOverride.controller.ts`, added emission of `location_override_approved` with `{ busId, teacherId }` across the college room when an override request is approved, triggering the driver client's native `_handleOverrideActivated` pause handler.
  3. **REST Fallback Concurrency Guard**: In `server/src/services/BusService.ts`, updated `updateBusLocation` to check `bus.trackingTeacherId` and abort broadcasting if a teacher override is active, closing the REST fallback loophole.

---

### ✅ Error 9: Raw GPS Jitter Emitted Without Smoothing [RESOLVED]
* **Severity**: Medium (Resolved)
* **Status**: ✅ **Implemented & Verified**
* **Files Modified / Created**:
  * [`mobile/lib/core/utils/gps_kalman_filter.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/core/utils/gps_kalman_filter.dart)
  * [`mobile/lib/features/bus/services/location_service.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/features/bus/services/location_service.dart)
  * [`mobile/lib/features/driver/presentation/driver_dashboard.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/features/driver/presentation/driver_dashboard.dart)
  * [`mobile/lib/features/teacher/presentation/teacher_dashboard.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/features/teacher/presentation/teacher_dashboard.dart)
* **Root Cause**:
  Raw geolocator positions were emitted directly over the socket stream without Kalman filtering, speed gates, or distance thresholds. Stationary GPS chips fluctuate between 0.1 and 0.8 m/s due to satellite geometry and multipath reflection, drifting up to 15-20 meters and causing chaotic bearing spins (0° to 359°). This jitter was broadcast continuously to the server and all students, triggering false route deviation warnings and erratic map marker wiggling at stops and intersections.
* **Resolution**:
  1. **1D Kalman Filtering & Spatial Modeling**: Created `GpsKalmanFilter` in `mobile/lib/core/utils/gps_kalman_filter.dart` that models latitude and longitude independently with dynamic measurement variance based on reported GPS accuracy (`position.accuracy`), smooths raw coordinate fixes, and damps process noise when stationary.
  2. **Speed Gate & Heading Stabilization**: Clamped spurious stationary speeds (< 0.8 m/s ~ 2.9 km/h) to `0.0 m/s` and preserved the last known valid heading when stationary, preventing map compass markers from spinning wildly at red lights or bus stops.
  3. **Emission Delta Threshold & Keepalive Gate**: Implemented `shouldEmitLocationUpdate` in `LocationService` that only broadcasts socket packets if:
     - The bus moved $\ge 5.0$ meters, OR
     - The bus changed heading by $\ge 15.0^\circ$ while moving ($\ge 0.8$ m/s), OR
     - The bus is moving ($\ge 1.0$ m/s and $\ge 3.0$ meters), OR
     - The stationary keepalive interval ($\ge 15$ seconds) has elapsed to keep session state fresh on the server.
  4. **Integrated Across Broadcasters**: Integrated the smoothed positions and emission gating across both `DriverDashboard` and `TeacherDashboard`. Local map markers, route deviation detection, and stop arrival proximity now all consume the clean, Kalman-filtered stream.

---

### ✅ Error 10: OS Background Process Termination During Live Trips [RESOLVED]
* **Severity**: High (Resolved)
* **Status**: ✅ **Implemented & Verified**
* **Files Modified / Created**:
  * [`mobile/pubspec.yaml`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/pubspec.yaml)
  * [`mobile/android/app/src/main/AndroidManifest.xml`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/android/app/src/main/AndroidManifest.xml#L50-L65)
  * [`mobile/lib/core/services/background_tracking_service.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/core/services/background_tracking_service.dart)
  * [`mobile/lib/core/services/location_service.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/core/services/location_service.dart)
  * [`mobile/lib/features/bus/services/location_service.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/features/bus/services/location_service.dart)
  * [`mobile/lib/main.dart`](file:///d:/Data/GitHub/bus-tracking-mobile-app/mobile/lib/main.dart)
* **Root Cause**:
  Driver and teacher location tracking previously relied on standard in-app Geolocator listeners. When drivers navigated to other apps (e.g. Google Maps, phone dialer) or the device screen timed out, Android Doze mode and App Standby buckets, along with iOS background execution limits, suspended CPU and socket execution within 1–3 minutes, silently terminating live location streaming mid-trip.
* **Resolution**:
  1. **Foreground Service Integration (`flutter_background_service`)**:
     - Added `flutter_background_service: ^5.1.0` dependency.
     - Implemented `BackgroundTrackingService` in `mobile/lib/core/services/background_tracking_service.dart` featuring a dedicated background isolate with an Android Foreground Service notification channel (`bus_tracking_foreground_service`).
     - Persistent sticky notification displays: `"Upasthit Bus Tracking is Active"` with `"Sharing live location with students and coordinators"`, keeping the process in the OS foreground priority group and holding wake locks.
  2. **Android Manifest Declaration & Permissions**:
     - Updated `mobile/android/app/src/main/AndroidManifest.xml` to declare `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED`.
     - Explicitly registered `id.flutter.flutter_background_service.BackgroundService` with `android:foregroundServiceType="location"` conforming to Android 14+ (API 34) Foreground Service policies.
  3. **Tracking Lifecycle Coordination**:
     - In `LocationService.startLocationTracking`, automatically starts `BackgroundTrackingService` alongside the Fused Location Provider stream, reinforcing `AndroidSettings(foregroundNotificationConfig: ...)`.
     - In `LocationService.stopLocationTracking`, automatically stops `BackgroundTrackingService` and clears the foreground notification.
  4. **App Initialization**:
     - Configured `BackgroundTrackingService.initialize()` in `_initBackgroundServices()` in `mobile/lib/main.dart`.
  5. **Core Re-Export Path**:
     - Created `mobile/lib/core/services/location_service.dart` re-exporting `LocationService` and `BackgroundTrackingService` for unified imports.

---

## 3. Implementation Priority Matrix

| Error ID | Description | Component | Severity | Effort |
|---|---|---|---|---|
| **Error 1** | Socket.IO Auth Failure Bypasses Silent Token Refresh | Mobile Client | ✅ Resolved | Done |
| **Error 2** | Silent HTTP Refresh Token Out of Sync with Riverpod / Socket | Mobile Client | ✅ Resolved | Done |
| **Error 7** | Ghost Session / Permanent Lock on Abrupt Override Disconnect | Server Backend | ✅ Resolved | Done |
| **Error 3** | Concurrent HTTP 401 Mutex Race Condition | Mobile Client | ✅ Resolved | Done |
| **Error 4** | Server Logout Fails to Terminate Active WebSockets | Server Backend | ✅ Resolved | Done |
| **Error 8** | Concurrent Driver & Teacher GPS Emission Conflicts | Server Backend | ✅ Resolved | Done |
| **Error 10**| Background Process Suspension (Foreground Service) | Mobile Client | ✅ Resolved | Done |
| **Error 5** | Socket.IO Handshake Does Not Validate `tokenVersion` | Server Backend | ✅ Resolved | Done |
| **Error 9** | Raw GPS Noise (Kalman Filter / Emission Delta Threshold) | Mobile Client | ✅ Resolved | Done |
| **Error 6** | JWT Expiration Comment Discrepancy | Server Backend | ✅ Resolved | Done |
