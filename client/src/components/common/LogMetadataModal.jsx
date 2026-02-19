import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  XMarkIcon,
  CodeBracketIcon,
  InformationCircleIcon,
  ClipboardDocumentCheckIcon,
} from "@heroicons/react/24/outline";

const LogMetadataModal = ({ isOpen, onClose, log }) => {
  if (!isOpen || !log) return null;

  const hasBothStates = log.previousState && log.newState;
  const metadata = log.details || log.metadata || {};

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
            <div className="flex items-center space-x-3">
              <div className="bg-indigo-100 p-2 rounded-xl text-indigo-600">
                <CodeBracketIcon className="w-6 h-6" />
              </div>
              <div>
                <h2 className="text-xl font-extrabold text-gray-800">
                  Log Details
                </h2>
                <p className="text-xs text-gray-500 font-bold uppercase tracking-wider">
                  {log.action}
                </p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="p-2 hover:bg-gray-200 rounded-full transition-colors"
            >
              <XMarkIcon className="w-6 h-6 text-gray-500" />
            </button>
          </div>

          {/* Content */}
          <div className="flex-1 overflow-y-auto p-6 bg-gray-50/30">
            <div className="space-y-6">
              {/* Basic Info */}
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm">
                  <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">
                    Actor
                  </p>
                  <p className="font-bold text-gray-700 truncate">
                    {log.userEmail}
                  </p>
                </div>
                <div className="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm">
                  <p className="text-[10px] font-black text-gray-400 uppercase tracking-widest mb-1">
                    Resource
                  </p>
                  <p className="font-bold text-gray-700">
                    {log.resource || "N/A"}
                  </p>
                </div>
              </div>

              {/* JSON Data */}
              <div className="space-y-4">
                {log.previousState && (
                  <div>
                    <div className="flex items-center space-x-2 mb-2">
                      <InformationCircleIcon className="w-4 h-4 text-red-500" />
                      <span className="text-[10px] font-black text-gray-400 uppercase tracking-widest">
                        Previous State
                      </span>
                    </div>
                    <div className="bg-gray-900 rounded-2xl p-4 overflow-x-auto shadow-inner ring-1 ring-white/10">
                      <pre className="text-[10px] text-red-300 font-mono leading-relaxed">
                        {JSON.stringify(log.previousState, null, 2)}
                      </pre>
                    </div>
                  </div>
                )}

                {log.newState && (
                  <div>
                    <div className="flex items-center space-x-2 mb-2">
                      <InformationCircleIcon className="w-4 h-4 text-green-500" />
                      <span className="text-[10px] font-black text-gray-400 uppercase tracking-widest">
                        New State
                      </span>
                    </div>
                    <div className="bg-gray-900 rounded-2xl p-4 overflow-x-auto shadow-inner ring-1 ring-white/10">
                      <pre className="text-[10px] text-green-300 font-mono leading-relaxed">
                        {JSON.stringify(log.newState, null, 2)}
                      </pre>
                    </div>
                  </div>
                )}

                {!log.previousState && !log.newState && metadata && (
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center space-x-2">
                        <InformationCircleIcon className="w-4 h-4 text-indigo-500" />
                        <span className="text-[10px] font-black text-gray-500 uppercase tracking-widest">
                          Metadata Payload
                        </span>
                      </div>
                      <button
                        onClick={() =>
                          navigator.clipboard.writeText(
                            JSON.stringify(metadata, null, 2),
                          )
                        }
                        className="flex items-center space-x-1 text-indigo-600 hover:text-indigo-700 text-xs font-bold transition-colors"
                      >
                        <ClipboardDocumentCheckIcon className="w-4 h-4" />
                        <span>Copy JSON</span>
                      </button>
                    </div>
                    <div className="bg-gray-900 rounded-2xl p-4 overflow-x-auto shadow-inner ring-1 ring-white/10">
                      <pre className="text-[10px] text-indigo-300 font-mono leading-relaxed">
                        {JSON.stringify(metadata, null, 2)}
                      </pre>
                    </div>
                  </div>
                )}
              </div>

              {/* Timestamp */}
              <div className="text-center">
                <p className="text-xs text-gray-400 font-bold">
                  Event occurred on {new Date(log.createdAt).toLocaleString()}
                </p>
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="p-4 border-t bg-gray-50/50 flex justify-end">
            <button
              onClick={onClose}
              className="px-6 py-2 bg-gray-200 text-gray-700 font-bold rounded-xl hover:bg-gray-300 transition-colors"
            >
              Close
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};

export default LogMetadataModal;
