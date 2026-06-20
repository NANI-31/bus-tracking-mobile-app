---
trigger: always_on
---

# Bus Tracking Core Logic — Agent Improvement Rules

This rule governs how the agent approaches all tasks related to the **core logic, data
flows, actor interactions, and real-time tracking architecture** of this bus tracking
application.

---

## Scope

These rules apply whenever the task involves any of the following:

- Bus assignment lifecycle (Coordinator → Driver → Student)
- Real-time location sharing, receiving, or display (Socket.IO streams)
- Route creation, assignment, or map rendering
- `assignmentStatus` state transitions (`unassigned` → `pending` → `accepted`)
- `BusModel`, `BusLocationModel`, `RouteModel`, `RoutePoint` domain models
- Actor dashboards: `StudentDashboard`, `DriverDashboard`, `CoordinatorDashboard`
- `SocketService` events: `location_updated`, `bus_updated`, `driver_status_update`
- `DataService`, `BusService`, `BusRepository`, `RouteService` operations
- `MapNavigationState`, `StudentMapTab`, `CommonMapView`
- `PersistenceService`, `SecureStorageService` (stored bus/route selections)
- ETA calculation, route deviation detection, or stop-point proximity logic

---

## Core Actor Contract

Every improvement MUST respect the following actor permission boundaries:

### Admin / Super Admin

- Manages colleges, bus number registry, and user approvals
- Does **not** assign buses to drivers or control live tracking
- Owns `defaultRouteId` on a bus (permanent default route)

### Coordinator

- Assigns a driver to a bus → sets `assignmentStatus = 'pending'`
- Assigns a `routeId` to the bus at assignment time
- Can track any **accepted** and **active** bus via the Live Map tab
- Cannot force-start or override a driver's tracking session

### Driver

- Sees a pending assignment card → can **Accept** or **Reject**
- On Accept: `assignmentStatus = 'accepted'`, location sharing auto-starts
- On Reject: `driverId = null`, `assignmentStatus = 'unassigned'`, `status = 'not-running'`
- Emits `update_location` via `SocketService.updateLocation()` at GPS intervals
- Also sets `status = 'on-time'` on start and `status = 'not-running'` on stop

### Student

- Can only select and track a bus where `assignmentStatus == 'accepted'`
- The selected bus is persisted via `PersistenceService` (`selected_bus_id`)
- If the persisted bus is no longer `accepted`, the selection MUST be cleared on startup
- Receives live bus location from `SocketService.locationUpdateStream`

---

## Assignment Lifecycle — The Single Source of Truth

```
Coordinator assigns bus
        │
        ▼
BusModel.assignmentStatus = 'pending'
BusModel.driverId = <driver_id>
BusModel.routeId = <route_id>
        │
        ▼
[Socket emits 'bus_updated']
        │
   ┌────┴─────────────────────┐
   ▼                          ▼
Driver sees                 Coordinator sees
pending card                status = 'pending'
   │
   ├── Accept ──► assignmentStatus = 'accepted'
   │               auto-starts location sharing
   │               emits 'update_location' via socket
   │
   └── Reject ──► assignmentStatus = 'unassigned'
                  driverId = null, status = 'not-running'
```

**Rule**: Never skip or short-circuit this lifecycle. Any code that changes
`assignmentStatus` directly to `'accepted'` without going through `'pending'` first is
a logic violation.

---

## Real-Time Data Flow Rules

1. **Socket is the primary channel** — REST API (`BusRepository`) is only the fallback
   when `SocketService.isConnected == false`. Never replace socket events with polling.

2. **`location_updated` → `locationUpdateStream`** is the canonical source for a bus's
   position on every map tab (`StudentMapTab`, driver's `CommonMapView`, coordinator's
   live map). Do not read position from Firestore or REST for real-time display.

3. **`bus_updated` → `busUpdateStream` + `busListUpdateStream`** must trigger UI
   refresh of assignment status badges, driver cards, and student bus lists.

4. **`join_college`** must be emitted whenever the socket connects or reconnects, and
   on every app resume (`didChangeAppLifecycleState` → `AppLifecycleState.resumed`).
   Missing this causes all subsequent events to be silently dropped.

5. **Offline queue** (`_eventQueue` in `SocketService`) flushes on reconnect. Do not
   add location updates to the queue indefinitely — apply rate limiting or a max-depth
   cap to prevent memory bloat.

---

## Route Model Integrity Rules

- `RouteModel` has: `startPoint`, `stopPoints[]`, `endPoint`, `routeType` ('pickup' | 'drop'), `color`
- `directions` (`DirectionsResult`) holds the polyline/encoded path for Google Maps rendering
- **Always prefer `directions` data** over drawing straight lines between `RoutePoint`s
- `defaultRouteId` on `BusModel` is a persistent preference; `routeId` is the active trip route
- When a driver selects a route before starting, store it via `SecureStorageService.setDriverRouteId()`
- On next startup, restore via `bus.routeId` matching inside `collegeRoutesProvider`

---

## Map Display Rules

- **Student map**: Only render buses where `assignmentStatus == 'accepted'`
  AND the bus appears in `liveBusIds` (from `locationUpdateStream`)
- **Coordinator map**: Render all accepted + active buses in the college
- **Driver map**: Renders own bus marker + assigned route polyline + stop markers
- Stop markers must use `MapMarkerHelper` icons:
  - Start: `getStartMarker()` — green
  - Intermediate: `getStopMarker()` — orange
  - End: `getEndMarker()` — red
- Route polyline color comes from `RouteModel.color` (hex string, default `#0097B2`)
- Bus icon must be loaded via `MapMarkerHelper.createBusMarker()` — never use default pin

---

## ETA & Deviation Detection Rules

- Route deviation threshold is **200 meters** from the nearest route segment
- Deviation alerts are rate-limited to **once per minute** (`_lastDeviationAlertTime`)
- ETA is calculated using a default average speed of **30 km/h (8.33 m/s)** when real
  speed is unavailable
- ETA targets the **nearest stop point**, not the route end
- These calculations run inside `_checkRouteDeviation()` and `_calculateETA()` in
  `DriverDashboard` — improvements to these must not break the call chain from
  `locationService.startLocationTracking(onLocationUpdate: ...)`

---

## State Persistence Rules

| Key                 | Service                | Cleared When                             |
| ------------------- | ---------------------- | ---------------------------------------- |
| `selected_bus_id`   | `PersistenceService`   | Bus is no longer `accepted` on app start |
| `isSharingLocation` | `PersistenceService`   | Driver stops sharing or logs out         |
| `driver_bus_id`     | `SecureStorageService` | Driver rejects / assignment is removed   |
| `driver_route_id`   | `SecureStorageService` | Route is changed or assignment removed   |

**Rule**: Never read stale persisted IDs without re-validating against the live
provider data. Always cross-check against `collegeBusesStreamProvider` or
`driverBusProvider` before restoring a persisted selection.

---

## What the Agent MUST Focus On

When improving any part of this system, the agent MUST:

1. **Trace the full actor data pipeline** — from the action initiator (e.g., Coordinator
   tapping "Assign") to the final consumer (e.g., Student seeing the bus on the map)
   before writing any code.

2. **Verify assignment status guards** — any feature that shows, hides, or restricts
   content based on a bus must check `assignmentStatus` against its expected value.

3. **Preserve socket event chain integrity** — edits to `SocketService`, `DataService`,
   or any `listen`/`watch` in a dashboard must not break the stream → UI update path.

4. **Validate Riverpod provider dependencies** — before adding a new provider, confirm
   there is no circular dependency and that invalidation/refresh propagates correctly.

5. **Keep domain models immutable via `copyWith`** — never mutate a `BusModel`,
   `RouteModel`, or `BusLocationModel` directly; always use `.copyWith(...)`.

6. **Test the offline-to-online transition** — any change touching `SocketService` must
   be mentally traced through: disconnect → queue → reconnect → `join_college` → flush.

---

## What the Agent MUST NOT Do

- Do **not** silently set `assignmentStatus = 'accepted'` without the driver explicitly
  accepting via `_handleAcceptAssignment()`
- Do **not** add tracking map access for students with `assignmentStatus != 'accepted'`
- Do **not** use direct Firestore reads for real-time location — always use the
  `SocketService` stream
- Do **not** bypass `PersistenceService` staleness checks when restoring selections
- Do **not** duplicate route polyline rendering logic — always extend `CommonMapView`
  or the shared `MapMarkerHelper`
- Do **not** change ETA or deviation thresholds without documenting the reasoning as
  a comment at the call site

---

## Improvement Focus Areas (What Next)

Every response for a logic-related task MUST end with 3–5 forward-looking improvements
from this list:

- **Assignment reliability**: Notification delivery guarantees when a coordinator
  assigns a bus (push notification fallback if socket is offline)
- **Driver location accuracy**: Kalman filter or accuracy threshold guard before
  emitting `update_location` (reject GPS jitter below threshold)
- **Student ETA display**: Propagate driver ETA string from `DriverLocationState`
  to the student's bus card via a shared socket payload
- **Route adherence scoring**: Calculate a session-level adherence % from deviation
  event count vs. total location updates
- **Multi-bus coordinator view**: Cluster overlapping bus markers on the coordinator
  live map when buses are close together
- **Offline assignment sync**: Queue coordinator-initiated assignments when offline
  and replay on reconnect, matching the existing `_eventQueue` pattern in `SocketService`
- **Stop arrival detection**: Emit a `stop_reached` event when the bus is within
  50 meters of a `RoutePoint` to power real-time student alerts
