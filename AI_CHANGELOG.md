# AI Changelog — Upasthit Bus Tracking System

> **AI INSTRUCTION**: Read this file AFTER reading `AI_PROJECT_INDEX.md`. This file records all significant code changes in reverse chronological order. Each entry documents what changed, why, and which files were affected. Append a new entry whenever significant changes are made — do NOT overwrite existing entries.

---

## Format for New Entries

```
## [2026-07-31] — Custom Split Border for Map Search Bar

**Type**: Feature / UI
**Summary**: Ported the custom split border painter from the bottom navigation bar (curved_bottom_nav_bar.dart) into GlassCard and GlassMorphicContainer via GlassSplitBorderPainter. Draws a dual-gradient specular highlight path along the top-left edge (with rcToPoint smooth corner rounding) and a bottom-right gradient reflection path. This gives search bars on maps (e.g., student map tab, location picker) the exact same premium split-border design as the bottom navigation bar.

### Files Changed
- mobile/lib/shared/widgets/glass_card.dart — Created GlassSplitBorderPainter and enabled useSplitBorder by default on GlassCard
- mobile/lib/shared/widgets/glass_morphic_container.dart — Added useSplitBorder parameter supporting GlassSplitBorderPainter
- mobile/lib/features/coordinator/presentation/modules/location_picker_screen.dart — Enabled useSplitBorder: true on map search bar container

---

## [2026-07-31] — Fix Glass Map Search Bar Border Corner Clipping

**Type**: Bug Fix (UI)
**Summary**: Fixed bevelled / flat corner cut-off artifacts on the rounded borders of glass search bars and glassmorphic containers. The root cause was Border.all(width: 1.5) being placed inside ClipRRect(borderRadius: R). Because Flutter strokes a border centered on the boundary, ClipRRect clipped off the outer half of the stroke and truncated the corner arcs diagonally. Solved by separating the outer border container from the inner ClipRRect backdrop blur layer across GlassCard and GlassMorphicContainer. Also set enabledBorder and ocusedBorder to InputBorder.none on the student map search field.

### Files Changed
- mobile/lib/shared/widgets/glass_card.dart — Placed aseDecoration.border on outer Container outside ClipRRect
- mobile/lib/shared/widgets/glass_morphic_container.dart — Separated uildBackgroundFill() inside ClipRRect from uildBorderOverlay() on top
- mobile/lib/features/student/presentation/tabs/student_map_tab.dart — Added enabledBorder: InputBorder.none and ocusedBorder: InputBorder.none to search TextField

---

## [YYYY-MM-DD] — <Short Title>

**Type**: Feature | Bug Fix | Refactor | Architecture | Database | API | Breaking Change | Config
**Summary**: One paragraph describing what changed and why.

### Files Changed
- `path/to/file.dart` — what changed
- `path/to/another.ts` — what changed

### APIs Changed (if any)
- New: `METHOD /endpoint` — description
- Modified: `METHOD /endpoint` — what changed
- Removed: `METHOD /endpoint` — why removed

### Database Changes (if any)
- Model/field additions or removals

### Breaking Changes (if any)
- Describe any breaking changes and migration steps

### Notes for Future AI Sessions
- Key decisions or gotchas to be aware of
```

---

## [2026-07-25] — AI Knowledge System Created

**Type**: Documentation / Architecture
**Summary**: Created `AI_PROJECT_INDEX.md` and `AI_CHANGELOG.md` in the project root to serve as permanent AI knowledge files. These files allow future AI sessions to understand the full project architecture without scanning the entire codebase first. The index covers all four sub-applications (Flutter mobile, React client, Express server, .agents/rules), their architecture, folder structure, important files, feature map, API map, state management, database models, navigation, configuration, reusable components, utilities, services, middleware, business logic, dependency chains, cross-references, development rules, and coding conventions.

### Files Changed
- `AI_PROJECT_INDEX.md` [NEW] — Comprehensive project knowledge index
- `AI_CHANGELOG.md` [NEW] — This change history file

### Notes for Future AI Sessions
- Read AI_PROJECT_INDEX.md before any source file
- The project app name is **Upasthit**
- Always respect rules in `.agents/AGENTS.md` (no git push) and `.agents/rules/Bus-logic.md` (assignment lifecycle + socket rules)

---

## [2026-07-24] — Route Polyline Trimming Fix (All Tracking Maps)

**Type**: Bug Fix
**Summary**: The route polyline was not trimming correctly at the bus position. The old code found the nearest *discrete point* in the polyline array via `sublist(idx)`. When the bus was mid-segment between two sparse route points, the line extended 20-50 m past the bus icon or started too far behind it. Additionally, `_updateRoutePolyline` only fired at GPS ticks (~3 s), so the polyline stayed frozen during 60fps animation — appearing misaligned with the animated bus marker. Fixed by: (1) adding `trimPolylineAtBus()` using perpendicular segment projection (geometric foot on nearest segment), so the trimmed line always starts exactly AT the bus; (2) throttling the polyline update to every 6th animation frame (~10fps) so it trims in real-time as the bus animates, without 60fps setState overhead.

### Files Changed
- `mobile/lib/core/utils/route_math_utils.dart` — Added `trimPolylineAtBus(LatLng busPos, List<LatLng> points)` using `distanceToSegment` segment projection; returns `[projectedFoot, ...remainingPoints]`
- `mobile/lib/shared/widgets/maps/live_bus_map.dart` — Replaced `sublist(closestIdx)` with `trimPolylineAtBus()`; added `_polylineFrameCount` throttle in AnimationController listener (every 6th frame); removed unused private `_findClosestPointIndex` method
- `mobile/lib/features/driver/presentation/widgets/driver_live_tracking_tab.dart` — Replaced `sublist(closestIdx)` with `trimPolylineAtBus()` in `_buildPolylines()`
- `mobile/lib/features/teacher/presentation/tabs/teacher_live_tracking_tab.dart` — Replaced `sublist(closestIdx)` with `trimPolylineAtBus()` in `_buildPolylines()`

### Notes for Future AI Sessions
- `trimPolylineAtBus` is the canonical polyline trimming function — always use it; never sublist by index
- The 6-frame throttle means polyline updates at ~10fps (60fps / 6); this is intentional to avoid 60fps setState cost
- `distanceToSegment` computes perpendicular distance using parameter t (clamped to [0,1]); the projected foot at t is the trim start point

---

## [2026-07-24] — Server GPS Outlier Guard

**Type**: Bug Fix / Performance
**Summary**: Added server-side GPS outlier rejection to prevent phantom GPS positions (provider hiccups, cold-start noise) from being broadcast to students and coordinators. Implemented Haversine distance check between consecutive GPS fixes per bus. Fixes > 500 m are silently rejected and not broadcast. Threshold: 500 m gives a 2.5× margin over the max legitimate movement at 80 km/h in a 3 s socket interval (~200 m). State tracked in `lastKnownPositions` Map keyed by busId (persists across socket reconnects within the same server process).

### Files Changed
- `server/src/socket/handlers/location.ts` — Added `haversineMeters()` helper; `lastKnownPositions` Map; outlier guard block before throttle logic; `OUTLIER_THRESHOLD_M = 500`

### Notes for Future AI Sessions
- The outlier guard is server-side only; the client also has a 500m guard in `LiveBusMap._handleLocationUpdate()`
- `lastKnownPositions` is in-memory — it resets on server restart, meaning the first fix after restart is always accepted regardless of position

---

## [2026-07-23] — Offline Route Directions Cache

**Type**: Feature
**Summary**: Added offline fallback for route directions — the latest calculated `DirectionsResult` (polylines + legs) is now cached in `SharedPreferences` via `PersistenceService`. When the device loses internet and `DirectionsService.fetchDirections()` fails, the cached result is used to keep stop points and polylines visible on the map. Cache key: `route_directions_<routeId>`. Cache is written immediately after a successful fetch and cleared on logout.

### Files Changed
- `mobile/lib/core/services/persistence_service.dart` — Added `getRouteDirections(key)`, `setRouteDirections(key, result)`, `clearRouteDirectionsCache()` methods; uses `_keyRouteDirectionsPrefix = 'route_directions_'`
- `mobile/lib/core/services/directions_service.dart` — Modified to check cache before API call; write to cache on successful fetch
- `mobile/lib/core/services/directions_result.dart` — Added `toMap()` / `fromMap()` serialization methods for SharedPreferences storage

### Notes for Future AI Sessions
- Cache is per-routeId string key: `route_directions_<routeId>`
- `DirectionsResult.toMap()` serializes polylinePoints as a list of {lat, lng} maps
- Cache is NOT invalidated when the route is updated — caller must call `clearRouteDirectionsCache()` after route edits

---

## [2026-07-22] — Route Stop Order Fix for Drop Trip Direction

**Type**: Bug Fix
**Summary**: When the coordinator selected "drop" as the trip direction, the stop points on the student/driver screen were still showing in pickup order (suburbs → college). Fixed by implementing `RouteModel.getOrderedStops(tripType)` which returns stops in the correct direction: pickup=[startPoint, ...stopPoints, endPoint]; drop=[endPoint, ...stopPoints.reversed, startPoint]. Updated all map widgets and the stop list UI to call this method instead of accessing `route.stopPoints` directly.

### Files Changed
- `mobile/lib/features/route/domain/route_model.dart` — Added `getOrderedStops(String tripType)` method
- `mobile/lib/shared/widgets/maps/live_bus_map.dart` — Uses `getOrderedStops(tripType)` for stop marker placement
- `mobile/lib/features/driver/presentation/widgets/driver_live_tracking_tab.dart` — Uses `getOrderedStops(tripType)` for stop markers and polyline direction
- `mobile/lib/features/teacher/presentation/tabs/teacher_live_tracking_tab.dart` — Same fix
- `mobile/lib/shared/widgets/maps/trip_progress_sheet.dart` — Uses ordered stops for stop list display
- `mobile/lib/features/driver/presentation/widgets/live_tracking_control_panel.dart` — Uses ordered stops for stop list panel

### Notes for Future AI Sessions
- ALWAYS use `route.getOrderedStops(tripType)` — never access `route.stopPoints` directly in map/tracking widgets
- `tripType` comes from the bus's current trip configuration (set by coordinator at assignment time)

---

## [2026-07-22] — Teacher Override Screen UI: White Space Fix

**Type**: Bug Fix (UI)
**Summary**: Removed duplicate `SizedBox` bottom padding on the teacher override screen that caused excessive white space below the stop list and trip complete button panel.

### Files Changed
- `mobile/lib/features/teacher/presentation/teacher_dashboard.dart` — Removed redundant `SizedBox` height clearance at bottom of control panel widget

---

## [2026-07-22] — Driver Screen: Next Stop Widget Repositioning

**Type**: Bug Fix (UI)
**Summary**: Moved the "Next: S1 - 1 min" ETA widget to appear above the SOS modal button on the driver live tracking screen.

### Files Changed
- `mobile/lib/features/driver/presentation/widgets/driver_live_tracking_tab.dart` — Reordered widget stack: ETA card now positioned above SOS button in the column layout

---

## [2026-07-14] — Content Security Policy Fix (Server Dashboard)

**Type**: Bug Fix
**Summary**: Fixed CSP violations on the server's public `index.html` dashboard page. Inline scripts were blocked by the default Helmet CSP. Updated `app.ts` to add `'unsafe-inline'` and `'unsafe-eval'` to `scriptSrc` directives, and added Google Maps domains to `imgSrc` and `connectSrc`.

### Files Changed
- `server/src/app.ts` — Updated Helmet CSP directives: added `'unsafe-inline'`, `'unsafe-eval'` to scriptSrc; added Google Maps + gstatic domains to imgSrc and connectSrc

### Notes for Future AI Sessions
- The CSP in app.ts is permissive for development; tighten for production by replacing 'unsafe-inline' with specific nonces or hashes

---

## [2026-07-14] — Teacher Override "Too Many Requests" Error Investigation

**Type**: Investigation / Known Issue
**Summary**: When a teacher requests a bus override and the coordinator approves it, the teacher screen showed "Too many requests, please try again" in red. Root cause: the teacher screen was making multiple rapid API calls to check override status after approval, hitting the 300 req/min global rate limiter. The rate limiter in `app.ts` applies to all `/api/v1` routes. The fix requires either increasing the rate limit for specific endpoints or implementing debouncing on the teacher-side polling.

### Files Changed
- None (investigation only — fix deferred)

### Notes for Future AI Sessions
- Rate limiter: `windowMs: 60*1000, max: 300` in `app.ts` — this is the source of the 429 error
- Teacher screen polls too frequently after override approval — add debounce or exponential backoff
- Consider adding a specific, higher rate limit for the override-check endpoint

---

## [2026-07-12] — Student Map: Route Line Direction Consistency

**Type**: Bug Fix
**Summary**: In the student map's live tracking view, the route line shown to the student differed from the driver's line when both devices were at the same location. Root cause: student LiveBusMap was building the full polyline from Route.directions but not accounting for tripType direction, while driver was reversing for drop trips. Fixed by ensuring LiveBusMap also calls `getOrderedStops(tripType)` and uses the correct polyline start/end direction.

### Files Changed
- `mobile/lib/shared/widgets/maps/live_bus_map.dart` — Added tripType-aware polyline rendering; student and driver now see the same line

---

## [2026-07-11] — Initial Codebase Analysis

**Type**: Architecture / Documentation
**Summary**: Initial full-project analysis documenting the existing architecture. Identified key patterns: Riverpod + Repository for Flutter, Redux Toolkit for React, MVC + Service for Express. Documented the bus assignment lifecycle, real-time socket flows, and map rendering pipeline.

### Files Changed
- `codebase_analysis_report.md` — Initial analysis document (in project root)
- `tracking_improvements_report.md` — Tracking-specific improvements report

### Notes for Future AI Sessions
- These reports in the project root are preliminary analysis documents — AI_PROJECT_INDEX.md is the canonical, maintained reference

---

*End of changelog. Append new entries above this line following the entry format.*
