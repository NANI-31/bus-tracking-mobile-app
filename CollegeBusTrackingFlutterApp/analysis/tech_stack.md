# Technology Stack Analysis

## Frontend (Mobile Application)

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.8.1)
- **Language**: [Dart](https://dart.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Navigation**: [go_router](https://pub.dev/packages/go_router)
- **Styling/UI**:
  - [velocity_x](https://pub.dev/packages/velocity_x) (Utility-first UI)
  - [flutter_tailwind_css_colors](https://pub.dev/packages/flutter_tailwind_css_colors)
  - [pinput](https://pub.dev/packages/pinput) (For OTP/PIN inputs)
  - [cached_network_image](https://pub.dev/packages/cached_network_image)
- **Real-time Communication**: [socket_io_client](https://pub.dev/packages/socket_io_client)
- **Maps & Location**:
  - [google_maps_flutter](https://pub.dev/packages/google_maps_flutter)
  - [geolocator](https://pub.dev/packages/geolocator)
  - [maps_toolkit](https://pub.dev/packages/maps_toolkit)
- **Backend Services**:
  - [firebase_core](https://pub.dev/packages/firebase_core)
  - [firebase_messaging](https://pub.dev/packages/firebase_messaging) (Push Notifications)
  - [dio](https://pub.dev/packages/dio) (HTTP Client)
- **Utilities**:
  - [intl](https://pub.dev/packages/intl) (Localization/Internationalization)
  - [shared_preferences](https://pub.dev/packages/shared_preferences) (Local Storage)
  - [permission_handler](https://pub.dev/packages/permission_handler)

## Backend (Server)

- **Runtime**: [Node.js](https://nodejs.org/)
- **Framework**: [Express.js](https://expressjs.com/)
- **Language**: [TypeScript](https://www.typescriptlang.org/)
- **Database**:
  - [MongoDB](https://www.mongodb.com/) (via [Mongoose](https://mongoosejs.com/))
- **Real-time Communication**: [Socket.io](https://socket.io/)
- **Authentication**:
  - [JSON Web Tokens (JWT)](https://jwt.io/)
  - [bcryptjs](https://www.npmjs.com/package/bcryptjs) (Password hashing)
- **Cloud Services**:
  - [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
  - [Google APIs](https://www.npmjs.com/package/googleapis)
- **Mailing**: [Nodemailer](https://nodemailer.com/)
- **Security & Utilities**:
  - [cors](https://www.npmjs.com/package/cors)
  - [dotenv](https://www.npmjs.com/package/dotenv)
  - [rate-limiter-flexible](https://www.npmjs.com/package/rate-limiter-flexible)
  - [lru-cache](https://www.npmjs.com/package/lru-cache)
