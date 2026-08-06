# AI Project Index — Upasthit Bus Tracking System

> **AI INSTRUCTION**: Read this file FIRST before touching any source files. Use it as your primary knowledge source. Only open source files when implementation details are needed. Update this document whenever architecture or structure changes.

---

## 1. Project Overview

**Upasthit** is a multi-tenant, real-time college bus tracking platform.
It consists of four tightly-coupled sub-applications:

| App | Stack | Purpose |
|-----|-------|---------|
| `mobile/` | Flutter + Riverpod | Student, Driver, Coordinator, Teacher, Admin mobile app |
| `client/` | React + Redux Toolkit + MUI | Web dashboard for Super Admin, College Admin, Coordinator |
| `server/` | Express.js + TypeScript + MongoDB + Socket.IO | REST API, real-time socket server, Firebase push notifications |
| `.agents/rules/` | Markdown | Development rules governing core logic changes |

**Core capabilities:**
- Real-time GPS bus tracking via Socket.IO (3 s server throttle, 60fps client animation)
- Role-based dashboards: Student, Driver, Coordinator, Teacher, College Admin, Super Admin
- Bus assignment lifecycle: Coordinator assigns → Driver accepts/rejects → Students track
- Route management with Google Maps Directions API (polylines cached in Route model)
- SOS emergency alerts (driver triggers, coordinator/admin receives via FCM + socket)
- Push notifications via Firebase Cloud Messaging (multilingual: en/hi/te)
- Subscription payments with Premium plans (daily cron expiry check)
- Teacher GPS override (substitute driver tracking)
- Multi-language UI (English, Telugu, Hindi)

---

## 2. Folder Structure

### `mobile/` — Flutter Application

```
mobile/lib/
├── main.dart                   # App entry: Firebase init, Maps renderer, FCM init, shader precompile
├── core/
│   ├── constants/              # AppSizes, AppTheme, API URLs, colors
│   ├── data/                   # Dio HTTP client, interceptors, base repository
│   ├── providers/              # Global Riverpod providers (service, repository, socket)
│   ├── router/router.dart      # GoRouter config, role-based redirect logic
│   ├── services/               # Core singletons: SocketService, DataService, PersistenceService
│   └── utils/                  # AppLogger, MapMarkerHelper, route_math_utils, ShaderPrecompiler
├── features/
│   ├── auth/                   # Login, Register, OTP, Forgot/Reset password screens
│   ├── student/                # StudentDashboard, bus tracking map, schedule, bus-stop screen
│   ├── driver/                 # DriverDashboard, live tracking tab, ETA, SOS
│   ├── coordinator/            # CoordinatorDashboard, bus assignment, route management
│   ├── teacher/                # TeacherDashboard, override tracking tab
│   ├── college_admin/          # CollegeAdminDashboard
│   ├── super_admin/            # SuperAdminDashboard, college management
│   ├── bus/                    # BusModel, BusProvider, BusRepository, LocationService
│   ├── route/                  # RouteModel, RouteService, RouteRepository
│   ├── notification/           # FCMService, NotificationService, NotificationsScreen
│   ├── payment/                # PaymentService, subscription screens
│   ├── sos/                    # SosModel, SosProvider, SOS alerts
│   ├── user/                   # UserModel, ProfileScreen, EditProfileScreen, ReferralScreen
│   ├── incident/               # IncidentService, incident reporting modal
│   ├── audit/                  # Audit log display
│   ├── settings/               # App settings screen
│   └── schedule/               # Schedule management screens
├── shared/
│   ├── screens/                # SplashScreen, PrivacyPolicy, TermsConditions
│   └── widgets/                # LiveBusMap, TripProgressSheet, SosButton, GlassMorphicContainer…
├── widgets/
│   └── common/                 # CommonMapView, bottom navigation, analytics widgets
└── l10n/                       # ARB localization files per feature (en, te, hi)
```

**Key feature structures:**

| Feature | Key Files |
|---------|----------|
| Driver | `driver_dashboard.dart` (ETA+deviation), `driver_live_tracking_tab.dart` (map+polyline), `live_tracking_control_panel.dart` |
| Student | `student_dashboard.dart`, `student_map_tab.dart` (uses LiveBusMap), `map_navigation_provider.dart` |
| Coordinator | `coordinator_dashboard.dart`, `driver_selection_screen.dart`, `edit_bus_screen.dart` |
| Teacher | `teacher_dashboard.dart`, `teacher_live_tracking_tab.dart` (active/passive map) |
| Bus | `bus_model.dart`, `bus_provider.dart` (`collegeBusesStreamProvider`, `driverBusProvider`) |

---

### `client/` — React Web Dashboard

```
client/src/
├── App.jsx                     # BrowserRouter, lazy loading, PrivateRoute wiring
├── main.jsx                    # React DOM entry, Redux store Provider
├── index.css                   # Global styles + glassmorphism utilities
├── theme.js                    # MUI dark theme
├── api/axios.js                # Axios instance with JWT Authorization interceptor
├── app/store.js                # Redux Toolkit store
├── pages/Login.jsx             # Shared login page for all web roles
├── components/
│   ├── PrivateRoute.jsx        # Role-based route guard (reads Redux auth state)
│   └── ErrorBoundary.jsx       # Global React error boundary
├── features/
│   ├── auth/                   # authSlice (login/logout/user state)
│   ├── super-admin/
│   │   ├── pages/              # SuperAdminDashboard, Colleges, CollegeDetails, GlobalUsers,
│   │   │                       # AuditLogs, GlobalPayments, GlobalTracking, AdvancedAnalytics,
│   │   │                       # SubscriptionPlans, SystemAnalysis
│   │   ├── api/                # Super admin API functions
│   │   ├── components/         # SA-specific reusable components
│   │   └── slices/             # Redux slices for SA state
│   ├── college-admin/
│   │   ├── pages/              # Dashboard, Users, Fleet, Routes, Payments, LiveTracking, Logs, RefundDashboard
│   │   ├── api/                # College admin API functions
│   │   ├── components/         # CA-specific components
│   │   └── slices/             # Redux slices for CA state
│   ├── coordinator/
│   │   └── pages/              # CoordinatorDashboard, CoordinatorLiveTracking, CoordinatorRoutes
│   └── common/                 # Shared feature modules
├── layouts/                    # CollegeAdminLayout, SuperAdminLayout, CoordinatorLayout
├── services/                   # External service integrations
└── utils/                      # Formatting + helper functions
```

---

### `server/` — Express.js API + Socket.IO

```
server/src/
├── index.ts                    # Entry: DB + Redis + Firebase init, cron jobs, listen
├── app.ts                      # Express + Socket.IO setup, security middleware, CORS, routes
├── config/
│   ├── db.ts                   # MongoDB connection (mongoose)
│   ├── redis.ts                # Redis connection (ioredis)
│   └── env.ts                  # Env variable validation at startup
├── models/                     # All Mongoose models (see Section 9)
├── routes/
│   ├── index.ts                # Master router: registers all sub-routers under /api/v1
│   ├── auth.routes.ts          # /api/v1/auth
│   ├── core/                   # user, college, places routes
│   ├── transport/              # bus, route, schedule, assignment, history routes
│   ├── features/               # notification, sos, incident, payment, plan routes
│   └── admin/                  # collegeAdmin, superAdmin, audit, systemConfig routes
├── controllers/                # Request/response handling per domain
├── services/
│   ├── busAssignmentService.ts # ALL assignment lifecycle logic + notifications
│   ├── busService.ts           # Bus CRUD and status management
│   ├── notificationService.ts  # Templated FCM push + Notification DB persistence
│   ├── DirectionsService.ts    # Google Maps Directions API (server-side caching)
│   ├── s3.service.ts           # AWS S3 file uploads (photos, voice messages)
│   ├── sosService.ts           # SOS creation, resolution, FCM broadcast
│   ├── AuditService.ts         # Audit log creation
│   ├── MetricsService.ts       # System metrics snapshots (cron-driven)
│   └── collegeService.ts       # College CRUD operations
├── middleware/
│   ├── authMiddleware.ts       # JWT protect, authorize(roles), premiumOnly, collegeAdminOnly
│   ├── errorMiddleware.ts      # Global error handler (standardizes error responses)
│   ├── requestIdMiddleware.ts  # Adds X-Request-ID UUID header per request
│   └── validate.ts             # Request schema validation middleware
├── socket/
│   ├── index.ts                # Socket.IO init, JWT auth middleware for sockets
│   ├── config.ts               # busCache (Map), rateLimiter (RateLimiterMemory)
│   ├── buffer.ts               # In-memory latest GPS position per bus
│   ├── types.ts                # ThrottledBroadcast type definition
│   └── handlers/
│       ├── location.ts         # update_location (outlier guard 500m, throttle 3s), stop_reached
│       ├── tracking.ts         # join_college, leave_college, start/stop_tracking events
│       ├── connection.ts       # On connect: JWT auth, join college room
│       ├── disconnect.ts       # On disconnect: cleanup, bus status update
│       ├── sos.ts              # SOS trigger/resolve via socket
│       └── updates.ts          # Manual bus_updated broadcasts
├── cron/
│   ├── payment.cron.ts         # Daily premium subscription expiry check
│   └── notification.cron.ts    # Scheduled notification delivery jobs
└── utils/
    ├── logger.ts               # Winston logger with Socket.IO log transport
    ├── firebase.ts             # Firebase Admin SDK init + FCM send helpers
    ├── buildNotification.ts    # Multilingual notification template builder (en/hi/te)
    ├── busNearbyLogic.ts       # Geospatial check: bus near student stop (2dsphere)
    └── socketAuth.ts           # JWT verification for Socket.IO handshake auth
```

---

### `.agents/rules/` — Development Rules

| File | Scope |
|------|-------|
| `AGENTS.md` | Always active — Git: never `git push` automatically; provide commit message only |
| `rules/Bus-logic.md` | Always active for bus/tracking/map tasks — assignment lifecycle, socket rules, map display, ETA/deviation, state persistence |

---

## 3. Architecture

### Flutter Architecture (mobile/)

Pattern: Feature-first + Riverpod + Repository Pattern

```
UI Widget (ConsumerWidget)
  → ref.watch(someProvider)
  → Service Layer  (BusService, RouteService, DataService)
  → Repository Layer (BusRepository, RouteRepository)
  → Dio HTTP Client → Express REST API
            ↕
  → SocketService (WebSocket) → Socket.IO Server (real-time)
```

- **State**: Riverpod (Provider, NotifierProvider, AsyncNotifierProvider, StreamProvider, FutureProvider)
- **Navigation**: GoRouter with role-based redirect in `routerProvider`
- **Persistence**: `PersistenceService` (SharedPreferences + route directions cache) + `SecureStorageService` (encrypted tokens)
- **Maps**: google_maps_flutter, AnimationController 60fps lerp, polyline trimming via `route_math_utils.dart`
- **Localization**: ARB-based per-feature (login, student, driver, coordinator, admin, notification, common)

### React Architecture (client/)

Pattern: Feature-first + Redux Toolkit + MUI

```
Page Component
  → useSelector / useDispatch (Redux)
  → Redux Thunk action or RTK Query
  → axios.js (JWT interceptor) → Express REST API
```

- **State**: Redux Toolkit slices per feature; no Context for domain state
- **Routing**: React Router v6 + lazy-loaded pages + PrivateRoute role guard
- **UI**: Material-UI v5 + glassmorphism CSS + @vis.gl/react-google-maps

### Express Architecture (server/)

Pattern: MVC + Service Layer

```
HTTP/WebSocket Client
  → Express Router (/api/v1/...)
  → protect (JWT verify + tokenVersion + premium check)
  → authorize(...roles)
  → Controller (req/res only)
  → Service Layer (all business logic)
  → Mongoose Model → MongoDB
         ↕ Firebase Admin (FCM push)
         ↕ Redis (rate limiting)
         ↕ Socket.IO (real-time broadcast)
```

Socket.IO Real-Time Flow:
```
Driver: socket.emit('update_location', {busId, collegeId, location})
  → Socket auth (JWT in handshake.auth.token)
  → location.ts: validate fields + outlier guard (haversine 500m)
  → throttle: max 1 broadcast per 3 seconds per busId
  → socket.to(collegeId).emit('location_updated', payload)
  → LiveBusMap._handleLocationUpdate() → animate marker
```

---

## 4. Important Files

| File | Purpose | Key Dependencies |
|------|---------|-----------------|
| `mobile/lib/main.dart` | App bootstrap (Firebase, Maps, FCM, shaders) | Firebase, GoRouter, Riverpod |
| `mobile/lib/core/router/router.dart` | GoRouter + role-based auth redirect | authProvider, UserRole |
| `mobile/lib/core/services/socket_service.dart` | Socket.IO client, 13 broadcast streams, offline queue | socket_io_client |
| `mobile/lib/core/services/data_service.dart` | Facade combining all services | BusService, RouteService, UserService |
| `mobile/lib/core/services/persistence_service.dart` | SharedPreferences + route directions offline cache | SharedPreferences, SecureStorageService |
| `mobile/lib/core/providers/service_providers.dart` | Riverpod wiring for all services + theme/locale | All services |
| `mobile/lib/core/providers/repository_providers.dart` | Riverpod wiring for all repositories | Dio, all repositories |
| `mobile/lib/shared/widgets/maps/live_bus_map.dart` | Animated multi-bus map (student/coordinator) | SocketService, GoogleMaps, RouteModel |
| `mobile/lib/features/driver/presentation/driver_dashboard.dart` | Driver screen: ETA + deviation detection | SocketService, LocationService |
| `mobile/lib/features/driver/presentation/widgets/driver_live_tracking_tab.dart` | Driver map + polyline trimming | route_math_utils, CommonMapView |
| `mobile/lib/features/teacher/presentation/tabs/teacher_live_tracking_tab.dart` | Teacher override map | route_math_utils, LiveBusMap |
| `mobile/lib/core/utils/route_math_utils.dart` | trimPolylineAtBus, distanceToSegment, findClosestPointIndex | geolocator, google_maps_flutter |
| `mobile/lib/core/utils/map_marker_helper.dart` | Custom bus/stop BitmapDescriptor markers | google_maps_flutter |
| `server/src/app.ts` | Express + Socket.IO setup, CORS, security | All middleware, router |
| `server/src/index.ts` | Server bootstrap (DB, Redis, Firebase, cron) | app.ts, all configs |
| `server/src/socket/handlers/location.ts` | GPS handler: outlier guard + throttle + broadcast + stop_reached | busCache, rateLimiter, locationBuffer |
| `server/src/services/busAssignmentService.ts` | Assignment lifecycle (pending/accept/reject/complete) + FCM | Bus, User, NotificationService |
| `server/src/services/notificationService.ts` | Templated FCM push + Notification DB save | Firebase, buildNotification, User |
| `server/src/middleware/authMiddleware.ts` | JWT verify + tokenVersion + premium expiry auto-downgrade | jsonwebtoken, User model |
| `client/src/App.jsx` | React Router, lazy loading, layout structure | All pages, PrivateRoute |
| `client/src/api/axios.js` | Axios instance with JWT Authorization interceptor | localStorage |
| `client/src/app/store.js` | Redux Toolkit store | All feature slices |

---

## 5. Feature Map

### Bus Assignment (Core)
- Mobile: `coordinator_dashboard.dart` → `driver_selection_screen.dart` → `driver_dashboard.dart` → `student_map_tab.dart`
- Server: `PUT /api/v1/buses/:id` → `bus.controller` → `busAssignmentService.ts`
- Socket: `bus_updated` event → all college room members
- Lifecycle: `unassigned → pending → accepted → unassigned`

### Real-Time GPS Tracking
- Mobile emit: `SocketService.updateLocation()` → `update_location` socket event
- Server: `location.ts` → outlier guard → throttle 3 s → `location_updated` broadcast
- Mobile receive: `locationUpdateStream` → `LiveBusMap._handleLocationUpdate()` → animated marker
- Polyline: `trimPolylineAtBus()` called every 6th animation frame

### Route Management
- Mobile: `route_model.dart`, `route_service.dart`, `route_repository.dart`
- Server: `route.routes.ts` → `route.controller` → `DirectionsService.ts`
- DB: `Route.model.ts` (startPoint, stopPoints[], endPoint, routeType, directions{polylinePoints[]}, color)
- API: `GET/POST/PUT/DELETE /api/v1/routes`

### SOS Emergency
- Mobile: `sos_button.dart` → `sos_provider.dart` → socket `sos_trigger`
- Server: `sos.routes` → `sosService.ts` → FCM to coordinators + `sos_alert` socket event
- Resolve: coordinator resolves → `sos_resolved` event

### Teacher Override
- Mobile: `teacher_dashboard.dart` → override request → coordinator approves → teacher starts GPS
- Server: `POST /api/v1/buses/:id/override-request`, `PUT /api/v1/buses/:id/override-approve`
- Socket: Same `update_location` event; validated by `bus.trackingTeacherId == user.id`

### Notifications
- Server: `notificationService.ts` builds en/hi/te templates → saves to DB + FCM push
- Mobile: FCMService receives push → NotificationService shows local notification
- API: `GET /api/v1/notifications`, `PUT /api/v1/notifications/:id/read`

### Payments / Subscriptions
- Plans seeded at startup; managed via `/api/v1/plans`
- Cron: `payment.cron.ts` — daily check downgrades expired premium users
- Auth middleware auto-checks `isPremium` + `premiumUntil` on every request

### Stop Arrival Detection
- Driver detects bus within 50 m of stop → `socket.emit('stop_reached')`
- Server rebroadcasts `stop_reached` to college room
- Students receive via `SocketService.stopReachedStream`

---

## 6. Shared Logic

| Module | Source File | Used By | Purpose |
|--------|------------|---------|---------|
| `trimPolylineAtBus` | `core/utils/route_math_utils.dart` | LiveBusMap, Driver tab, Teacher tab | Segment-projection polyline trim — line starts exactly AT bus |
| `distanceToSegment` | `core/utils/route_math_utils.dart` | DriverDashboard deviation check | Perpendicular distance from GPS point to segment |
| `findClosestPointIndex` | `core/utils/route_math_utils.dart` | DriverDashboard ETA | Nearest discrete polyline point index |
| `MapMarkerHelper` | `core/utils/map_marker_helper.dart` | LiveBusMap, Driver, Teacher | createBusMarker(), getStartMarker(), getStopMarker(), getEndMarker() |
| `CommonMapView` | `widgets/common/common_map_view.dart` | Driver tab, Teacher tab (active) | Shared GoogleMap with single-bus marker + polyline |
| `LiveBusMap` | `shared/widgets/maps/live_bus_map.dart` | Student, Coordinator, Teacher (passive) | Multi-bus animated tracking map |
| `SocketService` | `core/services/socket_service.dart` | All dashboards | Single Socket.IO connection; 13 broadcast streams |
| `DataService` | `core/services/data_service.dart` | All dashboards | Service facade |
| `PersistenceService` | `core/services/persistence_service.dart` | Auth, Driver, Student | SharedPreferences + token cache + route directions cache |
| `SecureStorageService` | `core/services/secure_storage_service.dart` | Auth, PersistenceService | Encrypted: auth/refresh tokens, driver_bus_id, driver_route_id |
| `RouteModel.getOrderedStops` | `features/route/domain/route_model.dart` | LiveBusMap, Driver, Teacher | Respects tripType: pickup=[start…stops…end], drop=reversed |
| `NotificationService` (server) | `server/src/services/notificationService.ts` | Bus, SOS, assignment controllers | Sends templated FCM push + saves Notification to DB |
| `busAssignmentService` | `server/src/services/busAssignmentService.ts` | Bus controller | All assignment state transitions + side-effect notifications |
| `authMiddleware` | `server/src/middleware/authMiddleware.ts` | All server routes | JWT verify + tokenVersion + premium expiry auto-downgrade |
| `axios.js` (client) | `client/src/api/axios.js` | All client feature API modules | Shared Axios with `Authorization: Bearer` interceptor |

---

## 7. API Map

All endpoints prefixed with `/api/v1`.

| Method | Endpoint | Auth | Roles | Purpose |
|--------|----------|------|-------|---------|
| POST | `/auth/login` | No | All | Login, returns JWT + refresh token |
| POST | `/auth/register` | No | All | Register new user |
| POST | `/auth/refresh` | No | All | Refresh JWT |
| POST | `/auth/logout` | JWT | All | Logout, increments tokenVersion |
| POST | `/auth/send-otp` | No | All | Send OTP |
| POST | `/auth/verify-otp` | No | All | Verify OTP |
| GET | `/users/me` | JWT | All | Current user profile |
| PUT | `/users/:id` | JWT | Owner | Update user (FCM token, profile) |
| GET | `/buses` | JWT | Coordinator+ | Bus list for college |
| POST | `/buses` | JWT | CollegeAdmin+ | Create bus |
| PUT | `/buses/:id` | JWT | Coordinator+ | Update bus (triggers assignment lifecycle) |
| DELETE | `/buses/:id` | JWT | CollegeAdmin+ | Delete bus |
| POST | `/buses/:id/override-request` | JWT | Teacher | Request GPS override |
| PUT | `/buses/:id/override-approve` | JWT | Coordinator | Approve teacher override |
| GET | `/routes` | JWT | All | Routes for college |
| POST | `/routes` | JWT | Coordinator+ | Create route (fetches Directions) |
| PUT | `/routes/:id` | JWT | Coordinator+ | Update route |
| DELETE | `/routes/:id` | JWT | CollegeAdmin+ | Delete route |
| GET | `/notifications` | JWT | All | User's notifications |
| PUT | `/notifications/:id/read` | JWT | Owner | Mark read |
| POST | `/sos` | JWT | Driver | Trigger SOS |
| PUT | `/sos/:id/resolve` | JWT | Coordinator+ | Resolve SOS |
| GET | `/sos` | JWT | Coordinator+ | SOS events for college |
| POST | `/incidents` | JWT | All | Report incident |
| GET | `/history` | JWT | Coordinator+ | Trip history |
| GET | `/schedules` | JWT | All | Bus schedules |
| POST | `/payments` | JWT | Student | Create payment/transaction |
| GET | `/plans` | No | All | Available subscription plans |
| GET | `/colleges` | JWT | SuperAdmin | All colleges |
| POST | `/colleges` | JWT | SuperAdmin | Create college |
| PUT | `/colleges/:id` | JWT | SuperAdmin | Update college |
| GET | `/admin/college/users` | JWT | CA+ | Users in college |
| PUT | `/admin/college/users/:id/approve` | JWT | CA+ | Approve user |
| GET | `/admin/super/stats` | JWT | SA | System-wide stats |
| GET | `/admin/audit-logs` | JWT | CA+ | Audit logs |
| GET | `/admin/system-config` | JWT | SA | System configuration |
| GET | `/places/autocomplete` | JWT | All | Google Places autocomplete proxy |

---

## 8. State Management

### Flutter — Riverpod

| Provider | Type | Purpose |
|----------|------|---------|
| `authProvider` | AsyncNotifierProvider | Auth state: current user + token |
| `socketServiceProvider` | ChangeNotifierProvider | Single socket connection + all 13 streams |
| `dataServiceProvider` | ChangeNotifierProvider | Service facade |
| `busServiceProvider` | Provider | Bus CRUD + socket ops |
| `routeServiceProvider` | Provider | Route CRUD + directions loading |
| `locationServiceProvider` | Provider | GPS access (geolocator) |
| `themeServiceProvider` | NotifierProvider | Dark/light, map theme, accent color |
| `localeServiceProvider` | NotifierProvider | App language (en/hi/te) |
| `mapStyleProvider` | FutureProvider | Google Maps JSON style per theme |
| `collegeBusesStreamProvider` | StreamProvider | Live bus list for a college |
| `driverBusProvider` | AsyncNotifierProvider | Driver's assigned bus |
| `driverLocationProvider` | NotifierProvider | Driver GPS state |
| `driverMapStateProvider` | NotifierProvider | Driver map: route selection + directions |
| `mapNavigationProvider` | NotifierProvider | Camera follow, center, zoom for student map |
| `activeSosProvider` | StreamProvider.family | Active SOS for college |

### React — Redux Toolkit

| Slice | Feature | Purpose |
|-------|---------|---------|
| `authSlice` | features/auth | Login state: user object, JWT, role |
| SA slices | features/super-admin/slices | Colleges, global users, plans |
| CA slices | features/college-admin/slices | Fleet, users, routes, payments |

---

## 9. Database

Database: MongoDB via Mongoose.
User `_id` is a custom string. All other models use ObjectId.

### Core Models

**User** (`User.model.ts`) — key fields:
- `role`: student | teacher | driver | busCoordinator | collegeAdmin | superAdmin | parent
- `collegeId`: required for all roles except superAdmin
- `approved`: must be true before user can access the app
- `tokenVersion`: incremented on logout — invalidates all existing JWTs
- `fcmToken`: device push token for FCM
- `routeId`, `stopId`, `stopName`, `stopLocation`: student's assigned route + preferred stop
- `stopLocationGeo`: GeoJSON Point (2dsphere index) for proximity queries
- `isPremium`, `premiumUntil`, `subscriptionPlan`: subscription state
- `loginAttempts`, `lockUntil`: brute-force protection

**Bus** (`Bus.model.ts`) — key fields:
- `busNumber`: unique per college (compound index with collegeId)
- `driverId`: currently assigned driver user ID
- `routeId`: active trip route (changes per trip)
- `defaultRouteId`: persistent default route (set by admin)
- `assignmentStatus`: unassigned | pending | accepted — THE core state machine field
- `status`: on-time | delayed | not-running
- `trackingTeacherId`: set when a teacher override is active
- `shiftId`: links bus to college shift schedule

**Route** (`Route.model.ts`) — key fields:
- `routeType`: pickup | drop — determines stop direction
- `startPoint`, `endPoint`: {name, location: {lat, lng}}
- `stopPoints[]`: intermediate stops
- `directions`: cached Google Directions {polylinePoints[], totalDistanceKm, totalDurationMin, legs[]}
- `color`: hex string for polyline color (default #1E90FF)

**College** (`College.model.ts`) — key fields:
- `allowedDomains[]`: email domain whitelist
- `busNumbers[]`: allowed bus number registry
- `verified`, `suspended`: super admin control flags
- `shifts[]`: college shift definitions with pickup/drop times
- `allowManualPremium`: super admin override

### Supporting Models

| Model | Purpose |
|-------|---------|
| `Notification.model.ts` | Push notification records per user |
| `Sos.model.ts` | SOS events (status: active/resolved, location, driver) |
| `Incident.model.ts` | Driver incident reports |
| `History.model.ts` | Trip history records |
| `BusAssignmentLog.model.ts` | Audit trail for assignment state changes |
| `AuditLog.model.ts` | Admin action audit trail |
| `Plan.model.ts` | Subscription plan definitions |
| `Transaction.model.ts` | Payment transaction records |
| `Schedule.model.ts` | Bus schedule entries |
| `MetricSnapshot.model.ts` | System analytics snapshots |
| `SystemConfig.model.ts` | Global key-value configuration |
| `TeacherOverrideRequest.model.ts` | Teacher override request tracking |

### Relationships
```
College (1) ─── (n) User
College (1) ─── (n) Bus
College (1) ─── (n) Route
Bus     (n) ─── (1) Route  [routeId / defaultRouteId]
Bus     (n) ─── (1) User   [driverId]
User[student] ─ (1) Route  [routeId]
User[student] ─ stopId/stopLocation [denormalized stop ref]
```

---

## 10. Navigation

### Flutter (GoRouter)

| Path | Widget | Roles |
|------|--------|-------|
| `/` | SplashScreen | All |
| `/login` | LoginScreen | Unauthenticated |
| `/register` | RegisterScreen | Unauthenticated |
| `/forgot-password` | ForgotPasswordScreen | Unauthenticated |
| `/otp-verify` | OtpVerificationScreen | Unauthenticated |
| `/reset-password` | ResetPasswordScreen | Unauthenticated |
| `/student` | StudentDashboard | student, parent |
| `/student/schedule` | BusScheduleScreen | student |
| `/student/bus-stop` | StudentBusStopScreen | student |
| `/teacher` | TeacherDashboard | teacher |
| `/driver` | DriverDashboard | driver |
| `/coordinator` | CoordinatorDashboard | busCoordinator |
| `/coordinator/assign-driver/:busNumber` | DriverSelectionScreen | busCoordinator |
| `/coordinator/assignment-history/:busId/:busNumber` | AssignmentHistoryScreen | busCoordinator |
| `/coordinator/edit-bus/:busNumber` | EditBusScreen | busCoordinator |
| `/coordinator/edit-driver/:driverId` | EditDriverScreen | busCoordinator |
| `/coordinator/schedule` | ScheduleManagementScreen | busCoordinator |
| `/college-admin` | CollegeAdminDashboard | collegeAdmin |
| `/super-admin` | SuperAdminDashboard | superAdmin |
| `/super-admin/colleges/:id` | CollegeDetailsScreen | superAdmin |
| `/profile` | ProfileScreen | All authenticated |
| `/profile/edit` | EditProfileScreen | All authenticated |
| `/notifications` | NotificationsScreen | All authenticated |
| `/referral` | ReferralScreen | All authenticated |

Auth redirect: unauthenticated → /login. Authenticated on login/root route → role dashboard.

### React (BrowserRouter)

| Path | Component | Roles |
|------|-----------|-------|
| `/login` | Login | All |
| `/college-admin` | Dashboard | collegeAdmin |
| `/college-admin/users` | Users | collegeAdmin |
| `/college-admin/fleet` | Fleet | collegeAdmin |
| `/college-admin/routes` | Routes | collegeAdmin |
| `/college-admin/payments` | Payments | collegeAdmin |
| `/college-admin/tracking` | LiveTracking | collegeAdmin |
| `/college-admin/logs` | Logs | collegeAdmin |
| `/super-admin` | SuperAdminDashboard | superAdmin |
| `/super-admin/colleges` | Colleges | superAdmin |
| `/super-admin/colleges/:id` | CollegeDetails | superAdmin |
| `/super-admin/users` | GlobalUsers | superAdmin |
| `/super-admin/audit` | AuditLogs | superAdmin |
| `/super-admin/payments` | GlobalPayments | superAdmin |
| `/super-admin/analytics` | AdvancedAnalytics | superAdmin |
| `/super-admin/tracking` | GlobalTracking | superAdmin |
| `/super-admin/plans` | SubscriptionPlans | superAdmin |
| `/coordinator` | CoordinatorDashboard | busCoordinator |
| `/coordinator/tracking` | CoordinatorLiveTracking | busCoordinator |
| `/coordinator/routes` | CoordinatorRoutes | busCoordinator |

---

## 11. Configuration

### Server (`server/.env`)

| Variable | Purpose |
|----------|---------|
| `PORT` | HTTP listen port (default 5000) |
| `MONGODB_URI` | MongoDB Atlas connection string |
| `JWT_SECRET` | JWT signing secret |
| `REDIS_URL` | Redis connection URL |
| `FIREBASE_SERVICE_ACCOUNT_KEY` | Firebase Admin SDK credentials |
| `GOOGLE_MAPS_API_KEY` | Server-side Directions API key |
| `AWS_ACCESS_KEY_ID` | S3 access key |
| `AWS_SECRET_ACCESS_KEY` | S3 secret |
| `AWS_S3_BUCKET_NAME` | S3 bucket name |
| `AWS_REGION` | S3 region |
| `VITE_CLIENT_URL` | Allowed CORS origin (production web client URL) |
| `VITE_CLIENT_IP_URL` | Additional allowed CORS IP (LAN dev) |
| `NODE_ENV` | development or production |

### Client (`client/.env`)

| Variable | Purpose |
|----------|---------|
| `VITE_API_URL` | Backend REST base URL |
| `VITE_GOOGLE_MAPS_API_KEY` | Google Maps JS API key |

### Mobile
- `google-services.json` — Firebase Android config (gitignored)
- `AndroidManifest.xml` — Permissions: ACCESS_FINE_LOCATION, ACCESS_BACKGROUND_LOCATION, INTERNET, POST_NOTIFICATIONS
- `pubspec.yaml` — All Flutter package dependencies

---

## 12. Reusable Components

### Flutter Shared Widgets (`mobile/lib/shared/widgets/`)

| Widget | Purpose |
|--------|---------|
| `LiveBusMap` | Animated multi-bus tracking map; GPS outlier guard; socket stream listener; 6-frame throttled polyline trim |
| `TripProgressSheet` | Bottom sheet with stop progress indicators during active trip |
| `SosButton` | Driver/teacher emergency SOS trigger with confirmation |
| `BusCard` | Bus info card (number, status, driver, route) |
| `CustomButton` | Primary/secondary branded action button |
| `CustomInputField` | Styled text input with validation |
| `GlassMorphicContainer` | Frosted glass UI container |
| `GlobalConnectivityBanner` | App-level network status banner wrapping the entire app |
| `ShimmerSkeletons` | Loading state skeleton placeholders |
| `SuccessModal` / `ApiErrorModal` | Result feedback dialogs |
| `VectorEmptyState` | Empty state illustration widget |
| `LanguageSelector` | Language picker |
| `IncidentReportModal` | Driver incident report submission modal |

### React Components (`client/src/components/`)

| Component | Purpose |
|-----------|---------|
| `PrivateRoute` | Role-based route guard |
| `ErrorBoundary` | Global React error boundary |
| `LoadingFallback` | Suspense fallback spinner |

---

## 13. Utilities

| Utility | File | Purpose |
|---------|------|---------|
| `trimPolylineAtBus(busPos, points)` | `route_math_utils.dart` | Returns [projectedFoot, ...remaining] — polyline always starts AT bus |
| `distanceToSegment(point, segA, segB)` | `route_math_utils.dart` | Perpendicular distance (meters) from GPS point to segment |
| `findClosestPointIndex(point, points)` | `route_math_utils.dart` | Index of nearest discrete polyline point |
| `MapMarkerHelper.createBusMarker()` | `map_marker_helper.dart` | Custom bus BitmapDescriptor — ALWAYS use this, never default pin |
| `MapMarkerHelper.getStartMarker()` | `map_marker_helper.dart` | Green start marker |
| `MapMarkerHelper.getStopMarker()` | `map_marker_helper.dart` | Orange intermediate stop marker |
| `MapMarkerHelper.getEndMarker()` | `map_marker_helper.dart` | Red end marker |
| `MapStyleHelper.getStyleForTheme()` | `map_style_helper.dart` | Google Maps JSON style for dark/light/auto |
| `AppLogger.i/d/e/w()` | `app_logger.dart` | Structured logging with file output — use instead of print() |
| `ShaderPrecompiler.precompileAll()` | `shader_precompiler.dart` | Pre-compiles fragment shaders at boot to prevent first-render jank |
| `busNearbyLogic.ts` | `server/utils/busNearbyLogic.ts` | Checks if bus is within alert distance of any student's stop (2dsphere) |
| `buildNotificationMessage(type, payload, lang)` | `server/utils/buildNotification.ts` | Localized notification title + body from template |
| `firebase.ts` | `server/utils/firebase.ts` | Firebase Admin init; sendNotificationToDevice, sendNotificationToDevices, sendNotificationToTopic |
| `logger.ts` | `server/utils/logger.ts` | Winston logger with file rotation + Socket.IO log transport |

---

## 14. Services

### Mobile Services

| Service | Responsibility |
|---------|---------------|
| `SocketService` | Single Socket.IO connection; emits update_location, join_college, stop_reached; 13 broadcast streams; offline _eventQueue with 30-item location cap |
| `DataService` | Facade — combines BusService, RouteService, UserService, IncidentService, NotificationDataService, PaymentService |
| `BusService` | Bus CRUD, assignment operations via REST + socket |
| `RouteService` | Route CRUD, directions loading, route assignment |
| `LocationService` | GPS tracking stream; accuracy filtering; callback chain for deviation detection |
| `DirectionsService` | Fetches Google Maps Directions; returns DirectionsResult with polyline + legs |
| `PersistenceService` | SharedPreferences: auth token cache, selected_bus_id, isSharingLocation, route directions offline cache |
| `SecureStorageService` | flutter_secure_storage: auth token, refresh token, driver_bus_id, driver_route_id |
| `FCMService` | Firebase push registration, FCM token management, foreground/background message handling |
| `NotificationService` | Local notification display (flutter_local_notifications) |
| `VoiceRecordingService` | Record + upload voice messages to S3 |

### Server Services

| Service | Responsibility |
|---------|---------------|
| `busAssignmentService` | ALL assignment transitions: pending notification, accepted notification, rejection cleanup, trip completion history log, route change notification |
| `busService` | Bus CRUD, status updates |
| `notificationService` | Builds multilingual template, saves to Notification collection, sends FCM |
| `DirectionsService` | Google Maps Directions API server-side + caching in Route document |
| `s3Service` | Pre-signed URLs, uploads/downloads for AWS S3 |
| `sosService` | SOS creation + FCM broadcast to college coordinators; resolution with socket event |
| `AuditService` | Creates AuditLog records for admin actions |
| `MetricsService` | Metric snapshot collection on cron schedule |
| `collegeService` | College CRUD, domain validation, suspension management |

---

## 15. Middleware

| Middleware | Behavior |
|-----------|---------|
| `protect` | Verifies Bearer JWT; calls User.findById; checks tokenVersion match; auto-downgrades expired premium; populates req.user |
| `authorize(...roles)` | Checks req.user.role is in whitelist; returns 403 otherwise |
| `superAdminOnly` | Shorthand authorize('superAdmin') |
| `collegeAdminOnly` | Allows superAdmin + collegeAdmin; cross-tenant check on targetCollegeId |
| `premiumOnly` | Blocks non-premium users (superAdmin bypasses); returns code: 'PREMIUM_REQUIRED' |
| `errorHandler` | Global Express error handler — standardizes error response format |
| `requestIdMiddleware` | Attaches unique X-Request-ID UUID header for tracing |
| `validate` | Schema validation of req.body/params; returns 400 on failure |
| Rate Limiter | 300 req/min/IP on all /api/v1 routes |
| Socket Auth | JWT in Socket.IO handshake.auth.token; populates socket.user |

---

## 16. Business Logic

### Authentication
1. POST /auth/login → verify credentials → JWT (id, email, role, collegeId, tokenVersion)
2. Axios/Dio attaches Authorization: Bearer on every request
3. protect: verify JWT, check tokenVersion == DB value, check premium expiry (auto-downgrade)
4. Logout: tokenVersion++ in DB → all existing tokens invalid

### Assignment Lifecycle (CRITICAL — never bypass)
```
unassigned → pending:   Coordinator PUT /buses/:id with driverId + routeId
pending → accepted:     Driver PUT /buses/:id with assignmentStatus='accepted' → GPS auto-starts
pending → unassigned:   Driver rejects → driverId cleared
accepted → unassigned:  Trip complete or driver stops
```

### GPS Tracking Chain
```
Driver GPS tick → LocationService.onLocationUpdate
  → SocketService.updateLocation()
  → socket.emit('update_location')
Server:
  → validate → outlier guard (500m) → throttle (3s) → broadcast location_updated
Mobile:
  → SocketService.locationUpdateStream
  → LiveBusMap._handleLocationUpdate() → client outlier guard (500m)
  → AnimationController lerp 60fps → smooth bus marker movement
  → every 6th frame: trimPolylineAtBus() → polyline starts AT bus
```

### Route Direction (tripType)
- pickup: [startPoint, ...stopPoints, endPoint] — suburbs to college
- drop: [endPoint, ...stopPoints.reversed, startPoint] — college to suburbs
- Always call RouteModel.getOrderedStops(tripType) — never manually reverse in map widgets

---

## 17. Dependency Relationships

### Full Bus Assignment Chain
```
Coordinator assigns → PUT /api/v1/buses/:id
  → protect + authorize('busCoordinator')
  → bus.controller → busAssignmentService.handleAssignmentChanges()
  → Bus.model.save() → MongoDB
  → notificationService → FCM → Driver device
  → io.to(collegeId).emit('bus_updated')
  → DriverDashboard: pending card appears
Driver accepts → PUT /api/v1/buses/:id {assignmentStatus:'accepted'}
  → busAssignmentService → Bus.save()
  → io.to(collegeId).emit('bus_updated')
  → Student can now select bus for tracking
  → Driver LocationService starts → socket.emit('update_location') per GPS tick
  → Students receive location_updated → LiveBusMap animates
```

### Student Tracking Chain
```
StudentDashboard
  → collegeBusesStreamProvider (busListUpdateStream)
  → StudentMapTab: select bus where assignmentStatus == 'accepted'
  → LiveBusMap mounted → listens to locationUpdateStream
  → _handleLocationUpdate: client outlier guard → _animatedLocations lerp
  → AnimationController 60fps → bus marker moves smoothly
  → every 6th frame: _updateRoutePolyline → trimPolylineAtBus()
  → Polyline starts exactly at current animated bus position
```

---

## 18. Cross References

**Changing Authentication:**
`authMiddleware.ts` + `User.model.ts` (tokenVersion) + `mobile/features/auth/` + `persistence_service.dart` + `secure_storage_service.dart` + `client/api/axios.js` + `client/features/auth/`

**Changing Bus Assignment:**
`busAssignmentService.ts` + `Bus.model.ts` + `bus_model.dart` + `coordinator_dashboard.dart` + `driver_dashboard.dart` + `socket/handlers/` + `.agents/rules/Bus-logic.md`

**Changing Map / Polyline:**
`route_math_utils.dart` + `live_bus_map.dart` + `driver_live_tracking_tab.dart` + `teacher_live_tracking_tab.dart` + `map_marker_helper.dart` + `common_map_view.dart`

**Changing Route Model:**
`Route.model.ts` + `route_model.dart` + `route_repository.dart` + all map widgets

**Changing Notifications:**
`notificationService.ts` + `buildNotification.ts` + `notificationTypes.ts` + `fcm_service.dart` + `notification_service.dart`

**Changing Socket Events:**
`server/src/socket/handlers/` (all files) + `socket_service.dart` + all dashboard files + `.agents/rules/Bus-logic.md`

---

## 19. Development Rules

### `.agents/AGENTS.md` (always active)
- NEVER run `git push` automatically
- After changes: stage + commit locally; output formatted commit message for user review

### `.agents/rules/Bus-logic.md` (always active for core logic)

**Assignment**: unassigned → pending → accepted. Never skip pending. Never set accepted without driver explicitly accepting.

**Real-Time Data Flow**:
1. Socket is PRIMARY; REST is fallback only when SocketService.isConnected == false
2. location_updated → locationUpdateStream is THE ONLY source for real-time bus position
3. bus_updated → busUpdateStream + busListUpdateStream must trigger all assignment-status UI
4. join_college MUST be emitted on connect, reconnect, AND app lifecycle resume
5. Offline queue _eventQueue max 30 location events — never queue without cap

**Map Display**:
- Student: only buses where assignmentStatus=='accepted' AND in liveBusIds
- Bus icon: always MapMarkerHelper.createBusMarker() — NEVER default pin
- Stops: getStartMarker() green, getStopMarker() orange, getEndMarker() red

**State Persistence**:
- Validate selected_bus_id against live provider on startup
- Clear selected_bus_id if bus is no longer accepted
- Validate driver_bus_id against driverBusProvider before restoring

**Agent MUST NOT**:
- Skip pending state
- Allow student tracking of non-accepted buses
- Use Firestore reads for real-time location
- Bypass PersistenceService staleness checks
- Duplicate polyline rendering outside CommonMapView/MapMarkerHelper
- Change ETA (30 km/h) or deviation threshold (200m) without a comment at call site

---

## 20. Coding Conventions

### Flutter / Dart
- Files: snake_case.dart; Classes: PascalCase; Variables: camelCase
- Feature structure: presentation/, application/, domain/, data/
- Domain models: immutable — always use .copyWith(), never mutate directly
- State: Riverpod only; no setState at top-level dashboards
- Logging: AppLogger.i/d/e/w() — never use print()
- Errors: AppExceptions typed exceptions; catch in repository layer

### TypeScript / Express
- Files: camelCase.ts; Models: PascalCase.model.ts
- Controllers: request/response only; all business logic in services
- Every protected route: protect + authorize([roles]) middleware chain
- Errors: try/catch in controllers; call next(err) for errorHandler

### React / JavaScript
- Components: PascalCase.jsx; Utilities: camelCase.js
- State: Redux Toolkit slices; no Context for business data
- API calls: always through client/src/api/axios.js — never create a separate Axios instance
- Protected routes: always wrap with PrivateRoute

### API Response Format
- Success: { "message": "...", "data": {...} }
- Error:   { "message": "...", "code": "OPTIONAL_ERROR_CODE" }

---

## 21. AI Instructions

1. **Read this file first** before scanning any source files.
2. **Use this as primary knowledge source** — do not re-derive architecture from scratch.
3. **Only open source files** when you need exact function signatures, line numbers, or local variable names.
4. **Follow all rules** in `.agents/AGENTS.md` and `.agents/rules/Bus-logic.md` — especially: never git push; never skip assignment pending; never use default pins; never duplicate polyline rendering.
5. **After completing changes**: provide formatted commit message; do NOT run `git push`.
6. **Update this file** when: new features added, files renamed/moved, new providers/services created, API endpoints change, architecture changes.
7. **Read `AI_CHANGELOG.md`** after this file to see recent changes not yet reflected above.
8. **Never leave outdated information** — correct or remove stale sections when updating.
