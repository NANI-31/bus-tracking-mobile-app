import React, { useState, useEffect, useRef, useMemo } from "react";
import { motion } from "framer-motion";
import {
  PlayIcon,
  PauseIcon,
  TrashIcon,
  MagnifyingGlassIcon,
  ArrowDownTrayIcon,
  ArrowPathIcon,
} from "@heroicons/react/24/outline";

const LiveTerminalConsole = ({
  terminalLogs,
  setTerminalLogs,
  isLiveLoggingPaused,
  setIsLiveLoggingPaused,
  terminalSearch,
  setTerminalSearch,
  terminalLevels,
  setTerminalLevels,
}) => {
  const consoleEndRef = useRef(null);
  const [autoScroll, setAutoScroll] = useState(true);
  const [isCopied, setIsCopied] = useState(false);

  // Auto scroll to bottom
  useEffect(() => {
    if (autoScroll && consoleEndRef.current) {
      consoleEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [terminalLogs, autoScroll]);

  // Filter logs by search term and level checkboxes
  const filteredLogs = useMemo(() => {
    return terminalLogs.filter((log) => {
      const level = (log.level || "").toLowerCase();
      
      // Filter by level
      if (level.includes("info") && !terminalLevels.info) return false;
      if (level.includes("warn") && !terminalLevels.warn) return false;
      if (level.includes("error") && !terminalLevels.error) return false;
      if (level.includes("http") && !terminalLevels.http) return false;
      if (level.includes("debug") && !terminalLevels.debug) return false;

      // Filter by search query
      if (terminalSearch.trim()) {
        const query = terminalSearch.toLowerCase();
        const msg = (log.message || "").toLowerCase();
        return msg.includes(query) || level.includes(query);
      }

      return true;
    });
  }, [terminalLogs, terminalLevels, terminalSearch]);

  const toggleLevel = (lvl) => {
    setTerminalLevels((prev) => ({ ...prev, [lvl]: !prev[lvl] }));
  };

  const copyToClipboard = () => {
    const rawText = filteredLogs
      .map((log) => `[${log.timestamp}] [${log.level.toUpperCase()}]: ${log.message}`)
      .join("\n");
    navigator.clipboard.writeText(rawText);
    setIsCopied(true);
    setTimeout(() => setIsCopied(false), 2000);
  };

  const downloadLogs = () => {
    const rawText = filteredLogs
      .map((log) => `[${log.timestamp}] [${log.level.toUpperCase()}]: ${log.message}`)
      .join("\n");
    const blob = new Blob([rawText], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `server-logs-${new Date().toISOString()}.txt`;
    link.click();
    URL.revokeObjectURL(url);
  };

  // Helper to color code logs in terminal
  const getLogColors = (level = "") => {
    const lvl = level.toLowerCase();
    if (lvl.includes("error")) return "text-red-400 font-extrabold";
    if (lvl.includes("warn")) return "text-amber-400 font-bold";
    if (lvl.includes("http")) return "text-fuchsia-400";
    if (lvl.includes("debug")) return "text-cyan-400";
    return "text-emerald-400"; // Info logs green
  };

  return (
    <div className="flex flex-col bg-[#0B0F19] border border-slate-800 rounded-3xl overflow-hidden shadow-2xl h-[calc(100vh-220px)] min-h-[450px]">
      {/* Console Toolbar */}
      <div className="flex flex-col md:flex-row justify-between items-stretch md:items-center gap-4 bg-[#111827] border-b border-slate-800 p-4 shrink-0">
        {/* Level Filters */}
        <div className="flex flex-wrap items-center gap-2">
          {["info", "warn", "error", "http", "debug"].map((lvl) => {
            const active = terminalLevels[lvl];
            const colors = {
              info: "border-emerald-500/20 text-emerald-400 bg-emerald-500/5 hover:bg-emerald-500/10",
              warn: "border-amber-500/20 text-amber-400 bg-amber-500/5 hover:bg-amber-500/10",
              error: "border-red-500/20 text-red-400 bg-red-500/5 hover:bg-red-500/10",
              http: "border-fuchsia-500/20 text-fuchsia-400 bg-fuchsia-500/5 hover:bg-fuchsia-500/10",
              debug: "border-cyan-500/20 text-cyan-400 bg-cyan-500/5 hover:bg-cyan-500/10",
            }[lvl];
            return (
              <button
                key={lvl}
                onClick={() => toggleLevel(lvl)}
                className={`px-3 py-1 text-[11px] font-black uppercase tracking-wider rounded-lg border transition-all cursor-pointer select-none ${
                  active
                    ? `${colors.split(" ")[0]} ${colors.split(" ")[1]} ${colors.split(" ")[2]} border-opacity-100`
                    : "border-slate-800 text-slate-500 bg-transparent hover:text-slate-400 hover:border-slate-700"
                }`}
              >
                {lvl}
              </button>
            );
          })}
        </div>

        {/* Live Search and Control Toolbar */}
        <div className="flex flex-wrap items-center gap-3">
          {/* Search */}
          <div className="relative">
            <MagnifyingGlassIcon className="absolute left-3 top-2.5 h-4 w-4 text-slate-500" />
            <input
              type="text"
              placeholder="Search logs..."
              value={terminalSearch}
              onChange={(e) => setTerminalSearch(e.target.value)}
              className="pl-9 pr-4 py-2 bg-[#0B0F19] border border-slate-800 text-slate-300 placeholder-slate-600 rounded-xl text-xs focus:outline-none focus:border-blue-500/50 w-full sm:w-48 transition-all"
            />
          </div>

          {/* Action buttons */}
          <div className="flex items-center gap-1.5">
            {/* Pause/Play stream */}
            <button
              onClick={() => setIsLiveLoggingPaused(!isLiveLoggingPaused)}
              title={isLiveLoggingPaused ? "Resume Live Stream" : "Pause Live Stream"}
              className={`p-2 rounded-xl border transition-all cursor-pointer ${
                isLiveLoggingPaused
                  ? "bg-amber-500/10 border-amber-500/30 text-amber-400 hover:bg-amber-500/20"
                  : "bg-slate-800/50 border-slate-800 text-slate-400 hover:text-white hover:bg-slate-800"
              }`}
            >
              {isLiveLoggingPaused ? (
                <PlayIcon className="w-4 h-4" />
              ) : (
                <PauseIcon className="w-4 h-4" />
              )}
            </button>

            {/* Clear console */}
            <button
              onClick={() => setTerminalLogs([])}
              title="Clear Console"
              className="p-2 bg-slate-800/50 border border-slate-800 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl transition-all cursor-pointer"
            >
              <TrashIcon className="w-4 h-4" />
            </button>

            {/* Copy Logs */}
            <button
              onClick={copyToClipboard}
              title="Copy visible logs"
              className="p-2 bg-slate-800/50 border border-slate-800 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl transition-all cursor-pointer text-xs font-bold flex items-center gap-1"
            >
              <span className="text-[10px] uppercase font-black px-0.5">
                {isCopied ? "Copied" : "Copy"}
              </span>
            </button>

            {/* Download logs */}
            <button
              onClick={downloadLogs}
              title="Download Logs"
              className="p-2 bg-slate-800/50 border border-slate-800 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl transition-all cursor-pointer"
            >
              <ArrowDownTrayIcon className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Console Display */}
      <div className="flex-1 p-6 font-mono text-xs overflow-y-auto custom-scrollbar select-text space-y-1.5">
        {filteredLogs.map((log, index) => (
          <div key={index} className="flex items-start gap-3 hover:bg-slate-800/20 py-0.5 px-1 rounded-sm leading-relaxed transition-all">
            <span className="text-slate-600 select-none shrink-0">
              [{new Date(log.timestamp).toLocaleTimeString()}]
            </span>
            <span className={`shrink-0 ${getLogColors(log.level)}`}>
              [{log.level.toUpperCase()}]
            </span>
            <span className="text-slate-300 break-all white-space-pre-wrap">
              {log.message}
            </span>
          </div>
        ))}

        {filteredLogs.length === 0 && (
          <div className="flex flex-col items-center justify-center h-full text-slate-600 gap-2">
            <ArrowPathIcon className={`w-8 h-8 ${isLiveLoggingPaused ? "" : "animate-spin"}`} />
            <p className="font-bold">
              {isLiveLoggingPaused
                ? "Live streaming is paused."
                : "Waiting for server-side events..."}
            </p>
          </div>
        )}

        <div ref={consoleEndRef} />
      </div>

      {/* Console Footer Status */}
      <div className="bg-[#111827] border-t border-slate-800 px-6 py-3 flex justify-between items-center text-[10px] text-slate-500 shrink-0 select-none">
        <div className="flex items-center gap-2">
          <span className={`w-2 h-2 rounded-full ${isLiveLoggingPaused ? "bg-amber-500 animate-pulse" : "bg-emerald-500 animate-ping"}`} />
          <span className="font-black uppercase tracking-wider">
            {isLiveLoggingPaused ? "Live Stream Paused" : "Live Streaming Active"}
          </span>
        </div>
        <div className="font-bold">
          Showing {filteredLogs.length} of {terminalLogs.length} logs
        </div>
        <label className="flex items-center gap-1.5 cursor-pointer">
          <input
            type="checkbox"
            checked={autoScroll}
            onChange={(e) => setAutoScroll(e.target.checked)}
            className="rounded-sm border-slate-700 bg-slate-800 text-blue-500 focus:ring-0 focus:ring-offset-0"
          />
          <span className="font-black uppercase tracking-wider">Auto-Scroll</span>
        </label>
      </div>
    </div>
  );
};

export default LiveTerminalConsole;
