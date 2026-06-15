import React, { createContext, useContext, useEffect, useRef, useState } from "react";
import { initiateSocketConnection, joinRoom } from "@/services/socket";

const LiveTrackingContext = createContext(null);

export const LiveTrackingProvider = ({ children, collegeId, userToken, mode = "college" }) => {
  const [isOnline, setIsOnline] = useState(true);
  const locationsRef = useRef({});
  const listenersRef = useRef({});

  // Subscribe a component to a specific bus location updates
  const subscribeToBus = (busId, callback) => {
    if (!listenersRef.current[busId]) {
      listenersRef.current[busId] = new Set();
    }
    listenersRef.current[busId].add(callback);

    // If we already have a location cached, push it immediately to the subscriber
    if (locationsRef.current[busId]) {
      callback(locationsRef.current[busId]);
    }

    // Unsubscribe function
    return () => {
      if (listenersRef.current[busId]) {
        listenersRef.current[busId].delete(callback);
        if (listenersRef.current[busId].size === 0) {
          delete listenersRef.current[busId];
        }
      }
    };
  };

  // Get current cached location for a bus
  const getCachedLocation = (busId) => {
    return locationsRef.current[busId] || null;
  };

  useEffect(() => {
    if (!userToken) return;

    const socket = initiateSocketConnection(userToken);

    // Initialize state
    setIsOnline(socket.connected);

    const handleConnect = () => {
      setIsOnline(true);
    };

    const handleDisconnect = () => {
      setIsOnline(false);
    };

    const handleConnectError = () => {
      setIsOnline(false);
    };

    socket.on("connect", handleConnect);
    socket.on("disconnect", handleDisconnect);
    socket.on("connect_error", handleConnectError);

    if (mode === "global") {
      joinRoom("join_global_tracking");
    } else if (collegeId) {
      joinRoom("join_college", collegeId);
    }

    const handleLocationUpdate = (data) => {
      const { busId, location, speed, heading, timestamp, delay } = data;
      if (!busId) return;

      const newLoc = {
        lat: location.lat,
        lng: location.lng,
        speed: speed ?? 0,
        heading: heading ?? 0,
        delay: delay ?? 0,
        timestamp: timestamp || new Date().toISOString(),
      };

      // Cache the update
      locationsRef.current[busId] = newLoc;

      // Notify any subscribers
      if (listenersRef.current[busId]) {
        listenersRef.current[busId].forEach((callback) => {
          try {
            callback(newLoc);
          } catch (err) {
            console.error(`Error in listener for bus ${busId}:`, err);
          }
        });
      }
    };

    socket.on("location_updated", handleLocationUpdate);

    return () => {
      socket.off("connect", handleConnect);
      socket.off("disconnect", handleDisconnect);
      socket.off("connect_error", handleConnectError);
      socket.off("location_updated", handleLocationUpdate);
    };
  }, [userToken, collegeId, mode]);

  return (
    <LiveTrackingContext.Provider value={{ subscribeToBus, getCachedLocation, isOnline }}>
      {children}
    </LiveTrackingContext.Provider>
  );
};

export const useLiveTracking = () => {
  const context = useContext(LiveTrackingContext);
  if (!context) {
    throw new Error("useLiveTracking must be used within a LiveTrackingProvider");
  }
  return context;
};
export default LiveTrackingContext;
