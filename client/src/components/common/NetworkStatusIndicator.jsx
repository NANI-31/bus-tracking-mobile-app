import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";

const NetworkStatusIndicator = () => {
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [showIndicator, setShowIndicator] = useState(false);
  const [wasOffline, setWasOffline] = useState(false);

  useEffect(() => {
    const handleOnline = () => {
      setIsOnline(true);
      setWasOffline(true);
      // Show "Connected" for 3 seconds, then hide
      setShowIndicator(true);
      const timer = setTimeout(() => {
        setShowIndicator(false);
        setWasOffline(false);
      }, 3000);
      return () => clearTimeout(timer);
    };

    const handleOffline = () => {
      setIsOnline(false);
      setShowIndicator(true);
    };

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    // Initial check: if already offline on load, show it
    if (!navigator.onLine) {
      setShowIndicator(true);
    }

    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
    };
  }, []);

  return (
    <AnimatePresence>
      {showIndicator && (
        <motion.div
          initial={{ opacity: 0, y: -50, x: "-50%" }}
          animate={{ opacity: 1, y: 16, x: "-50%" }}
          exit={{ opacity: 0, y: -50, x: "-50%" }}
          transition={{ type: "spring", stiffness: 260, damping: 20 }}
          className="fixed top-0 left-1/2 z-50 pointer-events-none"
        >
          {isOnline ? (
            // Connected Banner (Green Glow)
            <div className="flex items-center space-x-2.5 px-4 py-2.5 bg-emerald-950/80 border border-emerald-500/30 text-emerald-200 rounded-full shadow-[0_0_15px_rgba(16,185,129,0.3)] backdrop-blur-md">
              <span className="relative flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
              </span>
              <span className="text-xs font-bold tracking-wide">
                Connection Restored
              </span>
            </div>
          ) : (
            // Offline Warning (Red Pulse Glow)
            <div className="flex items-center space-x-2.5 px-4 py-2.5 bg-rose-950/80 border border-rose-500/30 text-rose-200 rounded-full shadow-[0_0_15px_rgba(239,68,68,0.3)] backdrop-blur-md">
              <span className="relative flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-rose-500"></span>
              </span>
              <span className="text-xs font-bold tracking-wide">
                Offline Mode — Retrying Connection...
              </span>
            </div>
          )}
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default NetworkStatusIndicator;
