# PKG4: External Libraries & Dependencies

**Package Diagram ID:** PKG4  
**Module Group:** External Libraries  
**Version:** 1.0  
**Date:** 2025-12-30

---

## 1. Purpose

This package diagram illustrates the dependencies of the Mobile Application and Backend Server on external open-source libraries and SDKs, highlighting key technology choices.

---

## 2. Packages / Modules

| Package Group  | Environment  | Key Libraries                                                                      |
| -------------- | ------------ | ---------------------------------------------------------------------------------- |
| Mobile Clients | Flutter/Dart | `google_maps_flutter`, `socket_io_client`, `firebase_messaging`, `provider`, `dio` |
| Server Core    | Node.js      | `express`, `socket.io`, `mongoose`, `firebase-admin`                               |
| Utilities      | Shared       | `moment` / `intl` (Date handling), `bcrypt` (Security)                             |

---

## 3. Mermaid Diagram

```mermaid
flowchart TB
    subgraph MobileApp["📱 Flutter Mobile App"]
        MobileCode["Application Code"]

        subgraph FlutterLibs["Flutter Packages (pub.dev)"]
            MapsSDK["google_maps_flutter"]
            SocketClient["socket_io_client"]
            FCMClient["firebase_messaging"]
            HttpLib["dio"]
            StateLib["provider"]
            StorageLib["flutter_secure_storage"]
            LocLib["geolocator"]
        end
    end

    subgraph BackendServer["⚙️ Node.js Backend"]
        ServerCode["Server Code"]

        subgraph NodeLibs["NPM Packages"]
            Express["express"]
            SocketServer["socket.io"]
            Mongoose["mongoose"]
            FirebaseAdmin["firebase-admin"]
            AuthLib["jsonwebtoken"]
            Cors["cors"]
        end
    end

    MobileCode --> MapsSDK
    MobileCode --> SocketClient
    MobileCode --> FCMClient
    MobileCode --> HttpLib
    MobileCode --> StateLib
    MobileCode --> StorageLib
    MobileCode --> LocLib

    ServerCode --> Express
    ServerCode --> SocketServer
    ServerCode --> Mongoose
    ServerCode --> FirebaseAdmin
    ServerCode --> AuthLib
    ServerCode --> Cors
```

---

## 4. Dependencies

| Library               | Usage                                           |
| --------------------- | ----------------------------------------------- |
| `google_maps_flutter` | Rendering maps and markers on mobile            |
| `socket_io_client`    | Real-time WebSocket client for location updates |
| `mongoose`            | ODM for MongoDB interaction                     |
| `firebase-admin`      | Sending push notifications from backend         |

---

## 5. Actors / Roles

| Component             | Role Interaction              |
| --------------------- | ----------------------------- |
| `geolocator`          | Driver (tracks location)      |
| `firebase_messaging`  | All Users (receives alerts)   |
| `google_maps_flutter` | All Users (views visual data) |

---

## 6. Notes / Considerations

- **Version Management:** defined in `pubspec.yaml` (Mobile) and `package.json` (Backend).
- **Security:** key libraries (`jsonwebtoken`, `flutter_secure_storage`) handle sensitive data.
