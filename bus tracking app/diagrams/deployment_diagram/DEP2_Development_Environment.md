# DEP2: Development Environment

**Deployment Diagram ID:** DEP2  
**Scenario Name:** Development Environment  
**Version:** 1.0  
**Date:** 2025-12-29

---

## 1. Purpose

This deployment diagram illustrates the local development environment setup, showing how developers run and test the system on their workstations.

---

## 2. Nodes / Devices

| Node                  | Type    | Description                   |
| --------------------- | ------- | ----------------------------- |
| Developer Workstation | PC/Mac  | Development machine           |
| Android Emulator      | Virtual | Android device emulator       |
| iOS Simulator         | Virtual | iOS device simulator          |
| Physical Device       | Mobile  | Test device connected via USB |
| Local MongoDB         | Local   | Local database instance       |

---

## 3. Software Components on Nodes

| Node                  | Components                                    |
| --------------------- | --------------------------------------------- |
| Developer Workstation | VS Code, Node.js, Flutter SDK, Android Studio |
| Android Emulator      | Flutter Debug App, Chrome DevTools            |
| iOS Simulator         | Flutter Debug App                             |
| Physical Device       | Flutter Debug App (hot reload enabled)        |
| Local MongoDB         | MongoDB Community Server                      |

---

## 4. Mermaid Diagram

```mermaid
flowchart TB
    subgraph DevMachine["💻 Developer Workstation"]
        VSCode["VS Code\n+ Flutter Extension"]
        Terminal["Terminal"]

        subgraph Backend["Backend Development"]
            NodeDev["Node.js\n(npm run dev)"]
            SocketDev["Socket.IO\n(localhost:3000)"]
        end

        subgraph DBLocal["Local Database"]
            MongoLocal[("MongoDB\nlocalhost:27017")]
        end
    end

    subgraph Emulators["📱 Emulators / Simulators"]
        AndroidEmu["Android Emulator\n(flutter run)"]
        iOSSim["iOS Simulator\n(flutter run)"]
    end

    subgraph PhysicalDev["📲 Physical Devices"]
        AndroidPhone["Android Phone\n(USB Debug)"]
        iPhone["iPhone\n(USB Debug)"]
    end

    subgraph ExternalDev["🌐 External Services (Dev)"]
        FirebaseDev["Firebase\n(Development Project)"]
        MapsDev["Google Maps\n(Dev API Key)"]
    end

    VSCode --> Terminal
    Terminal --> NodeDev
    NodeDev --> MongoLocal
    SocketDev --> MongoLocal

    VSCode --> AndroidEmu
    VSCode --> iOSSim
    VSCode --> AndroidPhone
    VSCode --> iPhone

    AndroidEmu <--> NodeDev
    iOSSim <--> NodeDev
    AndroidPhone <--> NodeDev
    iPhone <--> NodeDev

    AndroidEmu --> FirebaseDev
    AndroidEmu --> MapsDev
```

---

## 5. Actors / Roles

| Node                  | Developer Role                      |
| --------------------- | ----------------------------------- |
| Developer Workstation | Backend Developer, Mobile Developer |
| Emulators             | Testing and debugging               |
| Physical Devices      | Real device testing                 |

---

## 6. Notes / Considerations

- **Hot Reload:** Flutter enables instant code changes on emulators/devices.
- **Environment Variables:** `.env` file configures local vs production settings.
- **Port Configuration:** Backend runs on `localhost:3000`, MongoDB on `27017`.
- **Firebase:** Use separate Firebase project for development.
