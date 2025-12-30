# Entity-Relationship (ER) Analysis - College Bus Tracking System

This document provides a deep analysis of the project's data models, identifying key entities, their attributes, and their relationships.

## Entities and Attributes

### 1. User

- **Primary Key**: `_id` (String)
- **Attributes**:
  - `fullName`: string
  - `email`: string (unique)
  - `role`: enum (student, teacher, driver, busCoordinator, admin, parent)
  - `collegeId`: ObjectId (ref: College)
  - `phoneNumber`: string
  - `approved`: boolean
  - `routeId`: ObjectId (ref: Route)
  - `stopId`: string
  - `stopName`: string
  - `fcmToken`: string
  - `language`: enum (en, hi, te)

### 2. College

- **Primary Key**: `_id` (ObjectId)
- **Attributes**:
  - `name`: string
  - `allowedDomains`: string[]
  - `verified`: boolean
  - `busNumbers`: string[]
  - `createdBy`: string

### 3. Bus

- **Primary Key**: `_id` (ObjectId)
- **Attributes**:
  - `busNumber`: string
  - `driverId`: string (ref: User)
  - `routeId`: ObjectId (ref: Route)
  - `collegeId`: ObjectId (ref: College)
  - `isActive`: boolean
  - `status`: enum (on-time, delayed, not-running)
  - `assignmentStatus`: enum (unassigned, pending, accepted)

### 4. Route

- **Primary Key**: `_id` (ObjectId)
- **Attributes**:
  - `routeName`: string
  - `routeType`: enum (pickup, drop)
  - `startPoint`: { name, location }
  - `endPoint`: { name, location }
  - `stopPoints`: Array of { name, location }
  - `collegeId`: ObjectId (ref: College)
  - `createdBy`: string (ref: User)

### 5. Schedule

- **Primary Key**: `_id` (ObjectId)
- **Attributes**:
  - `routeId`: ObjectId (ref: Route)
  - `busId`: ObjectId (ref: Bus)
  - `shift`: enum (1st, 2nd)
  - `stopSchedules`: Array of { stopName, arrivalTime, departureTime }
  - `collegeId`: ObjectId (ref: College)

### 6. Incident

- **Primary Key**: `_id` (ObjectId)
- **Attributes**:
  - `collegeId`: string (ref: College)
  - `busId`: string (ref: Bus)
  - `driverId`: string (ref: User)
  - `reporterId`: string (ref: User)
  - `type`: enum (accident, breakdown, delay, behavior, other)
  - `severity`: enum (low, medium, high, critical)
  - `status`: enum (open, investigating, resolved)

### 7. Notification

- **Primary Key**: `_id` (ObjectId)
- **Attributes**:
  - `senderId`: string (ref: User)
  - `receiverId`: string (ref: User)
  - `message`: string
  - `type`: string
  - `isRead`: boolean

---

## Relationships and Cardinality

| Relationship | Entities             | Cardinality | Description                                       |
| ------------ | -------------------- | ----------- | ------------------------------------------------- |
| Belongs To   | User -> College      | N : 1       | Many users belong to one college.                 |
| Belongs To   | Bus -> College       | N : 1       | Many buses belong to one college.                 |
| Belongs To   | Route -> College     | N : 1       | Many routes belong to one college.                |
| Assigned To  | Bus -> User (Driver) | 1 : 1       | One bus is typically assigned to one driver.      |
| Assigned To  | Bus -> Route         | N : 1       | Multiple buses can serve the same route.          |
| Assigned To  | User -> Route        | N : 1       | Many students/teachers are assigned to one route. |
| Schedules    | Schedule -> Route    | N : 1       | One route can have multiple schedules (shifts).   |
| Schedules    | Schedule -> Bus      | N : 1       | One bus can have multiple schedules.              |
| Tracks       | BusLocation -> Bus   | N : 1       | Many location updates for one bus.                |
| Reports      | Incident -> User     | N : 1       | One user can report multiple incidents.           |
| Sends        | Notification -> User | N : 1       | One user can receive multiple notifications.      |

---

-> rule 10 is executed.
