import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  XMarkIcon,
  CodeBracketIcon,
  InformationCircleIcon,
  UserIcon,
  TagIcon,
  ClockIcon,
  DocumentDuplicateIcon,
} from "@heroicons/react/24/outline";

const LogMetadataModal = ({ isOpen, onClose, log }) => {
  const hasBothStates = log?.previousState && log?.newState;
  const metadata = log?.details || log?.metadata || {};
  const [copiedStates, setCopiedStates] = useState({});

  const handleCopy = (key, data) => {
    navigator.clipboard.writeText(JSON.stringify(data, null, 2));
    setCopiedStates((prev) => ({ ...prev, [key]: true }));
    setTimeout(() => {
      setCopiedStates((prev) => ({ ...prev, [key]: false }));
    }, 1500);
  };

  const formatDate = (dateString) => {
    if (!dateString) return "N/A";
    const d = new Date(dateString);
    const day = String(d.getDate()).padStart(2, "0");
    const month = String(d.getMonth() + 1).padStart(2, "0");
    const year = d.getFullYear();
    
    let hours = d.getHours();
    const ampm = hours >= 12 ? "PM" : "AM";
    hours = hours % 12;
    hours = hours ? hours : 12;
    const formattedHours = String(hours).padStart(2, "0");
    
    const minutes = String(d.getMinutes()).padStart(2, "0");
    const seconds = String(d.getSeconds()).padStart(2, "0");
    
    return `${day}/${month}/${year} ${formattedHours}:${minutes}:${seconds} ${ampm}`;
  };

  return (
    <AnimatePresence>
      {isOpen && log && (
        <div className="fixed inset-0 z-100 flex items-center justify-center p-4 md:p-6">
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-slate-950/70 backdrop-blur-md"
          />

          {/* Modal Container */}
          <motion.div
            initial={{ scale: 0.95, opacity: 0, y: 20 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.95, opacity: 0, y: 20 }}
            transition={{ type: "spring", damping: 25, stiffness: 350 }}
            className="relative bg-background-paper/90 backdrop-blur-xl border border-white/10 dark:border-slate-800/50 shadow-2xl rounded-[28px] w-full max-w-2xl max-h-[85vh] flex flex-col overflow-hidden z-10 text-text-theme-primary"
          >
            {/* Header */}
            <div className="p-6 border-b border-border-theme flex justify-between items-center bg-linear-to-r from-background-default/50 to-background-paper/50">
              <div className="flex items-center space-x-4">
                <div className="bg-[#1E90FF]/15 text-[#1E90FF] p-2.5 rounded-2xl border border-[#1E90FF]/20 shadow-xs">
                  <CodeBracketIcon className="w-6 h-6" />
                </div>
                <div>
                  <h2 className="text-xl font-black text-text-theme-primary tracking-tight">
                    Log Details
                  </h2>
                  <p className="text-[10px] text-[#1E90FF] font-black uppercase tracking-widest mt-0.5">
                    {log.action}
                  </p>
                </div>
              </div>
              <button
                onClick={onClose}
                className="p-2 hover:bg-background-default rounded-full transition-all text-text-theme-secondary hover:text-text-theme-primary hover:rotate-90 duration-200 cursor-pointer border-none bg-transparent"
              >
                <XMarkIcon className="w-5 h-5" />
              </button>
            </div>

            {/* Content */}
            <div className="flex-1 overflow-y-auto p-6 bg-background-default/10 custom-scrollbar space-y-6">
              {/* Basic Info Cards */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="bg-background-paper/60 backdrop-blur-xs p-4 rounded-2xl border border-border-theme/60 shadow-xs flex items-center gap-3.5 transition-all hover:border-[#1E90FF]/30">
                  <div className="p-2 bg-[#1E90FF]/5 text-[#1E90FF] rounded-xl">
                    <UserIcon className="w-4 h-4" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-[9px] font-black text-text-theme-secondary uppercase tracking-wider mb-0.5">
                      Actor
                    </p>
                    <p className="text-xs font-bold text-text-theme-primary truncate">
                      {log.userEmail || "System"}
                    </p>
                  </div>
                </div>

                <div className="bg-background-paper/60 backdrop-blur-xs p-4 rounded-2xl border border-border-theme/60 shadow-xs flex items-center gap-3.5 transition-all hover:border-[#1E90FF]/30">
                  <div className="p-2 bg-[#1E90FF]/5 text-[#1E90FF] rounded-xl">
                    <TagIcon className="w-4 h-4" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-[9px] font-black text-text-theme-secondary uppercase tracking-wider mb-0.5">
                      Resource Name
                    </p>
                    <p className="text-xs font-bold text-text-theme-primary truncate">
                      {log.resourceName || log.resource || "N/A"}
                    </p>
                  </div>
                </div>
              </div>

              {/* JSON Data Payloads (Code Editors) */}
              <div className="space-y-5">
                {log.previousState && (
                  <div className="space-y-2">
                    <div className="flex items-center space-x-2">
                      <InformationCircleIcon className="w-4 h-4 text-rose-main" />
                      <span className="text-[10px] font-black text-text-theme-secondary uppercase tracking-widest">
                        Previous State
                      </span>
                    </div>
                    
                    <div className="bg-[#090D16] border border-border-theme rounded-2xl overflow-hidden shadow-lg">
                      <div className="bg-[#0F1422] border-b border-border-theme/80 px-4 py-2 flex items-center justify-between">
                        <div className="flex items-center space-x-2">
                          <span className="w-2 h-2 rounded-full bg-rose-main" />
                          <span className="w-2 h-2 rounded-full bg-amber-500" />
                          <span className="w-2 h-2 rounded-full bg-emerald-main" />
                          <span className="text-[10px] font-mono font-bold text-slate-500 pl-2">
                            previous_state.json
                          </span>
                        </div>
                        <button
                          onClick={() => handleCopy("prev", log.previousState)}
                          className="flex items-center space-x-1.5 text-slate-400 hover:text-primary-main text-[9px] font-black tracking-wider uppercase transition-colors cursor-pointer border-none bg-transparent"
                        >
                          <DocumentDuplicateIcon className="w-3.5 h-3.5" />
                          <span>{copiedStates.prev ? "Copied!" : "Copy"}</span>
                        </button>
                      </div>
                      <div className="p-4 overflow-x-auto max-h-[200px] custom-scrollbar">
                        <pre className="text-[10px] text-rose-main/90 font-mono leading-relaxed">
                          {JSON.stringify(log.previousState, null, 2)}
                        </pre>
                      </div>
                    </div>
                  </div>
                )}

                {log.newState && (
                  <div className="space-y-2">
                    <div className="flex items-center space-x-2">
                      <InformationCircleIcon className="w-4 h-4 text-emerald-main" />
                      <span className="text-[10px] font-black text-text-theme-secondary uppercase tracking-widest">
                        New State
                      </span>
                    </div>

                    <div className="bg-[#090D16] border border-border-theme rounded-2xl overflow-hidden shadow-lg">
                      <div className="bg-[#0F1422] border-b border-border-theme/80 px-4 py-2 flex items-center justify-between">
                        <div className="flex items-center space-x-2">
                          <span className="w-2 h-2 rounded-full bg-rose-main" />
                          <span className="w-2 h-2 rounded-full bg-amber-500" />
                          <span className="w-2 h-2 rounded-full bg-emerald-main" />
                          <span className="text-[10px] font-mono font-bold text-slate-500 pl-2">
                            new_state.json
                          </span>
                        </div>
                        <button
                          onClick={() => handleCopy("new", log.newState)}
                          className="flex items-center space-x-1.5 text-slate-400 hover:text-primary-main text-[9px] font-black tracking-wider uppercase transition-colors cursor-pointer border-none bg-transparent"
                        >
                          <DocumentDuplicateIcon className="w-3.5 h-3.5" />
                          <span>{copiedStates.new ? "Copied!" : "Copy"}</span>
                        </button>
                      </div>
                      <div className="p-4 overflow-x-auto max-h-[200px] custom-scrollbar">
                        <pre className="text-[10px] text-emerald-main/90 font-mono leading-relaxed">
                          {JSON.stringify(log.newState, null, 2)}
                        </pre>
                      </div>
                    </div>
                  </div>
                )}

                {!log.previousState && !log.newState && metadata && (
                  <div className="space-y-2">
                    <div className="flex items-center space-x-2">
                      <InformationCircleIcon className="w-4 h-4 text-primary-main" />
                      <span className="text-[10px] font-black text-text-theme-secondary uppercase tracking-widest">
                        Metadata Payload
                      </span>
                    </div>

                    <div className="bg-[#090D16] border border-border-theme rounded-2xl overflow-hidden shadow-lg">
                      <div className="bg-[#0F1422] border-b border-border-theme/80 px-4 py-2 flex items-center justify-between">
                        <div className="flex items-center space-x-2">
                          <span className="w-2 h-2 rounded-full bg-rose-main" />
                          <span className="w-2 h-2 rounded-full bg-amber-500" />
                          <span className="w-2 h-2 rounded-full bg-emerald-main" />
                          <span className="text-[10px] font-mono font-bold text-slate-500 pl-2">
                            metadata_payload.json
                          </span>
                        </div>
                        <button
                          onClick={() => handleCopy("meta", metadata)}
                          className="flex items-center space-x-1.5 text-slate-400 hover:text-primary-main text-[9px] font-black tracking-wider uppercase transition-colors cursor-pointer border-none bg-transparent"
                        >
                          <DocumentDuplicateIcon className="w-3.5 h-3.5" />
                          <span>{copiedStates.meta ? "Copied!" : "Copy"}</span>
                        </button>
                      </div>
                      <div className="p-4 overflow-x-auto max-h-[300px] custom-scrollbar">
                        <pre className="text-[10px] text-indigo-main font-mono leading-relaxed">
                          {JSON.stringify(metadata, null, 2)}
                        </pre>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              {/* Timestamp Banner */}
              <div className="flex items-center justify-center gap-2 text-xs text-text-theme-secondary bg-background-default/30 py-2.5 px-4 rounded-xl border border-border-theme/40 max-w-md mx-auto shadow-xs">
                <ClockIcon className="w-4 h-4 text-[#1E90FF]" />
                <span className="font-bold">
                  Event occurred on {formatDate(log.createdAt)}
                </span>
              </div>
            </div>

            {/* Footer */}
            <div className="p-4 border-t border-border-theme bg-linear-to-r from-background-default/50 to-background-paper/50 flex justify-end">
              <button
                onClick={onClose}
                className="px-6 py-2.5 bg-[#1E90FF] hover:bg-[#1C64F2] text-white font-bold rounded-xl shadow-md hover:-translate-y-0.5 active:translate-y-0 transition-all cursor-pointer border-none"
              >
                Close Details
              </button>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
};

export default LogMetadataModal;
