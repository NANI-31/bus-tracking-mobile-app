# UML Diagrams - Master Index

**Project:** College Bus Tracking System  
**Total Diagrams:** 40  
**Generated:** 2025-12-29

---

## 📊 Entity-Relationship Diagrams

| ID  | Name                                                                             | Description                           |
| --- | -------------------------------------------------------------------------------- | ------------------------------------- |
| ER1 | [ER_College_Bus_Tracking_System](./er_diagram/ER_College_Bus_Tracking_System.md) | Entity relationships with cardinality |

---

## 🌊 Data Flow Diagrams (DFD)

| ID   | Name                                                                               | Description        |
| ---- | ---------------------------------------------------------------------------------- | ------------------ |
| DFD0 | [Context Diagram (Level 0)](./data_flow_diagram/DFD0_Context_Diagram.md)           | System boundaries  |
| DFD1 | [Main Processes (Level 1)](./data_flow_diagram/DFD1_Main_Processes.md)             | Core data flows    |
| DFD2 | [Track Live Buses (Level 2)](./data_flow_diagram/DFD2_Track_Live_Buses.md)         | Detailed tracking  |
| DFD2 | [Handle Notifications (Level 2)](./data_flow_diagram/DFD2_Handle_Notifications.md) | Notification logic |

---

## 🏛️ API Architecture Diagrams

| ID          | Name                                                                       | Description         |
| ----------- | -------------------------------------------------------------------------- | ------------------- |
| API_ARCH_01 | [API Architecture Diagram](./api_architecture/API_Architecture_Diagram.md) | Client-Server Flows |

---

## 🔐 Security Flow Diagrams

| ID           | Name                                                                            | Description        |
| ------------ | ------------------------------------------------------------------------------- | ------------------ |
| AUTH_FLOW_01 | [Authentication Flow Diagram](./auth_flow/Authentication_Authorization_Flow.md) | Login & RBAC Logic |

---

## ⚡ Real-Time Architecture Diagrams

| ID         | Name                                                                                                             | Description           |
| ---------- | ---------------------------------------------------------------------------------------------------------------- | --------------------- |
| RT_ARCH_01 | [Real-Time Architecture Diagram](./realtime_architecture_diagram/RT_Architecture_College_Bus_Tracking_System.md) | Socket.io Event logic |

---

## 📋 Use Case Diagrams

| ID  | Name                                                                               | Description           |
| --- | ---------------------------------------------------------------------------------- | --------------------- |
| UC1 | [User Authentication](./use_case_diagram/UC1_User_Authentication.md)               | Login, Register, OTP  |
| UC2 | [View Live Bus Location](./use_case_diagram/UC2_View_Live_Bus_Location.md)         | Real-time tracking    |
| UC3 | [Start/End Trip](./use_case_diagram/UC3_Start_End_Trip.md)                         | Driver trip control   |
| UC4 | [Manage Bus Routes](./use_case_diagram/UC4_Manage_Bus_Routes.md)                   | Route CRUD operations |
| UC5 | [Receive Push Notifications](./use_case_diagram/UC5_Receive_Push_Notifications.md) | FCM notifications     |
| UC6 | [Report Incident](./use_case_diagram/UC6_Report_Incident.md)                       | Incident submission   |
| UC7 | [Assign Driver to Bus](./use_case_diagram/UC7_Assign_Driver_To_Bus.md)             | Assignment workflow   |
| UC8 | [Manage User Approvals](./use_case_diagram/UC8_Manage_User_Approvals.md)           | Admin approvals       |
| UC9 | [View Trip History](./use_case_diagram/UC9_View_Trip_History.md)                   | Historical logs       |

---

## 🔄 Sequence Diagrams

| ID  | Name                                                                                         | Description         |
| --- | -------------------------------------------------------------------------------------------- | ------------------- |
| SD1 | [User Authentication Flow](./sequence_diagram/SD1_User_Authentication_Flow.md)               | Login with JWT      |
| SD2 | [Real-Time Bus Location Tracking](./sequence_diagram/SD2_Real_Time_Bus_Location_Tracking.md) | Socket.IO broadcast |
| SD3 | [Driver Trip Start/End](./sequence_diagram/SD3_Driver_Trip_Start_End.md)                     | Trip lifecycle      |
| SD4 | [Push Notification Delivery](./sequence_diagram/SD4_Push_Notification_Delivery.md)           | FCM delivery        |
| SD5 | [Incident Reporting Flow](./sequence_diagram/SD5_Incident_Reporting_Flow.md)                 | Incident submission |
| SD6 | [Driver Assignment Workflow](./sequence_diagram/SD6_Driver_Assignment_Workflow.md)           | Accept/Reject flow  |

---

## 🔁 State Machine Diagrams

| ID  | Name                                                              | Description            |
| --- | ----------------------------------------------------------------- | ---------------------- |
| SM1 | [Bus Entity](./state_machine_diagram/SM1_Bus_Entity.md)           | Bus operational states |
| SM2 | [Incident Entity](./state_machine_diagram/SM2_Incident_Entity.md) | Incident lifecycle     |
| SM3 | [User Account](./state_machine_diagram/SM3_User_Account.md)       | Registration/Approval  |
| SM4 | [Bus Assignment](./state_machine_diagram/SM4_Bus_Assignment.md)   | Assignment workflow    |
| SM5 | [Driver Session](./state_machine_diagram/SM5_Driver_Session.md)   | Driver availability    |
| SM6 | [Notification](./state_machine_diagram/SM6_Notification.md)       | Notification delivery  |

---

## 🔀 Activity Diagrams

| ID  | Name                                                                                     | Description         |
| --- | ---------------------------------------------------------------------------------------- | ------------------- |
| AD1 | [User Registration Approval](./activity_diagram/AD1_User_Registration_Approval.md)       | Onboarding workflow |
| AD2 | [Real-Time Bus Tracking](./activity_diagram/AD2_Real_Time_Bus_Tracking.md)               | Map tracking flow   |
| AD3 | [Driver Trip Management](./activity_diagram/AD3_Driver_Trip_Management.md)               | Trip control flow   |
| AD4 | [Incident Reporting Resolution](./activity_diagram/AD4_Incident_Reporting_Resolution.md) | Incident handling   |
| AD5 | [Bus Driver Assignment](./activity_diagram/AD5_Bus_Driver_Assignment.md)                 | Assignment process  |
| AD6 | [Push Notification Workflow](./activity_diagram/AD6_Push_Notification_Workflow.md)       | FCM delivery flow   |

---

## 🏗️ Class Diagrams

| ID  | Name                                                                                    | Description                    |
| --- | --------------------------------------------------------------------------------------- | ------------------------------ |
| CD1 | [Core Data Models](./class_diagram/CD1_Core_Data_Models.md)                             | User, College, Bus, Route      |
| CD2 | [Trip Location Models](./class_diagram/CD2_Trip_Location_Models.md)                     | BusLocation, Schedule, History |
| CD3 | [Incident Notification Models](./class_diagram/CD3_Incident_Notification_Models.md)     | Incident, Notification         |
| CD4 | [Backend Services Architecture](./class_diagram/CD4_Backend_Services_Architecture.md)   | Controllers, Services          |
| CD5 | [Frontend Services Architecture](./class_diagram/CD5_Frontend_Services_Architecture.md) | Flutter Services               |

---

## 🧩 Component Diagrams

| ID    | Name                                                                                        | Description      |
| ----- | ------------------------------------------------------------------------------------------- | ---------------- |
| COMP1 | [System Overview Architecture](./component_diagram/COMP1_System_Overview_Architecture.md)   | High-level view  |
| COMP2 | [Mobile Application Components](./component_diagram/COMP2_Mobile_Application_Components.md) | Flutter modules  |
| COMP3 | [Backend Server Components](./component_diagram/COMP3_Backend_Server_Components.md)         | Node.js layers   |
| COMP4 | [External Services Integration](./component_diagram/COMP4_External_Services_Integration.md) | Third-party APIs |

---

## 📦 Package Diagrams

| ID   | Name                                                                              | Description          |
| ---- | --------------------------------------------------------------------------------- | -------------------- |
| PKG1 | [System Overview Package](./package_diagram/PKG1_System_Overview.md)              | Top-level packages   |
| PKG2 | [Flutter Mobile App Packages](./package_diagram/PKG2_Flutter_Mobile_App.md)       | Mobile app mapping   |
| PKG3 | [Node.js Backend Packages](./package_diagram/PKG3_NodeJS_Backend.md)              | Server module layout |
| PKG4 | [External Libraries & Dependencies](./package_diagram/PKG4_External_Libraries.md) | Library dependencies |

---

## 🖥️ Deployment Diagrams

| ID   | Name                                                                                    | Description          |
| ---- | --------------------------------------------------------------------------------------- | -------------------- |
| DEP1 | [Production Cloud Deployment](./deployment_diagram/DEP1_Production_Cloud_Deployment.md) | Cloud infrastructure |
| DEP2 | [Development Environment](./deployment_diagram/DEP2_Development_Environment.md)         | Local dev setup      |
| DEP3 | [Network Communication Paths](./deployment_diagram/DEP3_Network_Communication_Paths.md) | Network protocols    |

---

## 📁 Folder Structure

```
diagrams/
├── README.md (this file)
├── er_diagram/
│   └── ER_College_Bus_Tracking_System.md
├── api_architecture/
│   └── API_Architecture_Diagram.md
├── auth_flow/
│   └── Authentication_Authorization_Flow.md
├── realtime_architecture_diagram/
│   └── RT_Architecture_College_Bus_Tracking_System.md
├── data_flow_diagram/
│   ├── DFD0_Context_Diagram.md
│   ├── DFD1_Main_Processes.md
│   └── ... (4 files)
├── use_case_diagram/
│   ├── UC1_User_Authentication.md
│   ├── UC2_View_Live_Bus_Location.md
│   └── ... (9 files)
├── sequence_diagram/
│   ├── SD1_User_Authentication_Flow.md
│   └── ... (6 files)
├── state_machine_diagram/
│   ├── SM1_Bus_Entity.md
│   └── ... (6 files)
├── activity_diagram/
│   ├── AD1_User_Registration_Approval.md
│   └── ... (6 files)
├── class_diagram/
│   ├── CD1_Core_Data_Models.md
│   └── ... (5 files)
├── component_diagram/
│   ├── COMP1_System_Overview_Architecture.md
│   └── ... (4 files)
├── package_diagram/
│   ├── PKG1_System_Overview.md
│   └── ... (4 files)
└── deployment_diagram/
    ├── DEP1_Production_Cloud_Deployment.md
    └── ... (3 files)
```

---

## 📖 How to View Diagrams

All diagrams use **Mermaid** syntax. To render them:

1. **VS Code**: Install "Markdown Preview Mermaid Support" extension
2. **GitHub**: Mermaid is natively supported in `.md` files
3. **Online**: Use [Mermaid Live Editor](https://mermaid.live/)

---

## 👥 Role Coverage

| Role        | Relevant Diagrams                 |
| ----------- | --------------------------------- |
| Student     | UC1, UC2, UC5, SD2, AD2           |
| Teacher     | UC1, UC2, UC5, SD2, AD2           |
| Driver      | UC1, UC3, UC6, SD3, SM1, SM5, AD3 |
| Coordinator | UC4, UC7, UC8, SD6, AD4, AD5      |
| Admin       | UC8, SM3, AD1                     |
