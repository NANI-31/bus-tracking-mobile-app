import { io } from "socket.io-client";

const SOCKET_URL = import.meta.env.VITE_API_URL || "http://localhost:5000";

let socket;
let pendingRoomJoins = []; // Track rooms to rejoin on reconnect

export const initiateSocketConnection = (token) => {
  if (socket) return socket;

  socket = io(SOCKET_URL, {
    auth: {
      token,
    },
    transports: ["websocket"],
    reconnection: true,
    reconnectionAttempts: Infinity,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 5000,
  });

  console.log(`Socket connecting...`);

  socket.on("connect", () => {
    console.log("[Socket] Connected:", socket.id);
    // Re-emit all pending room joins on reconnection
    pendingRoomJoins.forEach(({ event, args }) => {
      console.log(`[Socket] Re-joining room: ${event}`, args);
      socket.emit(event, ...args);
    });
  });

  socket.on("disconnect", (reason) => {
    console.log("[Socket] Disconnected:", reason);
  });

  socket.on("reconnect", (attemptNumber) => {
    console.log("[Socket] Reconnected after", attemptNumber, "attempts");
  });

  return socket;
};

/**
 * Register a room join event so it gets replayed on reconnection.
 * Call this instead of socket.emit("join_college", ...) directly.
 */
export const joinRoom = (event, ...args) => {
  // Remove any existing join for the same event to avoid duplicates
  pendingRoomJoins = pendingRoomJoins.filter((j) => j.event !== event);
  pendingRoomJoins.push({ event, args });

  if (socket && socket.connected) {
    socket.emit(event, ...args);
  }
  // If not connected yet, the "connect" handler above will emit it
};

export const disconnectSocket = () => {
  if (socket) {
    socket.disconnect();
    socket = null;
    pendingRoomJoins = [];
  }
};

export const getSocket = () => socket;
