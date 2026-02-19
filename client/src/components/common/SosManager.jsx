import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  XMarkIcon,
  MapPinIcon,
  CheckCircleIcon,
  ClockIcon,
  ExclamationCircleIcon,
  UserIcon,
  TruckIcon,
} from "@heroicons/react/24/outline";
import { useDispatch } from "react-redux";
import { resolveActiveSos } from "../../features/common/slices/sosSlice";

const SosManager = ({ isOpen, onClose, activeAlerts, sosLogs }) => {
  const [tab, setTab] = useState("active");
  const [resolvingId, setResolvingId] = useState(null);
  const [notes, setNotes] = useState("");
  const dispatch = useDispatch();

  if (!isOpen) return null;

  const handleResolve = async (e) => {
    e.preventDefault();
    if (!resolvingId) return;

    await dispatch(
      resolveActiveSos({ sosId: resolvingId, resolutionNotes: notes }),
    );
    setResolvingId(null);
    setNotes("");
  };

  const formatDate = (date) => {
    return new Date(date).toLocaleString();
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-100 flex items-center justify-center p-4">
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        />

        <motion.div
          initial={{ scale: 0.9, opacity: 0, y: 20 }}
          animate={{ scale: 1, opacity: 1, y: 0 }}
          exit={{ scale: 0.9, opacity: 0, y: 20 }}
          className="relative bg-white rounded-3xl shadow-2xl w-full max-w-2xl max-h-[80vh] flex flex-col overflow-hidden"
        >
          {/* Header */}
          <div className="p-6 border-b flex justify-between items-center bg-gray-50/50">
            <div>
              <h2 className="text-2xl font-bold text-gray-800 flex items-center">
                <ExclamationCircleIcon className="w-8 h-8 mr-2 text-red-600" />
                SOS Emergency Manager
              </h2>
              <p className="text-sm text-gray-500 font-medium">
                Monitor and resolve active emergency alerts
              </p>
            </div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-200 rounded-full transition-colors"
            >
              <XMarkIcon className="w-6 h-6 text-gray-500" />
            </button>
          </div>

          {/* Tabs */}
          <div className="flex border-b">
            <button
              onClick={() => setTab("active")}
              className={`flex-1 py-4 font-bold text-sm transition-all border-b-2 ${
                tab === "active"
                  ? "border-red-600 text-red-600 bg-red-50/30"
                  : "border-transparent text-gray-500 hover:text-gray-700 hover:bg-gray-50"
              }`}
            >
              Active Alerts ({activeAlerts.length})
            </button>
            <button
              onClick={() => setTab("logs")}
              className={`flex-1 py-4 font-bold text-sm transition-all border-b-2 ${
                tab === "logs"
                  ? "border-indigo-600 text-indigo-600 bg-indigo-50/30"
                  : "border-transparent text-gray-500 hover:text-gray-700 hover:bg-gray-50"
              }`}
            >
              Alert Logs
            </button>
          </div>

          {/* Content */}
          <div className="flex-1 overflow-y-auto p-6 space-y-4 bg-gray-50/30">
            {tab === "active" ? (
              activeAlerts.length > 0 ? (
                activeAlerts.map((alert) => (
                  <div
                    key={alert.sos_id}
                    className="bg-white border-2 border-red-100 rounded-2xl p-5 shadow-sm hover:shadow-md transition-shadow"
                  >
                    <div className="flex justify-between items-start mb-4">
                      <div>
                        <span className="bg-red-100 text-red-700 text-xs font-black px-2 py-1 rounded-lg uppercase mb-2 inline-block tracking-wider">
                          {alert.sos_id}
                        </span>
                        <h3 className="text-lg font-bold text-gray-800 flex items-center">
                          <ClockIcon className="w-5 h-5 mr-1 text-gray-400" />
                          {formatDate(alert.timestamp)}
                        </h3>
                      </div>
                      <a
                        href={`https://www.google.com/maps?q=${alert.latitude},${alert.longitude}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="bg-indigo-50 text-indigo-600 px-3 py-1.5 rounded-xl text-xs font-bold flex items-center hover:bg-indigo-100 transition-colors"
                      >
                        <MapPinIcon className="w-4 h-4 mr-1" />
                        View Map
                      </a>
                    </div>

                    <div className="grid grid-cols-2 gap-4 mb-4">
                      <div className="flex items-center space-x-3 bg-gray-50 p-3 rounded-xl">
                        <UserIcon className="w-8 h-8 text-gray-400" />
                        <div>
                          <p className="text-[10px] text-gray-400 font-bold uppercase tracking-tight">
                            Reported By
                          </p>
                          <p className="font-bold text-gray-700">
                            {alert.user_role}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-3 bg-gray-50 p-3 rounded-xl">
                        <TruckIcon className="w-8 h-8 text-gray-400" />
                        <div>
                          <p className="text-[10px] text-gray-400 font-bold uppercase tracking-tight">
                            Bus Number
                          </p>
                          <p className="font-bold text-gray-700">
                            {alert.bus_number}
                          </p>
                        </div>
                      </div>
                    </div>

                    {resolvingId === alert.sos_id ? (
                      <form
                        onSubmit={handleResolve}
                        className="space-y-3 pt-4 border-t border-dashed"
                      >
                        <div>
                          <label className="block text-xs font-bold text-gray-500 uppercase mb-1">
                            Resolution Notes
                          </label>
                          <textarea
                            value={notes}
                            onChange={(e) => setNotes(e.target.value)}
                            placeholder="Describe what was done to resolve this emergency..."
                            className="w-full bg-gray-50 border-gray-200 rounded-xl p-3 text-sm focus:ring-2 focus:ring-red-500 resize-none h-24 transition-all"
                            required
                          />
                        </div>
                        <div className="flex space-x-2">
                          <button
                            type="submit"
                            className="flex-1 bg-green-600 text-white font-bold py-2 rounded-xl hover:bg-green-700 transition-colors shadow-lg shadow-green-600/20"
                          >
                            Mark Resolved
                          </button>
                          <button
                            type="button"
                            onClick={() => setResolvingId(null)}
                            className="px-4 bg-gray-100 text-gray-500 font-bold py-2 rounded-xl hover:bg-gray-200 transition-colors"
                          >
                            Cancel
                          </button>
                        </div>
                      </form>
                    ) : (
                      <button
                        onClick={() => setResolvingId(alert.sos_id)}
                        className="w-full bg-red-600 text-white font-bold py-2.5 rounded-xl hover:bg-red-700 transition-colors shadow-lg shadow-red-600/20 flex items-center justify-center"
                      >
                        <CheckCircleIcon className="w-5 h-5 mr-1" />
                        Resolve Alert
                      </button>
                    )}
                  </div>
                ))
              ) : (
                <div className="flex flex-col items-center justify-center py-12 text-gray-400 opacity-60">
                  <div className="bg-gray-100 p-6 rounded-full mb-4">
                    <CheckCircleIcon className="w-16 h-16" />
                  </div>
                  <p className="font-black text-xl">All clear!</p>
                  <p className="font-bold text-sm uppercase tracking-widest">
                    No active emergency alerts
                  </p>
                </div>
              )
            ) : (
              <div className="space-y-3">
                {sosLogs.length > 0 ? (
                  sosLogs.map((log) => (
                    <div
                      key={log.sos_id}
                      className="bg-white border rounded-2xl p-4 opacity-75 hover:opacity-100 transition-opacity"
                    >
                      <div className="flex justify-between items-center mb-2">
                        <span className="font-bold text-gray-700">
                          {log.sos_id}
                        </span>
                        <span className="text-xs font-bold text-gray-400">
                          {formatDate(log.timestamp)}
                        </span>
                      </div>
                      <div className="text-sm text-gray-600 bg-gray-50 p-3 rounded-xl border-l-4 border-indigo-500">
                        <p className="font-black text-xs text-indigo-600 uppercase mb-1">
                          Resolution Detail
                        </p>
                        {log.resolutionNotes}
                      </div>
                    </div>
                  ))
                ) : (
                  <p className="text-center py-12 text-gray-400 font-bold">
                    No resolved alerts found.
                  </p>
                )}
              </div>
            )}
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};

export default SosManager;
