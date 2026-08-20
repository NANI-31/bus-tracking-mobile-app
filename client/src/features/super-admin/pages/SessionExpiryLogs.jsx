import React, { useEffect, useState, useCallback } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  ShieldExclamationIcon,
  ClockIcon,
  UserIcon,
  FunnelIcon,
  XMarkIcon,
  ArrowPathIcon,
  TrashIcon,
  CalendarDaysIcon,
  ExclamationTriangleIcon,
} from "@heroicons/react/24/outline";
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Skeleton,
  Tooltip,
  TablePagination,
} from "@mui/material";
import {
  getSessionExpiryLogs,
  getSessionExpiryLogsSummary,
  getSessionExpiryLogDetail,
  purgeSessionExpiryLogsAction,
  getColleges,
} from "../slices/superAdminSlice";
import toast from "react-hot-toast";

// ─── Constants ────────────────────────────────────────────────────────────────

const REASONS = [
  { value: "TOKEN_EXPIRED",          label: "Token Expired",      color: "#F59E0B", bg: "bg-amber-500/15",  text: "text-amber-400"  },
  { value: "TOKEN_VERSION_MISMATCH", label: "Version Mismatch",   color: "#8B5CF6", bg: "bg-violet-500/15", text: "text-violet-400" },
  { value: "USER_DELETED",           label: "User Deleted",       color: "#EF4444", bg: "bg-red-500/15",    text: "text-red-400"    },
  { value: "REFRESH_TOKEN_FAILED",   label: "Refresh Failed",     color: "#F97316", bg: "bg-orange-500/15", text: "text-orange-400" },
  { value: "SOCKET_AUTH_FAILED",     label: "Socket Auth Failed", color: "#06B6D4", bg: "bg-cyan-500/15",   text: "text-cyan-400"   },
  { value: "NO_TOKEN",               label: "No Token",           color: "#6B7280", bg: "bg-slate-500/15",  text: "text-slate-400"  },
  { value: "INVALID_TOKEN",          label: "Invalid Token",      color: "#EC4899", bg: "bg-pink-500/15",   text: "text-pink-400"   },
];
const REASON_MAP = Object.fromEntries(REASONS.map((r) => [r.value, r]));

// ─── Small Helpers ────────────────────────────────────────────────────────────

const ReasonBadge = ({ reason }) => {
  const m = REASON_MAP[reason] || { label: reason, bg: "bg-slate-500/15", text: "text-slate-400" };
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[9px] font-black uppercase tracking-widest ${m.bg} ${m.text}`}>
      {m.label}
    </span>
  );
};

const fmt = (d) =>
  d ? new Date(d).toLocaleString("en-IN", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit", second: "2-digit" }) : "—";

const fmtShort = (d) =>
  d ? new Date(d).toLocaleString("en-IN", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" }) : "—";

const pIcon = (p) => ({ android: "🤖", ios: "🍎", web: "🌐" })[p?.toLowerCase()] ?? "📱";

const TH = ({ children }) => (
  <TableCell sx={{ background: "var(--background-paper)", borderBottom: "1px solid var(--border-theme)", color: "var(--text-secondary)", fontSize: "9px", fontWeight: 900, letterSpacing: "0.1em", textTransform: "uppercase", padding: "10px 12px", whiteSpace: "nowrap" }}>
    {children}
  </TableCell>
);
const TD = ({ children, mono = false }) => (
  <TableCell sx={{ borderBottom: "1px solid var(--border-theme)", padding: "8px 12px" }}>
    <span className={`text-[11px] text-text-theme-secondary ${mono ? "font-mono" : ""}`}>{children}</span>
  </TableCell>
);

// ─── Summary Cards ────────────────────────────────────────────────────────────

const SummaryCards = ({ summary, loading }) => {
  const cards = [
    { title: "Total Events",    value: summary?.totalEvents ?? 0,        sub: `Last ${summary?.days ?? 7} days`,   color: "#1E90FF", bg: "bg-blue-500/10",   icon: <ShieldExclamationIcon className="w-5 h-5" /> },
    { title: "Last 24 Hours",   value: summary?.last24h ?? 0,            sub: "Recent activity",                   color: "#F59E0B", bg: "bg-amber-500/10",  icon: <ClockIcon className="w-5 h-5" /> },
    { title: "Affected Users",  value: summary?.affectedUsersCount ?? 0, sub: "Unique users impacted",             color: "#8B5CF6", bg: "bg-violet-500/10", icon: <UserIcon className="w-5 h-5" /> },
    { title: "Top Reason",      value: REASON_MAP[summary?.topReason]?.label ?? "—", sub: summary?.topReason ?? "No data", color: "#EF4444", bg: "bg-red-500/10", icon: <ExclamationTriangleIcon className="w-5 h-5" />, isText: true },
  ];
  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
      {cards.map((c, i) => (
        <motion.div key={c.title} initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: i * 0.07 }}
          className="p-4 bg-background-paper border border-border-theme rounded-2xl shadow-xs">
          {loading ? (
            <><Skeleton variant="text" width="60%" /><Skeleton variant="text" width="40%" height={40} /><Skeleton variant="text" width="80%" /></>
          ) : (
            <>
              <div className="flex items-center justify-between mb-3">
                <p className="text-[10px] font-black uppercase tracking-widest text-text-theme-secondary">{c.title}</p>
                <div className={`p-1.5 rounded-lg ${c.bg}`} style={{ color: c.color }}>{c.icon}</div>
              </div>
              <p className={`font-black text-text-theme-primary ${c.isText ? "text-sm leading-tight" : "text-2xl"}`}>
                {c.isText ? c.value : c.value.toLocaleString()}
              </p>
              <p className="text-[10px] text-text-theme-secondary mt-1">{c.sub}</p>
            </>
          )}
        </motion.div>
      ))}
    </div>
  );
};

// ─── Daily Bar Chart ─────────────────────────────────────────────────────────

const DailyChart = ({ data, loading }) => {
  if (loading) return (
    <div className="bg-background-paper border border-border-theme rounded-2xl p-5 mb-6">
      <Skeleton variant="text" width="30%" className="mb-4" />
      <div className="flex items-end gap-1 h-28">{Array.from({ length: 7 }).map((_, i) => <Skeleton key={i} variant="rectangular" className="flex-1 rounded-t" height={40 + i * 8} />)}</div>
    </div>
  );
  if (!data?.length) return (
    <div className="bg-background-paper border border-border-theme rounded-2xl p-5 mb-6 h-40 flex items-center justify-center text-text-theme-secondary text-sm">
      No trend data available
    </div>
  );
  const max = Math.max(...data.map((d) => d.count), 1);
  return (
    <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className="bg-background-paper border border-border-theme rounded-2xl p-5 mb-6">
      <div className="flex items-center justify-between mb-4">
        <p className="text-xs font-black uppercase tracking-widest text-text-theme-secondary">Daily Expiry Events</p>
        <span className="text-[10px] text-text-theme-secondary">Last {data.length} days</span>
      </div>
      <div className="flex items-end gap-1 h-28">
        {data.map((d, i) => {
          const pct = Math.max((d.count / max) * 100, 4);
          return (
            <Tooltip key={i} title={`${d._id}: ${d.count} events`} arrow>
              <motion.div className="flex-1 flex flex-col items-center gap-1 cursor-default group"
                initial={{ scaleY: 0 }} animate={{ scaleY: 1 }} transition={{ delay: i * 0.04, duration: 0.3 }} style={{ transformOrigin: "bottom" }}>
                <div className="w-full rounded-t-sm group-hover:opacity-75 transition-opacity"
                  style={{ height: `${pct}%`, background: "linear-gradient(to top, #1E90FF, #00FFD1)" }} />
                <span className="text-[8px] text-text-theme-secondary w-full text-center truncate">{d._id?.slice(5)}</span>
              </motion.div>
            </Tooltip>
          );
        })}
      </div>
    </motion.div>
  );
};

// ─── Reason Breakdown ─────────────────────────────────────────────────────────

const ReasonBreakdown = ({ data, loading, active, onToggle }) => {
  if (loading || !data?.length) return null;
  const total = data.reduce((s, d) => s + d.count, 0);
  return (
    <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className="bg-background-paper border border-border-theme rounded-2xl p-5 mb-6">
      <p className="text-xs font-black uppercase tracking-widest text-text-theme-secondary mb-4">Breakdown by Reason</p>
      <div className="space-y-2.5">
        {data.map((d) => {
          const m = REASON_MAP[d._id] || { label: d._id, color: "#6B7280", text: "text-slate-400" };
          const pct = total > 0 ? ((d.count / total) * 100).toFixed(1) : 0;
          const isActive = active === d._id;
          return (
            <div key={d._id} onClick={() => onToggle(d._id)}
              className={`cursor-pointer rounded-xl p-2.5 border transition-all ${isActive ? "border-[#1E90FF]/40 bg-blue-500/5" : "border-transparent hover:border-border-theme"}`}>
              <div className="flex items-center justify-between mb-1.5">
                <span className={`text-[9px] font-black uppercase tracking-widest ${m.text}`}>{m.label}</span>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-bold text-text-theme-primary">{d.count}</span>
                  <span className="text-[10px] text-text-theme-secondary">{pct}%</span>
                </div>
              </div>
              <div className="w-full h-1 bg-background-default rounded-full overflow-hidden">
                <motion.div initial={{ width: 0 }} animate={{ width: `${pct}%` }} transition={{ duration: 0.5, ease: "easeOut" }}
                  className="h-full rounded-full" style={{ backgroundColor: m.color }} />
              </div>
            </div>
          );
        })}
      </div>
    </motion.div>
  );
};

// ─── Detail Drawer ────────────────────────────────────────────────────────────

const Field = ({ label, value, mono = false }) => (
  <div className="py-2 border-b border-border-theme last:border-0">
    <p className="text-[10px] font-black uppercase tracking-widest text-text-theme-secondary mb-0.5">{label}</p>
    <p className={`text-xs text-text-theme-primary break-all ${mono ? "font-mono" : ""}`}>{value ?? "—"}</p>
  </div>
);

const SectionLabel = ({ label }) => (
  <p className="text-[10px] font-black uppercase tracking-widest text-[#1E90FF] mb-1 mt-4">{label}</p>
);

const DetailDrawer = ({ log, onClose }) => {
  if (!log) return null;
  return (
    <AnimatePresence>
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="fixed inset-0 z-50 flex justify-end" onClick={onClose}>
        <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" />
        <motion.div initial={{ x: "100%" }} animate={{ x: 0 }} exit={{ x: "100%" }} transition={{ type: "spring", damping: 30, stiffness: 300 }}
          className="relative z-10 w-full max-w-md bg-background-paper border-l border-border-theme h-full overflow-y-auto shadow-2xl"
          onClick={(e) => e.stopPropagation()}>
          {/* Header */}
          <div className="sticky top-0 bg-background-paper border-b border-border-theme px-5 py-4 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <ShieldExclamationIcon className="w-5 h-5 text-[#1E90FF]" />
              <span className="font-black text-sm text-text-theme-primary">Expiry Event Detail</span>
            </div>
            <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-white/5 text-text-theme-secondary hover:text-white transition-all">
              <XMarkIcon className="w-4 h-4" />
            </button>
          </div>

          <div className="px-5 py-4 space-y-0.5">
            <div className="mb-4"><ReasonBadge reason={log.reason} /></div>

            <SectionLabel label="User" />
            <Field label="User ID"    value={log.userId}    mono />
            <Field label="Email"      value={log.userEmail} />
            <Field label="Role"       value={log.userRole}  />

            <SectionLabel label="Cause" />
            <Field label="Reason"        value={log.reason}       mono />
            <Field label="Error Name"    value={log.errorName}    mono />
            <Field label="Error Message" value={log.errorMessage} />

            <SectionLabel label="Token Forensics" />
            <Field label="Issued At"            value={fmt(log.tokenIssuedAt)} />
            <Field label="Expired At"           value={fmt(log.tokenExpiredAt)} />
            <Field label="Token Lifetime"       value={log.tokenAgeSeconds != null
              ? `${Math.floor(log.tokenAgeSeconds / 3600)}h ${Math.floor((log.tokenAgeSeconds % 3600) / 60)}m`
              : undefined} />
            <Field label="Version (token)"  value={log.tokenVersion?.toString()}   mono />
            <Field label="Version (DB)"     value={log.dbTokenVersion?.toString()} mono />

            <SectionLabel label="Request" />
            <Field label="Endpoint"  value={log.requestEndpoint} mono />
            <Field label="Method"    value={log.requestMethod}   />
            <Field label="Client IP" value={log.clientIp}        mono />

            <SectionLabel label="Client" />
            <Field label="Platform"    value={log.platform    ? `${pIcon(log.platform)} ${log.platform}` : undefined} />
            <Field label="App Version" value={log.appVersion} mono />

            <SectionLabel label="When" />
            <Field label="Occurred At"    value={fmt(log.occurredAt)} />
            <Field label="Auto-Delete At" value={fmt(log.expiresAt)}  />
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
};

// ─── Main Page ────────────────────────────────────────────────────────────────

const SessionExpiryLogs = () => {
  const dispatch = useDispatch();
  const { sessionExpiryLogs, sessionExpiryLogsTotal, sessionExpiryLogsSummary, sessionExpiryLogsLoading, colleges } =
    useSelector((state) => state.superAdmin);

  const [page, setPage]               = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(50);
  const [filterOpen, setFilterOpen]   = useState(false);
  const [selectedLog, setSelectedLog] = useState(null);
  const [activeReason, setActiveReason] = useState(null);
  const [summaryDays, setSummaryDays] = useState(7);
  const [purgeConfirm, setPurgeConfirm] = useState(false);
  const [purgeLoading, setPurgeLoading] = useState(false);

  const [filters, setFilters] = useState({
    reason: [], platform: "", collegeId: "", startDate: "", endDate: "", userRole: "",
  });

  useEffect(() => { dispatch(getColleges()); }, [dispatch]);

  const buildParams = useCallback(() => {
    const p = { limit: rowsPerPage, skip: page * rowsPerPage };
    if (filters.reason.length)  p.reason    = filters.reason.join(",");
    if (filters.platform)       p.platform  = filters.platform;
    if (filters.collegeId)      p.collegeId = filters.collegeId;
    if (filters.startDate)      p.startDate = filters.startDate;
    if (filters.endDate)        p.endDate   = filters.endDate;
    if (filters.userRole)       p.userRole  = filters.userRole;
    return p;
  }, [filters, page, rowsPerPage]);

  useEffect(() => { dispatch(getSessionExpiryLogs(buildParams())); }, [dispatch, buildParams]);
  useEffect(() => {
    dispatch(getSessionExpiryLogsSummary({ days: summaryDays, ...(filters.collegeId ? { collegeId: filters.collegeId } : {}) }));
  }, [dispatch, summaryDays, filters.collegeId]);

  const setFilter = (key, val) => { setFilters((p) => ({ ...p, [key]: val })); setPage(0); };
  const clearAll  = () => { setFilters({ reason: [], platform: "", collegeId: "", startDate: "", endDate: "", userRole: "" }); setActiveReason(null); setPage(0); };

  const toggleReasonChip = (val) => {
    setFilters((p) => ({ ...p, reason: p.reason.includes(val) ? p.reason.filter((r) => r !== val) : [...p.reason, val] }));
    setPage(0);
  };

  const toggleBreakdown = (val) => {
    const same = activeReason === val;
    setActiveReason(same ? null : val);
    setFilter("reason", same ? [] : [val]);
  };

  const handleRowClick = (log) => {
    dispatch(getSessionExpiryLogDetail(log._id));
    setSelectedLog(log);
  };

  const handlePurge = async () => {
    setPurgeLoading(true);
    try {
      const r = await dispatch(purgeSessionExpiryLogsAction(90)).unwrap();
      toast.success(r.message || "Old logs purged");
      dispatch(getSessionExpiryLogs(buildParams()));
      dispatch(getSessionExpiryLogsSummary({ days: summaryDays }));
    } catch { toast.error("Failed to purge logs"); }
    finally   { setPurgeLoading(false); setPurgeConfirm(false); }
  };

  const refresh = () => {
    dispatch(getSessionExpiryLogs(buildParams()));
    dispatch(getSessionExpiryLogsSummary({ days: summaryDays }));
  };

  const activeCount = [filters.reason.length > 0, !!filters.platform, !!filters.collegeId, !!(filters.startDate || filters.endDate), !!filters.userRole].filter(Boolean).length;

  return (
    <div className="flex-1 overflow-y-auto min-h-0 bg-background-default">
      <div className="max-w-screen-2xl mx-auto px-4 sm:px-6 lg:px-8 py-6">

        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
          <div>
            <h1 className="text-xl font-black text-text-theme-primary flex items-center gap-2">
              <ShieldExclamationIcon className="w-6 h-6 text-[#1E90FF]" />
              Session Expiry Logs
            </h1>
            <p className="text-xs text-text-theme-secondary mt-0.5">Diagnostic log of all authentication failures and token expiry events</p>
          </div>
          <div className="flex items-center gap-2 flex-wrap">
            {/* Time window */}
            <div className="flex items-center gap-1 bg-background-paper border border-border-theme rounded-xl px-2 py-1">
              <CalendarDaysIcon className="w-3.5 h-3.5 text-text-theme-secondary" />
              {[7, 14, 30].map((d) => (
                <button key={d} onClick={() => setSummaryDays(d)}
                  className={`px-2 py-0.5 rounded-lg text-[10px] font-black uppercase transition-all ${summaryDays === d ? "bg-[#1E90FF] text-white" : "text-text-theme-secondary hover:text-text-theme-primary"}`}>
                  {d}d
                </button>
              ))}
            </div>
            {/* Filter */}
            <button onClick={() => setFilterOpen((v) => !v)}
              className={`flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-black border transition-all ${activeCount > 0 ? "bg-[#1E90FF]/10 border-[#1E90FF]/40 text-[#1E90FF]" : "border-border-theme text-text-theme-secondary hover:text-text-theme-primary"}`}>
              <FunnelIcon className="w-3.5 h-3.5" />Filters
              {activeCount > 0 && <span className="ml-1 w-4 h-4 bg-[#1E90FF] text-white rounded-full text-[9px] flex items-center justify-center">{activeCount}</span>}
            </button>
            {/* Refresh */}
            <button onClick={refresh} className="p-2 rounded-xl border border-border-theme text-text-theme-secondary hover:text-text-theme-primary transition-all active:scale-95">
              <ArrowPathIcon className="w-3.5 h-3.5" />
            </button>
            {/* Purge */}
            {!purgeConfirm ? (
              <button onClick={() => setPurgeConfirm(true)} className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-xs font-black border border-red-500/30 text-red-400 hover:bg-red-500/10 transition-all">
                <TrashIcon className="w-3.5 h-3.5" />Purge Old
              </button>
            ) : (
              <div className="flex items-center gap-1">
                <span className="text-[10px] text-red-400 font-bold">Purge logs older than 90d?</span>
                <button onClick={handlePurge} disabled={purgeLoading} className="px-2 py-1 rounded-lg bg-red-500 text-white text-[10px] font-black hover:bg-red-600 disabled:opacity-50">
                  {purgeLoading ? "…" : "Yes"}
                </button>
                <button onClick={() => setPurgeConfirm(false)} className="px-2 py-1 rounded-lg border border-border-theme text-text-theme-secondary text-[10px] font-black">Cancel</button>
              </div>
            )}
          </div>
        </div>

        {/* Filter Panel */}
        <AnimatePresence>
          {filterOpen && (
            <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }} transition={{ duration: 0.25, ease: "easeInOut" }} className="overflow-hidden mb-6">
              <div className="bg-background-paper border border-border-theme rounded-2xl p-5">
                <div className="flex items-center justify-between mb-4">
                  <p className="text-xs font-black uppercase tracking-widest text-text-theme-secondary">Filter Options</p>
                  {activeCount > 0 && <button onClick={clearAll} className="text-[10px] font-black text-red-400 hover:text-red-300 flex items-center gap-1"><XMarkIcon className="w-3 h-3" />Clear All</button>}
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                  {/* Reason chips */}
                  <div>
                    <p className="text-[10px] font-black uppercase tracking-widest text-text-theme-secondary mb-2">Reason</p>
                    <div className="flex flex-wrap gap-1.5">
                      {REASONS.map((r) => {
                        const on = filters.reason.includes(r.value);
                        return (
                          <button key={r.value} onClick={() => toggleReasonChip(r.value)}
                            className={`px-2 py-0.5 rounded-full text-[9px] font-black uppercase tracking-wider border transition-all ${on ? `${r.bg} ${r.text} border-current` : "border-border-theme text-text-theme-secondary hover:border-slate-500"}`}>
                            {r.label}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                  {/* Platform */}
                  <div>
                    <p className="text-[10px] font-black uppercase tracking-widest text-text-theme-secondary mb-2">Platform</p>
                    <div className="flex gap-1.5">
                      {["android", "ios", "web"].map((p) => (
                        <button key={p} onClick={() => setFilter("platform", filters.platform === p ? "" : p)}
                          className={`px-2 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider border transition-all ${filters.platform === p ? "bg-[#1E90FF]/15 text-[#1E90FF] border-[#1E90FF]/40" : "border-border-theme text-text-theme-secondary hover:border-slate-500"}`}>
                          {pIcon(p)} {p}
                        </button>
                      ))}
                    </div>
                  </div>
                  {/* College */}
                  <div>
                    <p className="text-[10px] font-black uppercase tracking-widest text-text-theme-secondary mb-2">College</p>
                    <select value={filters.collegeId} onChange={(e) => setFilter("collegeId", e.target.value)}
                      className="w-full bg-background-default border border-border-theme rounded-xl px-3 py-1.5 text-xs text-text-theme-primary outline-none focus:border-[#1E90FF]">
                      <option value="">All Colleges</option>
                      {(colleges || []).map((c) => <option key={c._id} value={c._id}>{c.name}</option>)}
                    </select>
                  </div>
                  {/* Date */}
                  <div>
                    <p className="text-[10px] font-black uppercase tracking-widest text-text-theme-secondary mb-2">Date Range</p>
                    <div className="flex gap-2">
                      <input type="date" value={filters.startDate} onChange={(e) => setFilter("startDate", e.target.value)}
                        className="flex-1 bg-background-default border border-border-theme rounded-xl px-2 py-1.5 text-xs text-text-theme-primary outline-none focus:border-[#1E90FF]" />
                      <input type="date" value={filters.endDate} onChange={(e) => setFilter("endDate", e.target.value)}
                        className="flex-1 bg-background-default border border-border-theme rounded-xl px-2 py-1.5 text-xs text-text-theme-primary outline-none focus:border-[#1E90FF]" />
                    </div>
                  </div>
                  {/* Role */}
                  <div>
                    <p className="text-[10px] font-black uppercase tracking-widest text-text-theme-secondary mb-2">User Role</p>
                    <select value={filters.userRole} onChange={(e) => setFilter("userRole", e.target.value)}
                      className="w-full bg-background-default border border-border-theme rounded-xl px-3 py-1.5 text-xs text-text-theme-primary outline-none focus:border-[#1E90FF]">
                      <option value="">All Roles</option>
                      <option value="student">Student</option>
                      <option value="driver">Driver</option>
                      <option value="busCoordinator">Coordinator</option>
                      <option value="teacher">Teacher</option>
                      <option value="collegeAdmin">College Admin</option>
                    </select>
                  </div>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Summary Cards */}
        <SummaryCards summary={sessionExpiryLogsSummary} loading={sessionExpiryLogsLoading && !sessionExpiryLogsSummary} />

        {/* Chart + Breakdown */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
          <div className="lg:col-span-2">
            <DailyChart data={sessionExpiryLogsSummary?.recentByDay} loading={sessionExpiryLogsLoading && !sessionExpiryLogsSummary} />
          </div>
          <div>
            <ReasonBreakdown data={sessionExpiryLogsSummary?.byReason} loading={sessionExpiryLogsLoading && !sessionExpiryLogsSummary} active={activeReason} onToggle={toggleBreakdown} />
          </div>
        </div>

        {/* Table */}
        <motion.div initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }} className="bg-background-paper border border-border-theme rounded-2xl overflow-hidden shadow-xs">
          <div className="px-5 py-3.5 border-b border-border-theme flex items-center justify-between">
            <div className="flex items-center gap-2">
              <ShieldExclamationIcon className="w-4 h-4 text-[#1E90FF]" />
              <span className="text-xs font-black uppercase tracking-widest text-text-theme-secondary">Event Log</span>
              <span className="ml-1 px-2 py-0.5 bg-[#1E90FF]/10 text-[#1E90FF] rounded-full text-[10px] font-black">{sessionExpiryLogsTotal.toLocaleString()}</span>
            </div>
            <span className="text-[10px] text-text-theme-secondary hidden sm:block">Click a row to inspect full details</span>
          </div>

          <TableContainer component={Paper} sx={{ background: "transparent", boxShadow: "none" }}>
            <Table size="small" stickyHeader>
              <TableHead>
                <TableRow>
                  <TH>Occurred At</TH>
                  <TH>Reason</TH>
                  <TH>User / Email</TH>
                  <TH>Role</TH>
                  <TH>Platform</TH>
                  <TH>Endpoint</TH>
                  <TH>IP</TH>
                </TableRow>
              </TableHead>
              <TableBody>
                {sessionExpiryLogsLoading
                  ? Array.from({ length: 8 }).map((_, i) => (
                    <TableRow key={i}>{Array.from({ length: 7 }).map((__, j) => (
                      <TableCell key={j} sx={{ borderBottom: "1px solid var(--border-theme)", padding: "8px 12px" }}><Skeleton variant="text" width="80%" /></TableCell>
                    ))}</TableRow>
                  ))
                  : sessionExpiryLogs.length === 0
                  ? (
                    <TableRow>
                      <TableCell colSpan={7} sx={{ textAlign: "center", py: 6, borderBottom: "none" }}>
                        <div className="flex flex-col items-center gap-2 text-text-theme-secondary">
                          <ShieldExclamationIcon className="w-10 h-10 opacity-20" />
                          <p className="text-sm font-bold">No expiry events found</p>
                          <p className="text-xs opacity-60">Try adjusting your filters or time window</p>
                        </div>
                      </TableCell>
                    </TableRow>
                  )
                  : sessionExpiryLogs.map((log) => (
                    <TableRow key={log._id} hover onClick={() => handleRowClick(log)}
                      sx={{ cursor: "pointer", "&:hover": { background: "rgba(255,255,255,0.03)" }, "&:last-child td": { borderBottom: "none" } }}>
                      <TD mono>{fmtShort(log.occurredAt)}</TD>
                      <TableCell sx={{ borderBottom: "1px solid var(--border-theme)", padding: "8px 12px" }}>
                        <ReasonBadge reason={log.reason} />
                      </TableCell>
                      <TableCell sx={{ borderBottom: "1px solid var(--border-theme)", padding: "8px 12px" }}>
                        <div className="flex flex-col">
                          <span className="text-[11px] text-text-theme-primary font-bold truncate max-w-[160px]">{log.userEmail ?? <span className="italic text-text-theme-secondary">anonymous</span>}</span>
                          {log.userId && <span className="text-[9px] text-text-theme-secondary font-mono truncate max-w-[160px]">{log.userId}</span>}
                        </div>
                      </TableCell>
                      <TD>{log.userRole ?? "—"}</TD>
                      <TD>{log.platform ? `${pIcon(log.platform)} ${log.platform}` : "—"}</TD>
                      <TD mono>{log.requestMethod && log.requestEndpoint ? `${log.requestMethod} ${log.requestEndpoint}` : "—"}</TD>
                      <TD mono>{log.clientIp ?? "—"}</TD>
                    </TableRow>
                  ))}
              </TableBody>
            </Table>
          </TableContainer>

          <TablePagination component="div" count={sessionExpiryLogsTotal} page={page}
            onPageChange={(_, p) => setPage(p)} rowsPerPage={rowsPerPage}
            onRowsPerPageChange={(e) => { setRowsPerPage(parseInt(e.target.value, 10)); setPage(0); }}
            rowsPerPageOptions={[25, 50, 100, 200]}
            sx={{ color: "var(--text-secondary)", borderTop: "1px solid var(--border-theme)", ".MuiTablePagination-select": { color: "var(--text-primary)", fontSize: 12 }, ".MuiTablePagination-displayedRows": { fontSize: 11 }, ".MuiSvgIcon-root": { color: "var(--text-secondary)" } }} />
        </motion.div>
      </div>

      {selectedLog && <DetailDrawer log={selectedLog} onClose={() => setSelectedLog(null)} />}
    </div>
  );
};

export default SessionExpiryLogs;
