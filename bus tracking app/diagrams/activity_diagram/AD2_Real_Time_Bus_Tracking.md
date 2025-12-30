# AD2: Real-Time Bus Tracking Process

**Activity Diagram ID:** AD2  
**Process Name:** Real-Time Bus Tracking  
**Version:** 1.0  
**Date:** 2025-12-29

---

## 1. Purpose

This activity diagram models the real-time bus tracking workflow from the perspective of Students, Teachers, and Parents. It describes how users subscribe to location updates, receive real-time data via WebSocket, and visualize bus positions on an interactive map.

---

## 2. Actors / Roles

| Role                       | Participation                      |
| -------------------------- | ---------------------------------- |
| Student / Teacher / Parent | Views bus location on map          |
| Mobile Application         | Renders map, handles socket events |
| Socket.IO Server           | Manages rooms, broadcasts updates  |
| Driver                     | Provides location data             |

---

## 3. Mermaid Diagram

```mermaid
flowchart TD
    A([Start]) --> B[User opens app after login]
    B --> C[Navigate to Dashboard/Map]
    C --> D{Route assigned?}

    D -- No --> E[Display 'Select route in Profile']
    E --> F([End])

    D -- Yes --> G[Initialize Google Maps]
    G --> H[Establish Socket.IO connection]
    H --> I{Connection successful?}

    I -- No --> J[Display 'Retrying...']
    J --> K[Wait with backoff]
    K --> H

    I -- Yes --> L[Emit joinRoom with routeId]
    L --> M[Socket Server adds to room]
    M --> N[Display map with stops]

    N --> O{Active bus on route?}
    O -- No --> P[Display 'No active buses']
    P --> Q[Wait for bus activity]
    Q --> O

    O -- Yes --> R[/Receive busLocationUpdate/]

    R --> S[Update marker position]
    S --> T[Calculate ETA to stop]
    T --> U[Display ETA on UI]

    U --> V{Bus near user stop?}
    V -- Yes --> W[Display 'Bus approaching!' alert]
    V -- No --> X[Continue monitoring]

    W --> Y{Trip still active?}
    X --> Y

    Y -- Yes --> R
    Y -- No --> Z[Display 'Trip ended']
    Z --> F
```

---

## 4. Notes / Conditions

### Preconditions

- User is authenticated
- User has an assigned route
- At least one bus is active on the route

### Real-Time Interactions

- Location updates every 5 seconds
- Socket.IO for low-latency delivery
- Animated marker movement

### Exceptional Flows

- **Driver Disconnects:** UI shows warning
- **Network Loss:** Reconnection with backoff

---

## 5. Modules / Components Represented

| Component          | Activities                        |
| ------------------ | --------------------------------- |
| Flutter Mobile App | Map rendering, ETA calculation    |
| Socket.IO Client   | Room subscription, event handling |
| Socket.IO Server   | Broadcasting location updates     |
| Google Maps SDK    | Map visualization                 |
