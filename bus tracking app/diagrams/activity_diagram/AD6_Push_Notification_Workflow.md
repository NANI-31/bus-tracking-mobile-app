# AD6: Push Notification Delivery Workflow

**Activity Diagram ID:** AD6  
**Process Name:** Push Notification Delivery  
**Version:** 1.0  
**Date:** 2025-12-29

---

## 1. Purpose

This activity diagram models the end-to-end workflow for generating, sending, and receiving push notifications within the system.

---

## 2. Actors / Roles

| Role               | Participation                     |
| ------------------ | --------------------------------- |
| System Event       | Initiates notification            |
| Backend Server     | Constructs and sends notification |
| Firebase FCM       | Delivers to devices               |
| Mobile Application | Receives and displays             |
| User (All Roles)   | Views notification                |

---

## 3. Mermaid Diagram

```mermaid
flowchart TD
    A([Start - System Event]) --> B[Identify notification type]
    B --> C[Identify target recipients]
    C --> D[Query User collection for FCM tokens]
    D --> E{Recipients found?}

    E -- No --> F[Log 'No recipients']
    F --> G([End])

    E -- Yes --> H[Build notification payload]
    H --> I[Build data payload]
    I --> J{Critical notification?}

    J -- Yes --> K[Set high priority]
    J -- No --> L[Set normal priority]

    K --> M[/For each FCM token/]
    L --> M

    M --> N[Send to Firebase FCM]
    N --> O{Delivery successful?}

    O -- Yes --> P[Log message ID]
    O -- No --> Q{Error type?}

    Q -- Invalid Token --> R[Remove stale token from User]
    Q -- Transient Error --> S[Queue for retry]
    Q -- Quota Exceeded --> T[Log and skip]

    R --> U[Create Notification document]
    S --> U
    T --> U
    P --> U

    U --> V[FCM delivers to device]
    V --> W{App state?}

    W -- Background --> X[Display system notification]
    W -- Foreground --> Y[Display in-app banner]

    X --> Z[User taps notification]
    Y --> Z

    Z --> AA[Parse data payload]
    AA --> AB[Navigate to relevant screen]
    AB --> AC[Send read receipt to backend]
    AC --> AD[Mark notification as read]
    AD --> G
```

---

## 4. Notes / Conditions

### Notification Types

| Type                | Trigger            | Priority |
| ------------------- | ------------------ | -------- |
| `bus_arriving`      | Bus proximity      | High     |
| `assignment_update` | New assignment     | High     |
| `incident`          | Incident reported  | High     |
| `trip_status`       | Trip started/ended | Normal   |

### Retry Logic

- Max 3 retries with exponential backoff
- Failed after retries: log and alert admin

---

## 5. Modules / Components Represented

| Component          | Activities                              |
| ------------------ | --------------------------------------- |
| Node.js Backend    | Payload construction, FCM communication |
| Firebase Admin SDK | Message sending                         |
| Firebase FCM       | Delivery                                |
| Flutter Mobile App | Display and interaction                 |
| MongoDB            | Notification logging                    |
