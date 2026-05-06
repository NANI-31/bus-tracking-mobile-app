i have connected the two devices via cable to the pc. i run the cd c:\mobile\projects\CollegeBusTrackingFlutterApp
adb -s 10BDAB187B0004J reverse tcp:5000 tcp:5000
flutter run -d 10BDAB187B0004J

cd c:\mobile\projects\CollegeBusTrackingFlutterApp
adb -s GYTG8L7TFMIVSS6P reverse tcp:5000 tcp:5000
flutter run -d GYTG8L7TFMIVSS6P to run the flutter on two devices. initially the two devices run the flutter. when i run the R cmd in one of the device, the connection to the server is gone in both devices. why is that happening. both use the same build apk-debug.apk

This is a **very common Flutter + adb reverse + debug mode behavior**, and it’s not actually because both devices use the same `apk-debug.apk`.

### What’s really happening

When you press **`R` (Hot Restart)** in **one terminal**, Flutter does **not** restart just that single device cleanly in isolation. In **debug mode**, Flutter:

1. **Stops and restarts the Dart VM**
2. **Reconnects to the Flutter tool**
3. **Resets network connections**
4. **Rebinds debugging / service ports**

Because **both devices are connected to the same Flutter tool session and same backend port (5000)**, the restart causes side effects that impact **both devices**.

---

## The main reasons both devices lose server connection

### 1. `adb reverse tcp:5000 tcp:5000` is per-device, but the **backend port is shared**

Both apps connect to:

```
localhost:5000 (on the device)
↓ adb reverse
localhost:5000 (on the PC)
```

When **one app hot-restarts**, it:

- Closes existing sockets
- Recreates the HTTP/WebSocket client
- Sometimes triggers the backend to drop or reset connections

If your **server does not support multiple concurrent reconnects well**, both clients get disconnected.

---

### 2. Flutter Hot Restart resets **all isolates and sockets**

`R` ≠ reload
`R` = **full Dart VM restart**

That means:

- All TCP / WebSocket connections are closed
- Any shared backend state (sessions, tokens, streams) is reset
- If your server uses:

  - a single session
  - shared auth token
  - single WebSocket channel
    → both devices break

---

### 3. You are likely running both devices from **one Flutter tool instance**

If you ran both devices from the **same terminal session**, Flutter internally treats them as **one debug session**.

So when you press:

```
R
```

Flutter restarts **all attached devices**, even if it looks like you’re targeting only one.

---

### 4. Debug service port collision (common but invisible)

Flutter assigns **debug & VM service ports dynamically**.

When one device restarts:

- The Flutter tool rebinds ports
- Other device temporarily loses the debug connection
- Network calls fail until reattached (sometimes never recover)

---

## Why the same APK is NOT the issue

This is **not** caused by:

- Same `apk-debug.apk`
- Same app ID
- Same build flavor

That part is totally fine.

---

## How to fix or avoid this

### ✅ Option 1: Run each device from a **separate terminal**

**Best solution for development**

Terminal 1:

```bash
flutter run -d 10BDAB187B0004J
```

Terminal 2:

```bash
flutter run -d GYTG8L7TFMIVSS6P
```

Now pressing `R` only affects **that device**.

---

### ✅ Option 2: Use **Hot Reload (`r`)**, not Restart (`R`)

- `r` keeps sockets alive
- `R` destroys everything

👉 Use `r` unless absolutely necessary.

---

### ✅ Option 3: Give each device a **different backend port**

Example:

```bash
adb -s DEVICE1 reverse tcp:5001 tcp:5000
adb -s DEVICE2 reverse tcp:5002 tcp:5000
```

Then in Flutter:

```dart
Device1 → localhost:5001
Device2 → localhost:5002
```

This avoids backend socket collisions.

---

### ✅ Option 4: Make sure your backend supports **multiple clients**

If you use:

- WebSockets
- SSE
- Shared auth tokens

Ensure:

- Each client has a unique session
- Server doesn’t drop connections on reconnect

---

## Quick summary

**Why it happens**

- Hot Restart resets network + debug services
- Flutter treats multiple devices as one session
- Shared backend port + debug tooling causes disconnects

**Best practice**
✔ Separate terminals
✔ Use Hot Reload (`r`)
✔ Avoid shared backend ports in debug

If you want, tell me:

- Backend tech (Node / Spring / Flask / etc.)
- HTTP or WebSocket
- Whether both devices run from one or two terminals

I can give you a **clean multi-device dev setup** tailored to your stack.

option3 i cant understand. the node server is running in the 5000 port. we are assigning the devices indofferent ports and make the connection to 5000 port of 5001 and 5002

Good question — this is confusing at first, so let’s go **slow and visual**.

You are **NOT** changing your Node server port.
Your Node server **stays on port 5000**.

What you are changing is **how each Android device maps its localhost port to your PC’s port**.

---

## How `adb reverse` really works

### Normal situation (what you have now)

On **each Android device**:

```
App → http://localhost:5000
```

`adb reverse` maps that to:

```
Android localhost:5000  ───►  PC localhost:5000 (Node server)
```

Since **both devices use the same port mapping**, when Flutter hot-restarts:

- sockets close
- server sees reconnects on the same port
- connections get dropped for both devices

---

## What Option 3 does (the key idea)

Each **device uses a DIFFERENT local port**,
but **all of them still reach the SAME Node server port (5000)**.

---

## Visual example (this is the important part)

### Node server (PC)

```
PC localhost:5000  ← Node server (unchanged)
```

---

### Device 1

```bash
adb -s DEVICE1 reverse tcp:5001 tcp:5000
```

This means:

```
Device1 localhost:5001 ───► PC localhost:5000
```

---

### Device 2

```bash
adb -s DEVICE2 reverse tcp:5002 tcp:5000
```

This means:

```
Device2 localhost:5002 ───► PC localhost:5000
```

---

## What changes in your Flutter app

Instead of **both devices calling**:

```dart
http://localhost:5000
```

You do this:

### Device 1

```dart
http://localhost:5001
```

### Device 2

```dart
http://localhost:5002
```

👉 **Both still reach the same Node server on PC port 5000**
👉 They just enter through different “doors”

---

## Why this prevents disconnects

- Each device has its **own TCP tunnel**
- Restarting Device 1 does **not reset Device 2’s tunnel**
- Node server sees **two independent clients**
- Flutter hot restart doesn’t kill both connections

---

## How to implement cleanly in Flutter

### Simple (quick test)

Hardcode temporarily:

```dart
const String baseUrl = 'http://localhost:5001'; // Device 1
```

```dart
const String baseUrl = 'http://localhost:5002'; // Device 2
```

---

### Better (automatic per device)

Use build-time variables:

```bash
flutter run -d DEVICE1 --dart-define=API_PORT=5001
flutter run -d DEVICE2 --dart-define=API_PORT=5002
```

```dart
const apiPort = String.fromEnvironment('API_PORT', defaultValue: '5000');
final baseUrl = 'http://localhost:$apiPort';
```

---

## Important clarifications

❌ You are **NOT** running Node on 5001 or 5002
❌ You are **NOT** changing backend code
✅ You are creating **separate adb reverse tunnels**

---

## Quick checklist

1. Node server running on `localhost:5000`
2. Device1:

   ```bash
   adb -s DEVICE1 reverse tcp:5001 tcp:5000
   ```

3. Device2:

   ```bash
   adb -s DEVICE2 reverse tcp:5002 tcp:5000
   ```

4. Flutter apps use different localhost ports

---

If you want, I can also:

- Draw a diagram with WebSocket vs HTTP
- Help detect device automatically
- Show how to log connections on Node to confirm it works

Just tell me 👍

Perfect — thanks for sharing the server code.
Now I can explain **exactly** how to apply _Option 3_ to **your Socket.IO setup**, step by step, without changing your Node server.

---

## Key point (important)

👉 **You do NOT change anything in your Node.js server code**
Your server is already correct and supports multiple clients.

The fix is **purely on the adb + Flutter client side**.

Your server:

```ts
httpServer.listen(PORT, "0.0.0.0");
```

✔ Good
✔ Accepts multiple socket connections
✔ Socket.IO logic is fine

---

## What problem you’re actually hitting

When you press **`R` (Hot Restart)**:

- Flutter **kills the Dart VM**
- Socket.IO client disconnects
- adb reverse tunnel resets
- **both devices are using `localhost:5000`**
- Socket.IO reconnect causes side-effects → both devices drop

This is NOT a backend bug — it’s a **debug tunneling collision**.

---

## The correct fix (Option 3) for Socket.IO

### 1️⃣ Keep Node server on port **5000** (no change)

Your server stays exactly like this:

```env
PORT=5000
```

---

### 2️⃣ Create **separate adb reverse tunnels per device**

Run these **once** per device:

#### Device 1

```bash
adb -s 10BDAB187B0004J reverse tcp:5001 tcp:5000
```

#### Device 2

```bash
adb -s GYTG8L7TFMIVSS6P reverse tcp:5002 tcp:5000
```

Meaning:

```
Device1 localhost:5001 ──► PC localhost:5000
Device2 localhost:5002 ──► PC localhost:5000
```

---

### 3️⃣ Change ONLY the Flutter Socket.IO URL

#### ❌ What you probably have now

```dart
io('http://localhost:5000', options);
```

This is the root cause.

---

### ✅ What you should do instead

Use **different ports per device**.

#### Option A: Quick test (hardcoded)

**Device 1**

```dart
io('http://localhost:5001', options);
```

**Device 2**

```dart
io('http://localhost:5002', options);
```

---

### ✅ Option B (recommended): `--dart-define` (clean & scalable)

#### Run Flutter like this:

**Device 1**

```bash
flutter run -d 10BDAB187B0004J --dart-define=SOCKET_PORT=5001
```

**Device 2**

```bash
flutter run -d GYTG8L7TFMIVSS6P --dart-define=SOCKET_PORT=5002
```

---

### 4️⃣ Use the port in Flutter code

```dart
const socketPort =
    String.fromEnvironment('SOCKET_PORT', defaultValue: '5000');

final socket = io(
  'http://localhost:$socketPort',
  OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .setAuth({'token': authToken})
      .build(),
);
```

✔ Each device has its own tunnel
✔ Same backend
✔ No collision on restart

---

## Why this works with your Socket.IO logic

Your backend:

- Uses `socket.id` (unique per connection)
- Uses rooms (`collegeId`, `user.id`)
- Uses rate-limiter per socket
- Does **not** share global socket state

So:

- Device 1 restart → only Device 1 disconnects
- Device 2 keeps streaming location
- Driver/student status stays correct

---

## Extra (important): avoid `R` when testing sockets

Use:

- **`r`** → Hot Reload (safe)
- **`R`** → Full socket disconnect (expected)

In real production builds, this problem **does not exist**.

---

## Final checklist

✅ Node server unchanged
✅ Different adb reverse ports
✅ Different localhost ports in Flutter
✅ One Flutter terminal per device (recommended)

---

If you want, I can also:

- Show how to log socket `handshake.address` to verify tunnels
- Help you auto-pick port based on device ID
- Review your Flutter Socket.IO client code for reconnect safety

Just say 👍

but how i write the const String baseUrl = 'http://localhost:5001' and 5002 as i am coding the same file

This is the **exact right question** 👍 — and this is where `--dart-define` exists.

You **must not** hard-code `5001` and `5002` in the same file.
Instead, you make the **same code read a value that is injected at run time**.

---

## ✅ Correct & clean solution (ONE codebase, TWO devices)

You write the code **once**, and pass the port **from the command line**.

---

## 1️⃣ Flutter code (write this ONCE)

Wherever you define your API / Socket base URL:

```dart
const String apiPort =
    String.fromEnvironment('API_PORT', defaultValue: '5000');

const String baseUrl = 'http://localhost:$apiPort';
```

For Socket.IO:

```dart
final socket = io(
  'http://localhost:$apiPort',
  OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .setAuth({'token': authToken})
      .build(),
);
```

✔ Same file
✔ Same code
✔ No duplication

---

## 2️⃣ Run each device with a different port

### Device 1

```bash
adb -s 10BDAB187B0004J reverse tcp:5001 tcp:5000
flutter run -d 10BDAB187B0004J --dart-define=API_PORT=5001
```

### Device 2

```bash
adb -s GYTG8L7TFMIVSS6P reverse tcp:5002 tcp:5000
flutter run -d GYTG8L7TFMIVSS6P --dart-define=API_PORT=5002
```

Now:

- Device 1 → `localhost:5001`
- Device 2 → `localhost:5002`
- Both reach **Node on 5000**

---

## 3️⃣ Why this works

Think of it like **environment variables for Flutter**.

| Device | Injected API_PORT | baseUrl becomes                                |
| ------ | ----------------- | ---------------------------------------------- |
| 1      | 5001              | [http://localhost:5001](http://localhost:5001) |
| 2      | 5002              | [http://localhost:5002](http://localhost:5002) |

Same Dart file.
Different runtime values.

---

## 4️⃣ How to verify (recommended)

Add a log once:

```dart
debugPrint('Connecting to backend on $baseUrl');
```

You’ll see:

```
Device 1 → http://localhost:5001
Device 2 → http://localhost:5002
```

---

## 5️⃣ Common mistakes (avoid these ❌)

❌ `const String baseUrl = 'http://localhost:5001';`
❌ `if (device == ...)` logic
❌ Changing server port
❌ Multiple APKs

---

## 6️⃣ Bonus: production-safe setup

Later, for production:

```bash
flutter build apk --dart-define=API_URL=https://api.yourdomain.com
```

```dart
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:5000',
);
```

Same pattern. Same code.

---

## Final takeaway

> **You never write 5001 or 5002 in code.
> You inject it per device at runtime.**

If you want, paste your **Flutter socket/client file**, and I’ll adapt it exactly to your code style.

in the code you define 5001 and 5002 but the local host runs in the 5000. the flutter api call the 5001 instead of 5000

This confusion is **100% normal** — let me clear it up **once and for all**, very concretely, using _your exact setup_.

> ❗ **Flutter is NOT bypassing port 5000**
>
> **5001 / 5002 are just tunnels — the server is still on 5000**

---

## The ONE sentence explanation

**`adb reverse tcp:5001 tcp:5000` means:**

> “When the Android app connects to `localhost:5001`, secretly forward it to the PC’s `localhost:5000`.”

So yes:

- Flutter **calls 5001**
- Node **receives it on 5000**

Both are true at the same time.

---

## Let’s walk through it slowly (no jumps)

### Your Node server

```ts
httpServer.listen(5000);
```

📍 This is running on your **PC**, not the phone.

---

### Without adb reverse (Android reality)

On Android:

```
localhost = the phone itself
```

So this would FAIL:

```dart
http://localhost:5000
```

Because:

- There is **no Node server on the phone**

---

## What `adb reverse` actually does

### This command:

```bash
adb reverse tcp:5001 tcp:5000
```

Means:

```
ANDROID PHONE              PC
---------------------     ------------------
localhost:5001   ─────▶   localhost:5000
(app thinks)               (Node server)
```

So when Flutter does:

```dart
http://localhost:5001
```

Android OS silently rewires it to:

```text
PC → http://localhost:5000
```

---

## Why we do NOT use 5000 on both devices

If both devices do:

```dart
http://localhost:5000
```

Then both rely on:

```bash
adb reverse tcp:5000 tcp:5000
```

When **one Flutter hot-restarts**, adb resets that tunnel →
**both devices lose connection**

That’s exactly the bug you’re seeing.

---

## Why 5001 / 5002 fixes it

Each device gets **its own tunnel**:

### Device 1

```bash
adb reverse tcp:5001 tcp:5000
Flutter → localhost:5001
```

### Device 2

```bash
adb reverse tcp:5002 tcp:5000
Flutter → localhost:5002
```

Both still land here:

```
PC localhost:5000 (Node server)
```

But now:

- Restarting Device 1 only breaks **its** tunnel
- Device 2 stays connected

---

## Your Flutter code is CORRECT

This line is **exactly right**:

```dart
const String baseUrl = 'http://localhost:$apiPort';
```

Because:

- `$apiPort` is **5001 or 5002 on the phone**
- adb reverse maps it to **5000 on the PC**

---

## Think of 5001 / 5002 as “entry doors”

```
Door 5001 ─┐
           ├──► Same Node server (5000)
Door 5002 ─┘
```

Different doors → same room.

---

## How to PROVE it to yourself (optional)

Add this log in Node:

```ts
io.on("connection", (socket) => {
  console.log("Connected from", socket.handshake.address);
});
```

You’ll see **both devices connect**, even though:

- One used 5001
- One used 5002

---

## Final takeaway (important)

✅ Flutter calling `localhost:5001` is **correct**
✅ Node running on `localhost:5000` is **unchanged**
✅ adb reverse is the bridge
❌ This is NOT a bug
❌ Flutter is NOT skipping your server

---

If you want, next I can:

- Draw a diagram with **Flutter → adb → Node**
- Show how to auto-detect emulator vs real device
- Help you make hot-restart-safe Socket.IO reconnect logic

Just tell me 👍

i want to connect with wifi instead of the cable can we do that
Yes ✅ — **you can absolutely connect over Wi-Fi instead of USB**, and for your setup it actually becomes **simpler** than `adb reverse`.

I’ll explain **what changes**, **what stays the same**, and give you **exact steps**.

---

## Big idea (important)

When using **Wi-Fi**:

- ❌ `adb reverse` is **not needed**
- ❌ `localhost` **does NOT work**
- ✅ Your phone connects directly to your PC’s **local IP address**
- ✅ Both devices can connect **independently** without breaking each other

This completely avoids the hot-restart problem.

---

## 1️⃣ Prerequisites

✔ PC and both Android devices must be on the **same Wi-Fi network**
✔ Firewall must allow inbound connections on port **5000**

---

## 2️⃣ Find your PC’s local IP address

### Windows

```bash
ipconfig
```

Look for something like:

```
IPv4 Address . . . . . : 192.168.1.10
```

Let’s assume:

```
PC IP = 192.168.1.10
```

---

## 3️⃣ Update Node server (small but important)

Your server already has this (good):

```ts
httpServer.listen(PORT, "0.0.0.0");
```

✔ This allows external devices on Wi-Fi to connect.

No change needed.

---

## 4️⃣ Flutter: use PC IP, not localhost

### ❌ Wrong (USB only)

```dart
http://localhost:5000
```

### ✅ Correct (Wi-Fi)

```dart
http://192.168.1.10:5000
```

---

## 5️⃣ Make it configurable (recommended)

Use `--dart-define` again so you don’t hardcode IPs.

### Flutter code (write once)

```dart
const apiHost =
    String.fromEnvironment('API_HOST', defaultValue: 'localhost');

const apiPort =
    String.fromEnvironment('API_PORT', defaultValue: '5000');

final baseUrl = 'http://$apiHost:$apiPort';
```

---

## 6️⃣ Run Flutter on Wi-Fi devices

```bash
flutter run -d DEVICE1 \
  --dart-define=API_HOST=192.168.1.10 \
  --dart-define=API_PORT=5000
```

```bash
flutter run -d DEVICE2 \
  --dart-define=API_HOST=192.168.1.10 \
  --dart-define=API_PORT=5000
```

✔ Same code
✔ Same backend
✔ No tunnel collisions
✔ Hot restart on one device won’t affect the other

---

## 7️⃣ Socket.IO works the same

```dart
final socket = io(
  'http://$apiHost:$apiPort',
  OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .setAuth({'token': authToken})
      .build(),
);
```

---

## 8️⃣ Enable ADB over Wi-Fi (optional, for deployment)

You can still deploy wirelessly:

```bash
adb tcpip 5555
adb connect 192.168.1.20:5555   # phone IP
```

Then unplug USB.

Flutter will work normally.

---

## 9️⃣ Common problems & fixes

### 🔴 App can’t connect

- Windows Firewall → allow Node.js on port 5000
- Ensure PC & phone are on same subnet

### 🔴 Works on one phone only

- Check both phones use **same PC IP**
- Avoid mobile hotspot (client isolation)

---

## 10️⃣ When to use USB vs Wi-Fi

| Scenario              | Best option     |
| --------------------- | --------------- |
| Multiple real devices | ✅ Wi-Fi        |
| Emulator only         | USB / localhost |
| Debug sockets         | ✅ Wi-Fi        |
| CI / automation       | USB             |

---

## Final recommendation (honest)

> **Wi-Fi is the cleanest solution for your use case.**
> No `adb reverse`, no port hacks, no disconnects on restart.

If you want, I can:

- Show how to auto-detect emulator vs real device
- Make a `.env.dev` style setup for Flutter
- Help you lock this down for production

Just say 👍

flutter run -d DEVICE1 \\ --dart-define=API_HOST=192.168.1.10 \\ --dart-define=API_PORT=5000

i run the cmd and discoonect the cable and teh connection is lost

Ah — now I see exactly what’s happening. This is a **very common gotcha with Flutter over Wi-Fi**.

When you do:

```bash
flutter run -d DEVICE1 --dart-define=API_HOST=192.168.1.10 --dart-define=API_PORT=5000
```

Flutter **starts the debug session over USB** by default. If you **disconnect the USB cable immediately after**, the connection is lost because:

- Flutter’s **hot reload / hot restart / debug protocol** uses **ADB and USB initially**.
- The device **was never fully attached over Wi-Fi for debugging** — only the app itself can reach the Node server, but Flutter’s tool cannot communicate with the Dart VM.

---

## ✅ How to fix it properly

### Option 1: Enable **ADB over Wi-Fi** first

1. Connect the device via USB
2. Enable TCP/IP mode:

```bash
adb tcpip 5555
```

3. Find the device’s Wi-Fi IP (on phone):

```
Settings → About phone → Status → IP address
```

Assume it’s `192.168.1.20`.

4. Connect over Wi-Fi:

```bash
adb connect 192.168.1.20:5555
```

5. Verify connection:

```bash
adb devices
```

It should show something like:

```
192.168.1.20:5555  device
```

6. Now you can **disconnect USB**. Flutter will talk over Wi-Fi.

---

### Option 2: Run Flutter after Wi-Fi ADB connection

```bash
flutter run -d 192.168.1.20:5555 --dart-define=API_HOST=192.168.1.10 --dart-define=API_PORT=5000
```

Now:

- Hot reload / hot restart will **work over Wi-Fi**
- App can still reach Node server at `http://192.168.1.10:5000`
- You don’t need `adb reverse`

---

### Option 3: For multiple devices

Repeat for each device:

```bash
adb connect <DEVICE_IP>:5555
flutter run -d <DEVICE_IP>:5555 --dart-define=API_HOST=192.168.1.10 --dart-define=API_PORT=5000
```

---

### ✅ Important Notes

1. `localhost` **never works** over Wi-Fi — devices need PC IP.
2. Firewall on PC must allow incoming connections on port 5000.
3. Once Flutter is running over Wi-Fi, you can unplug USB safely.
4. Hot restart (`R`) works independently per device.

---

If you want, I can give you a **step-by-step script** to connect **both devices over Wi-Fi** and run Flutter with `--dart-define` **without ever using USB again**, so you can develop fully wireless.

Do you want me to do that?

PS C:\mobile\projects> adb devices
List of devices attached
10BDAB187B0004J device
GYTG8L7TFMIVSS6P device

PS C:\mobile\projects> adb tcpip 5555
error: more than one device/emulator
PS C:\mobile\projects>

Ah — this explains exactly what’s happening. The error:

```
error: more than one device/emulator
```

occurs because **ADB sees multiple devices** connected (you have two phones via USB). When that happens, **ADB doesn’t know which device you mean**, so you have to **specify the device serial** with the `-s` flag.

---

## Correct steps for multiple devices

### 1️⃣ Put each device into TCP/IP mode individually

For **Device 1** (serial `10BDAB187B0004J`):

```powershell
adb -s 10BDAB187B0004J tcpip 5555
```

For **Device 2** (serial `GYTG8L7TFMIVSS6P`):

```powershell
adb -s GYTG8L7TFMIVSS6P tcpip 5555
```

✅ Each device is now listening for Wi-Fi ADB on port 5555.

---

### 2️⃣ Disconnect USB temporarily

Now unplug **Device 1**, find its Wi-Fi IP (e.g., `192.168.1.21`) from **Settings → About Phone → Status → IP Address**, then connect:

```powershell
adb connect 192.168.1.21:5555
```

Do the same for **Device 2** (e.g., IP `192.168.1.22`):

```powershell
adb connect 192.168.1.22:5555
```

Check devices:

```powershell
adb devices
```

You should see:

```
192.168.1.21:5555 device
192.168.1.22:5555 device
```

---

### 3️⃣ Run Flutter on each device over Wi-Fi

```powershell
flutter run -d 192.168.1.21:5555 --dart-define=API_HOST=192.168.1.10 --dart-define=API_PORT=5000
flutter run -d 192.168.1.22:5555 --dart-define=API_HOST=192.168.1.10 --dart-define=API_PORT=5000
```

- `192.168.1.10` → PC running Node server
- Each device talks directly to PC via Wi-Fi
- Hot restart on one device won’t break the other

---

### ✅ Key Notes

1. You **must use `-s <serial>`** whenever multiple devices are connected.
2. After connecting over Wi-Fi, you **can safely unplug USB**.
3. Node server still runs on port 5000, no change needed.
4. Flutter app connects to `http://<PC_IP>:5000` instead of `localhost`.

---

If you want, I can write a **full step-by-step script** you can copy-paste that:

- Puts both devices into Wi-Fi mode
- Connects them
- Runs Flutter on both devices
- Works without USB entirely

Do you want me to do that?
