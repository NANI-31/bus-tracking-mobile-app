# AD3: Driver Trip Management Process

**Activity Diagram ID:** AD3  
**Process Name:** Driver Trip Management  
**Version:** 1.0  
**Date:** 2025-12-29

---

## 1. Purpose

This activity diagram models the complete trip workflow from the Driver's perspective, from starting a trip to ending it. It covers location broadcasting, delay handling, and SOS scenarios.

---

## 2. Actors / Roles

| Role              | Participation                              |
| ----------------- | ------------------------------------------ |
| Driver            | Operates bus, controls trip lifecycle      |
| Driver Mobile App | Tracks location, communicates with backend |
| Socket.IO Server  | Receives and broadcasts location           |
| Coordinator       | Receives alerts and monitors trips         |

---

## 3. Mermaid Diagram

```mermaid
flowchart TD
    A([Start]) --> B[Driver logs in]
    B --> C[View Dashboard]
    C --> D{Assignment exists?}

    D -- No --> E[Display 'No bus assigned']
    E --> F([End])

    D -- Yes --> G[Display assigned bus and route]
    G --> H[Driver taps 'Start Trip']
    H --> I[Request location permission]
    I --> J{Permission granted?}

    J -- No --> K[Display 'Location required']
    K --> I

    J -- Yes --> L[Get current GPS position]
    L --> M[Emit tripStarted via Socket.IO]
    M --> N[Backend updates Bus status to on-time]
    N --> O[Log to History collection]
    O --> P[Broadcast trip start to subscribers]
    P --> Q[Start foreground location service]
    Q --> R[Display 'Trip Active' UI]

    R --> S[/GPS update every 5s/]
    S --> T[Emit updateLocation]
    T --> U[Backend persists to BusLocation]
    U --> V[Broadcast to route room]

    V --> W{ETA > scheduled?}
    W -- Yes --> X[Update status to delayed]
    W -- No --> Y[Maintain on-time status]

    X --> Z{SOS triggered?}
    Y --> Z

    Z -- Yes --> AA[Emit sosAlert]
    AA --> AB[Send high-priority FCM to Coordinators]
    AB --> AC[Coordinator receives and responds]
    AC --> AD{Trip continues?}

    Z -- No --> AD

    AD -- Yes --> S
    AD -- No --> AE[Driver taps 'End Trip']

    AE --> AF[Emit tripEnded]
    AF --> AG[Update Bus status to not-running]
    AG --> AH[Log trip completion]
    AH --> AI[Update BusAssignmentLog]
    AI --> AJ[Stop foreground service]
    AJ --> AK[Display trip summary]
    AK --> F
```

---

## 4. Notes / Conditions

### Preconditions

- Driver is authenticated with accepted assignment
- Device has GPS capability

### Postconditions

- Trip data logged in database
- All subscribers received real-time updates

### Exceptional Flows

- **GPS Lost:** Cached last position used temporarily
- **Network Down:** Location synced on reconnect
- **App Crash:** Foreground service continues

---

## 5. Modules / Components Represented

| Component               | Activities                         |
| ----------------------- | ---------------------------------- |
| Flutter Driver App      | Trip control UI, location tracking |
| Device Location Service | GPS coordinates                    |
| Socket.IO               | Real-time communication            |
| MongoDB                 | Trip logging                       |
| FCM                     | SOS notifications                  |
