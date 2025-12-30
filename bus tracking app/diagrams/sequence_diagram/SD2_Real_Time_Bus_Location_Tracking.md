# SD2: Real-Time Bus Location Tracking

**Sequence Diagram ID:** SD2  
**Scenario Name:** Real-Time Bus Location Tracking  
**Version:** 1.0  
**Date:** 2025-12-29

---

## 1. Purpose

This sequence diagram models the core real-time functionality of the system: how a Driver's location is broadcast to subscribed Students/Teachers via WebSocket (Socket.IO). This is the most critical interaction pattern in the system, demonstrating bidirectional real-time communication.

---

## 2. Actors & Objects

| Participant  | Type     | Description                              |
| ------------ | -------- | ---------------------------------------- |
| Driver       | Actor    | Bus operator with active trip            |
| DriverApp    | System   | Driver's Flutter mobile app              |
| StudentApp   | System   | Student's Flutter mobile app             |
| SocketServer | Backend  | Socket.IO server integrated with Express |
| LocationDB   | Database | BusLocation collection in MongoDB        |
| GoogleMaps   | External | Google Maps SDK on client                |

---

## 3. Mermaid Diagram

```mermaid
sequenceDiagram
    autonumber
    participant Driver
    participant DriverApp as Driver App
    participant SocketServer as Socket.IO Server
    participant LocationDB as BusLocation (MongoDB)
    participant StudentApp as Student App
    participant GoogleMaps as Google Maps SDK

    Note over Driver, GoogleMaps: Initial Connection Phase

    DriverApp->>SocketServer: connect() with auth token
    SocketServer->>SocketServer: Validate JWT
    SocketServer-->>DriverApp: Connection acknowledged

    StudentApp->>SocketServer: connect() with auth token
    SocketServer-->>StudentApp: Connection acknowledged
    StudentApp->>SocketServer: emit("joinRoom", {routeId})
    SocketServer->>SocketServer: Add client to route room
    SocketServer-->>StudentApp: Room joined confirmation

    Note over Driver, GoogleMaps: Trip Active - Location Broadcasting

    loop Every 5 seconds during active trip
        Driver->>DriverApp: GPS position update
        DriverApp->>DriverApp: Get current location
        DriverApp->>SocketServer: emit("updateLocation", {busId, lat, lng, speed, heading})

        par Persist to Database
            SocketServer->>LocationDB: insertOne({busId, location, timestamp})
            LocationDB-->>SocketServer: Write acknowledged
        and Broadcast to Room
            SocketServer->>StudentApp: emit("busLocationUpdate", {busId, lat, lng, speed})
        end

        StudentApp->>GoogleMaps: Update marker position
        GoogleMaps-->>StudentApp: Marker animated to new position
    end

    Note over Driver, GoogleMaps: Student Views Updated Map

    StudentApp-->>StudentApp: Calculate ETA based on speed & distance
```

---

## 4. Alternative Flows / Exceptions

| Scenario           | Handling                                                                                                 |
| ------------------ | -------------------------------------------------------------------------------------------------------- |
| Driver Disconnects | SocketServer emits "driverDisconnected" to room; StudentApp shows "Bus tracking temporarily unavailable" |
| Student Reconnects | On reconnect, StudentApp re-emits "joinRoom" to resubscribe                                              |
| High Latency       | Client-side interpolation smooths marker movement between updates                                        |

---

## 5. Modules / Components Represented

| Component      | File/Location                                                                    |
| -------------- | -------------------------------------------------------------------------------- |
| Driver App     | `lib/screens/driver/driver_dashboard.dart`, `lib/services/location_service.dart` |
| Student App    | `lib/screens/student/student_dashboard.dart`                                     |
| Socket Service | `lib/services/socket_service.dart`                                               |
| Socket Server  | `src/socket.ts`                                                                  |
| Location Model | `src/models/Bus.ts` (BusLocation)                                                |

---

## 6. Notes / Considerations

- **Real-Time Performance:** Location updates occur every 5 seconds to balance battery consumption and tracking accuracy.
- **Concurrency:** The `par` block shows parallel operations—database persistence and client broadcast happen concurrently.
- **Room-Based Routing:** Only students subscribed to a specific route receive updates, reducing unnecessary network traffic.
