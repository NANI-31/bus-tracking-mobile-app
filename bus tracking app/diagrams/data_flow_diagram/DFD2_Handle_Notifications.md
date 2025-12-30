# DFD2: Handle Notifications (Level 2)

**DFD ID:** DFD4.0  
**Level:** 2 (Explosion of Process 4.0)  
**Process:** Handle Notifications  
**Version:** 1.0  
**Date:** 2025-12-30

---

## 1. Purpose

This Level 2 DFD details the "Handle Notifications" process, explaining how system triggers (proximity, assignment, incident) are transformed into target-specific push notifications via Firebase.

---

## 2. Processes

| Process ID | Process Name       | Description                                                                  |
| ---------- | ------------------ | ---------------------------------------------------------------------------- |
| **4.1**    | Receive Trigger    | Ingests events from other system processes (Tracking, Resources, Incidents). |
| **4.2**    | Determine Audience | Queries database to find which users (tokens) need to be notified.           |
| **4.3**    | Format Payload     | Constructs the specific title, body, and data payload for the message.       |
| **4.4**    | Dispatch to FCM    | Sends the formatted payload to Firebase Cloud Messaging API.                 |
| **4.5**    | Handle Failures    | Manages retries for failed deliveries or invalid tokens.                     |

---

## 3. Data Stores

| ID     | Name         | Contents                                                            |
| ------ | ------------ | ------------------------------------------------------------------- |
| **D1** | User DB      | FCM Tokens, Route Subscriptions.                                    |
| **D6** | Unsent Queue | Temporary store for failed messages involving non-transient errors. |

---

## 4. Mermaid Diagram

```mermaid
flowchart TB
    %% Inputs
    TrackingSys((Tracking \n System))
    AdminSys((Admin \n System))

    %% Processes
    P4_1((4.1 \n Receive \n Trigger))
    P4_2((4.2 \n Determine \n Audience))
    P4_3((4.3 \n Format \n Payload))
    P4_4((4.4 \n Dispatch \n to FCM))
    P4_5((4.5 \n Handle \n Failures))

    %% Stores
    D1[(D1 \n User DB)]

    %% External
    FCM[Firebase FCM]

    %% Flows
    TrackingSys -->|Proximity Event| P4_1
    AdminSys -->|Assignment Event| P4_1

    P4_1 -->|Event Info| P4_2
    P4_1 -->|Event Type| P4_3

    P4_2 <-->|Query Subscriptions| D1
    P4_2 -->|Target Tokens| P4_4

    P4_3 -->|Message Body| P4_4

    P4_4 -->|API Request| FCM
    FCM -->|Response| P4_5

    P4_5 -->|Invalid Token| D1
    P4_5 -->|Success| Log[Log Success]
```

---

## 5. Notes / Considerations

- **Batching:** Process 4.4 may batch tokens for efficiency (multicast).
- **Token Management:** Process 4.5 is crucial for maintaining a clean D1 User DB by removing stale tokens (Invalid Token response).
- **Personalization:** Message content in 4.3 is localized based on user preference found in D1.
