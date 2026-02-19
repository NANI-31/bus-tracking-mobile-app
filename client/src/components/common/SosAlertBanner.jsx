import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ExclamationTriangleIcon, XMarkIcon } from "@heroicons/react/24/solid";

const SosAlertBanner = ({ activeAlerts, onOpenManager, onDismiss }) => {
  if (activeAlerts.length === 0) return null;

  return (
    <AnimatePresence>
      <motion.div
        initial={{ y: -100, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        exit={{ y: -100, opacity: 0 }}
        className="fixed top-4 left-1/2 -translate-x-1/2 z-100 w-full max-w-lg px-4"
      >
        <div className="bg-red-600 text-white rounded-2xl shadow-2xl p-4 flex items-center justify-between border-2 border-red-500/50 backdrop-blur-md">
          <div className="flex items-center space-x-4">
            <div className="bg-white/20 p-2 rounded-full animate-pulse">
              <ExclamationTriangleIcon className="w-6 h-6 text-white" />
            </div>
            <div>
              <h4 className="font-bold text-lg leading-tight">
                🚨 SOS Emergency Alert
              </h4>
              <p className="text-sm text-red-100 font-medium">
                {activeAlerts.length} active emergency{" "}
                {activeAlerts.length === 1 ? "alert" : "alerts"} reported.
              </p>
            </div>
          </div>

          <div className="flex items-center space-x-2">
            <button
              onClick={onOpenManager}
              className="bg-white text-red-600 px-4 py-2 rounded-xl font-bold text-sm hover:bg-red-50 transition-colors shadow-lg"
            >
              Manage
            </button>
            <button
              onClick={onDismiss}
              className="p-2 hover:bg-white/10 rounded-full transition-colors text-red-200"
            >
              <XMarkIcon className="w-5 h-5" />
            </button>
          </div>
        </div>
      </motion.div>
    </AnimatePresence>
  );
};

export default SosAlertBanner;
