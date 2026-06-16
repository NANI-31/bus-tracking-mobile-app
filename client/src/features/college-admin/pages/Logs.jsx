import React, { useEffect, useState, useRef, useMemo } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  ClipboardDocumentListIcon,
  UserIcon,
  ClockIcon,
  CodeBracketIcon,
  CalendarDaysIcon,
  XCircleIcon,
  TagIcon,
  Square3Stack3DIcon,
  FunnelIcon,
  TruckIcon,
  UserGroupIcon,
  MapIcon,
  CalendarIcon,
  Cog6ToothIcon,
  InformationCircleIcon,
  AcademicCapIcon,
  XMarkIcon,
  ChevronDownIcon,
  BookmarkIcon,
} from "@heroicons/react/24/outline";
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Box,
  Typography,
  TablePagination,
  Avatar,
  Skeleton,
  Tooltip,
} from "@mui/material";
import {
  getAuditLogs,
  addLiveLog,
} from "@/features/college-admin/slices/collegeAdminSlice";
import LogMetadataModal from "@/components/common/LogMetadataModal";
import ActivityChart from "@/components/common/ActivityChart";
import { getSocket, initiateSocketConnection } from "@/services/socket";
import LogTable from "../components/Logs/LogTable";
import { stringToColor, getInitials, getResourceIcon } from "@/utils/helpers";
import DatePicker from "@/components/common/DatePicker";

const VirtualList = ({ items, itemHeight = 28, height, children }) => {
  const [scrollTop, setScrollTop] = useState(0);

  const startIndex = Math.max(0, Math.floor(scrollTop / itemHeight) - 2);
  const endIndex = Math.min(
    items.length,
    Math.floor((scrollTop + height) / itemHeight) + 2
  );

  const visibleItems = items.slice(startIndex, endIndex);
  const totalHeight = items.length * itemHeight;
  const offsetY = startIndex * itemHeight;

  return (
    <div
      onScroll={(e) => setScrollTop(e.currentTarget.scrollTop)}
      style={{ height, overflowY: "auto", position: "relative" }}
      className="custom-scrollbar pr-1"
    >
      <div style={{ height: totalHeight, width: "100%", position: "relative" }}>
        <div
          style={{
            transform: `translateY(${offsetY}px)`,
            position: "absolute",
            left: 0,
            right: 0,
          }}
          className="space-y-1"
        >
          {visibleItems.map((item, index) => children(item, startIndex + index))}
        </div>
      </div>
    </div>
  );
};

const CollapsibleSection = ({ title, icon: Icon, isExpanded, onToggle, showBorder = true, children }) => {
  const [isAnimationDone, setIsAnimationDone] = useState(false);

  useEffect(() => {
    if (!isExpanded) {
      setIsAnimationDone(false);
    }
  }, [isExpanded]);

  return (
    <div className={`${showBorder ? "border-b border-border-theme pb-5" : "pb-2"}`}>
      <button
        onClick={onToggle}
        className="w-full flex items-center justify-between text-xs font-black text-text-theme-secondary uppercase tracking-wider mb-1 cursor-pointer group"
      >
        <span className="flex items-center gap-1.5 group-hover:text-text-theme-primary transition-colors">
          <Icon className="w-4 h-4 text-primary-main" /> {title}
        </span>
        <ChevronDownIcon
          className={`w-3.5 h-3.5 text-slate-400 transition-transform duration-200 ${
            isExpanded ? "rotate-180" : ""
          }`}
        />
      </button>
      <AnimatePresence initial={false}>
        {isExpanded && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.25, ease: "easeInOut" }}
            onAnimationComplete={() => {
              if (isExpanded) {
                setIsAnimationDone(true);
              }
            }}
            className={`${isAnimationDone ? "overflow-visible" : "overflow-hidden"} mt-3`}
          >
            {children}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

const LogSummaryWidget = ({ summary, onToggleGroup, isActive }) => {
  const categories = [
    {
      id: "creations",
      title: "Creations",
      count: summary.creations,
      ratio: summary.creationRatio,
      color: "emerald",
      bgLight: "bg-emerald-main/10",
      textClass: "text-emerald-main",
      barClass: "bg-emerald-main",
      activeBorder: "border-emerald-main shadow-emerald-main/10",
      hoverBorder: "hover:border-emerald-main/40",
      icon: (
        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5">
          <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v6m3-3H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      )
    },
    {
      id: "deletions",
      title: "Deletions",
      count: summary.deletions,
      ratio: summary.deletionRatio,
      color: "rose",
      bgLight: "bg-rose-main/10",
      textClass: "text-rose-main",
      barClass: "bg-rose-main",
      activeBorder: "border-rose-main shadow-rose-main/10",
      hoverBorder: "hover:border-rose-main/40",
      icon: (
        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5">
          <path strokeLinecap="round" strokeLinejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
        </svg>
      )
    },
    {
      id: "updates",
      title: "System Updates",
      count: summary.updates,
      ratio: summary.updateRatio,
      color: "indigo",
      bgLight: "bg-indigo-main/10",
      textClass: "text-indigo-main",
      barClass: "bg-indigo-main",
      activeBorder: "border-indigo-main shadow-indigo-main/10",
      hoverBorder: "hover:border-indigo-main/40",
      icon: (
        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5">
          <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0l3.181 3.183a8.25 8.25 0 0013.803-3.7M4.031 9.865a8.25 8.25 0 0113.803-3.7l3.181 3.182m0-4.991v4.99" />
        </svg>
      )
    }
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
      {categories.map((cat) => {
        const active = isActive(cat.id);
        return (
          <motion.div
            key={cat.id}
            onClick={() => onToggleGroup(cat.id)}
            whileHover={{ y: -2 }}
            className={`p-4 bg-background-paper border rounded-2xl cursor-pointer transition-all shadow-xs select-none flex flex-col justify-between ${
              active
                ? `${cat.activeBorder} shadow-md`
                : `border-border-theme ${cat.hoverBorder}`
            }`}
          >
            <div className="flex justify-between items-start">
              <div>
                <p className="text-[10px] font-black uppercase tracking-widest text-text-theme-secondary">
                  {cat.title}
                </p>
                <h4 className="text-2xl font-black text-text-theme-primary mt-1">
                  {cat.count}
                </h4>
              </div>
              <div className={`p-2 rounded-xl ${cat.bgLight} ${cat.textClass}`}>
                {cat.icon}
              </div>
            </div>
            
            <div className="mt-4">
              <div className="flex justify-between text-[10px] font-bold text-text-theme-secondary mb-1">
                <span>Distribution</span>
                <span className={cat.textClass}>{cat.ratio}%</span>
              </div>
              <div className="w-full h-1.5 bg-background-default rounded-full overflow-hidden">
                <motion.div
                  initial={{ width: 0 }}
                  animate={{ width: `${cat.ratio}%` }}
                  transition={{ duration: 0.5, ease: "easeOut" }}
                  className={`h-full ${cat.barClass}`}
                />
              </div>
            </div>
          </motion.div>
        );
      })}
    </div>
  );
};

const FilterContent = ({
  filters,
  handleFilterChange,
  actionOptions,
  resourceOptions,
  presets,
  savePreset,
  deletePreset,
  applyPreset,
}) => {
  const [actionSearch, setActionSearch] = useState("");
  const [newPresetName, setNewPresetName] = useState("");

  const [expandedSections, setExpandedSections] = useState({
    presets: true,
    date: true,
    resources: true,
    actions: true,
  });

  const toggleSection = (section) => {
    setExpandedSections((prev) => ({
      ...prev,
      [section]: !prev[section],
    }));
  };

  const filteredActions = actionOptions.filter((a) =>
    a.label.toLowerCase().includes(actionSearch.toLowerCase())
  );

  const toggleResource = (resource) => {
    const current = filters.resource;
    if (current.includes(resource)) {
      handleFilterChange("resource", current.filter((r) => r !== resource));
    } else {
      handleFilterChange("resource", [...current, resource]);
    }
  };

  const toggleAction = (actionValue) => {
    const current = filters.action;
    if (current.includes(actionValue)) {
      handleFilterChange("action", current.filter((a) => a !== actionValue));
    } else {
      handleFilterChange("action", [...current, actionValue]);
    }
  };

  const handleQuickDate = (type) => {
    const today = new Date();
    if (type === "today") {
      const todayStr = today.toISOString().split("T")[0];
      handleFilterChange("startDate", todayStr);
      handleFilterChange("endDate", todayStr);
    } else if (type === "yesterday") {
      const yesterday = new Date(today);
      yesterday.setDate(today.getDate() - 1);
      const yesterdayStr = yesterday.toISOString().split("T")[0];
      handleFilterChange("startDate", yesterdayStr);
      handleFilterChange("endDate", yesterdayStr);
    } else {
      handleFilterChange("startDate", "");
      handleFilterChange("endDate", "");
    }
  };

  return (
    <div className="space-y-6">
      {/* Saved Presets Section */}
      <CollapsibleSection
        title="Saved Presets"
        icon={BookmarkIcon}
        isExpanded={expandedSections.presets}
        onToggle={() => toggleSection("presets")}
      >
        <div className="space-y-3 pr-1">
          {/* List of Presets */}
          <div className="flex flex-col gap-1.5 max-h-[140px] overflow-y-auto custom-scrollbar">
            {presets.map((preset, idx) => {
              const isMatch =
                JSON.stringify(preset.filters) === JSON.stringify(filters);
              return (
                <div
                  key={idx}
                  onClick={() => applyPreset(preset.filters)}
                  className={`group flex items-center justify-between px-3 py-1.5 text-[11px] rounded-xl border transition-all cursor-pointer ${
                    isMatch
                      ? "border-[#1E90FF] bg-[#1E90FF]/5 text-[#1E90FF] font-bold"
                      : "border-border-theme bg-background-paper text-text-theme-secondary hover:border-[#1E90FF]/30 hover:text-text-theme-primary"
                  }`}
                >
                  <span className="truncate flex items-center gap-1.5">
                    <BookmarkIcon className={`w-3.5 h-3.5 ${isMatch ? "text-[#1E90FF]" : "text-slate-400 group-hover:text-text-theme-primary"}`} />
                    {preset.name}
                  </span>
                  
                  {/* Delete Button */}
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      deletePreset(idx);
                    }}
                    className="opacity-0 group-hover:opacity-100 hover:text-rose-main p-0.5 rounded-md transition-all text-slate-400 cursor-pointer"
                    title="Delete preset"
                  >
                    <XMarkIcon className="w-3.5 h-3.5" />
                  </button>
                </div>
              );
            })}
            
            {presets.length === 0 && (
              <p className="text-[10px] text-slate-400 py-1 text-center font-bold">
                No saved presets.
              </p>
            )}
          </div>

          {/* Save New Preset Input and Action */}
          <div className="border-t border-border-theme pt-3 mt-2 flex flex-col gap-2">
            <input
              type="text"
              placeholder="Preset name (e.g. Bus actions)"
              value={newPresetName}
              onChange={(e) => setNewPresetName(e.target.value)}
              className="w-full px-3 py-1.5 text-[11px] border border-border-theme rounded-lg bg-background-default focus:border-[#1E90FF] focus:outline-none text-text-theme-primary"
            />
            <button
              onClick={() => {
                if (newPresetName.trim()) {
                  savePreset(newPresetName);
                  setNewPresetName("");
                }
              }}
              disabled={!newPresetName.trim()}
              className={`w-full py-2 text-[10px] font-black rounded-lg transition-all text-center flex items-center justify-center gap-1.5 border border-transparent cursor-pointer ${
                newPresetName.trim()
                  ? "bg-[#1E90FF] text-white hover:bg-[#1C64F2]"
                  : "bg-background-default text-text-theme-secondary opacity-60 pointer-events-none"
              }`}
            >
              <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
              </svg>
              Save Current
            </button>
          </div>
        </div>
      </CollapsibleSection>

      {/* Date Filter Section */}
      <CollapsibleSection
        title="Date Filter"
        icon={CalendarDaysIcon}
        isExpanded={expandedSections.date}
        onToggle={() => toggleSection("date")}
      >
        <div className="flex flex-wrap gap-2 mb-3">
          <button
            onClick={() => handleQuickDate("today")}
            className={`px-2.5 py-1.5 text-[10px] font-bold rounded-lg transition-all cursor-pointer ${
              filters.startDate === new Date().toISOString().split("T")[0] &&
              filters.endDate === new Date().toISOString().split("T")[0]
                ? "bg-[#1E90FF] text-white"
                : "bg-background-default text-text-theme-secondary hover:text-text-theme-primary border border-border-theme"
            }`}
          >
            Today
          </button>
          <button
            onClick={() => handleQuickDate("yesterday")}
            className={`px-2.5 py-1.5 text-[10px] font-bold rounded-lg transition-all cursor-pointer ${
              filters.startDate === new Date(Date.now() - 86400000).toISOString().split("T")[0] &&
              filters.endDate === new Date(Date.now() - 86400000).toISOString().split("T")[0]
                ? "bg-[#1E90FF] text-white"
                : "bg-background-default text-text-theme-secondary hover:text-text-theme-primary border border-border-theme"
            }`}
          >
            Yesterday
          </button>
          {(filters.startDate || filters.endDate) && (
            <button
              onClick={() => handleQuickDate("clear")}
              className="px-2.5 py-1.5 text-[10px] font-bold bg-rose-main/10 text-rose-main rounded-lg hover:bg-rose-main/20 cursor-pointer"
            >
              Clear
            </button>
          )}
        </div>
        <div className="flex flex-col gap-2">
          <DatePicker
            value={filters.startDate}
            onChange={(val) => handleFilterChange("startDate", val)}
            placeholder="From Date"
            className="w-full"
          />
          <DatePicker
            value={filters.endDate}
            onChange={(val) => handleFilterChange("endDate", val)}
            placeholder="To Date"
            className="w-full"
          />
        </div>
      </CollapsibleSection>

      {/* Resources Filter Section */}
      <CollapsibleSection
        title="Resources"
        icon={TagIcon}
        isExpanded={expandedSections.resources}
        onToggle={() => toggleSection("resources")}
      >
        <div className="space-y-2 pr-1">
          {resourceOptions.map((resource) => {
            const isChecked = filters.resource.includes(resource);
            return (
              <label
                key={resource}
                className="flex items-center space-x-2.5 p-1 rounded-lg hover:bg-background-default cursor-pointer group"
              >
                <input
                  type="checkbox"
                  checked={isChecked}
                  onChange={() => toggleResource(resource)}
                  className="w-3.5 h-3.5 rounded-sm text-[#1E90FF] border-slate-300 focus:ring-[#1E90FF]"
                />
                <span className={`text-[11px] ${isChecked ? "font-bold text-text-theme-primary" : "text-text-theme-secondary group-hover:text-text-theme-primary"}`}>
                  {resource}
                </span>
              </label>
            );
          })}
        </div>
      </CollapsibleSection>

      {/* Actions Filter Section */}
      <CollapsibleSection
        title="Actions"
        icon={FunnelIcon}
        isExpanded={expandedSections.actions}
        onToggle={() => toggleSection("actions")}
        showBorder={false}
      >
        <input
          type="text"
          placeholder="Search actions..."
          value={actionSearch}
          onChange={(e) => setActionSearch(e.target.value)}
          className="w-full px-3 py-1.5 text-[11px] border border-border-theme rounded-lg bg-background-default focus:border-[#1E90FF] focus:outline-none mb-3 text-text-theme-primary"
        />
        
        {/* Virtualized Action Checklist */}
        <VirtualList items={filteredActions} itemHeight={28} height={140}>
          {(action) => {
            const isChecked = filters.action.includes(action.value);
            return (
              <label
                key={action.value}
                className="flex items-center space-x-2.5 p-1 rounded-lg hover:bg-background-default cursor-pointer group h-[24px]"
              >
                <input
                  type="checkbox"
                  checked={isChecked}
                  onChange={() => toggleAction(action.value)}
                  className="w-3.5 h-3.5 rounded-sm text-[#1E90FF] border-slate-300 focus:ring-[#1E90FF]"
                />
                <span className={`text-[11px] truncate ${isChecked ? "font-bold text-text-theme-primary" : "text-text-theme-secondary group-hover:text-text-theme-primary"}`}>
                  {action.label}
                </span>
              </label>
            );
          }}
        </VirtualList>
        
        {filteredActions.length === 0 && (
          <p className="text-[10px] text-slate-400 py-1 text-center font-bold">No actions match search</p>
        )}
      </CollapsibleSection>
    </div>
  );
};

const Logs = () => {
  const dispatch = useDispatch();
  const { auditLogs, loading, logsTotal } = useSelector(
    (state) => state.collegeAdmin,
  );
  
  const [filters, setFilters] = useState({
    startDate: "",
    endDate: "",
    action: [],
    resource: [],
  });
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(50);
  const [selectedLog, setSelectedLog] = useState(null);
  const [isFilterDrawerOpen, setIsFilterDrawerOpen] = useState(false);

  // Preset filter quick-saves
  const [presets, setPresets] = useState(() => {
    const saved = localStorage.getItem("college_admin_log_presets");
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        console.error(e);
      }
    }
    return [
      {
        name: "Recent Deletions",
        filters: { startDate: "", endDate: "", action: ["BUS_DELETE", "ROUTE_DELETE", "SCHEDULE_DELETE", "USER_DELETE"], resource: [] },
      },
      {
        name: "User Logins",
        filters: { startDate: "", endDate: "", action: ["LOGIN"], resource: [] },
      },
    ];
  });

  const savePreset = (name) => {
    const newPreset = { name, filters };
    const updated = [...presets, newPreset];
    setPresets(updated);
    localStorage.setItem("college_admin_log_presets", JSON.stringify(updated));
  };

  const deletePreset = (index) => {
    const updated = presets.filter((_, i) => i !== index);
    setPresets(updated);
    localStorage.setItem("college_admin_log_presets", JSON.stringify(updated));
  };

  const applyPreset = (presetFilters) => {
    setFilters(presetFilters);
    setPage(0);
  };

  useEffect(() => {
    // Process filters: convert arrays to comma-separated strings for the backend
    const activeFilters = {};
    Object.entries(filters).forEach(([key, value]) => {
      if (Array.isArray(value)) {
        if (value.length > 0) activeFilters[key] = value.join(",");
      } else if (value !== "") {
        activeFilters[key] = value;
      }
    });

    activeFilters.limit = rowsPerPage;
    activeFilters.skip = page * rowsPerPage;
    dispatch(getAuditLogs(activeFilters));
  }, [dispatch, filters, page, rowsPerPage]);

  const { userToken } = useSelector((state) => state.auth);

  useEffect(() => {
    let socket = getSocket();
    if (!socket && userToken) {
      socket = initiateSocketConnection(userToken);
    }

    if (socket) {
      console.log("SETTING UP LIVE LOG LISTENER");
      socket.on("new_audit_log", (newLog) => {
        console.log("RECEIVED LIVE LOG:", newLog);
        const hasFilters = Object.values(filters).some((v) =>
          Array.isArray(v) ? v.length > 0 : v !== "",
        );
        if (!hasFilters && page === 0) {
          console.log("ADDING LIVE LOG TO REDUX");
          dispatch(addLiveLog(newLog));
        } else {
          console.log(
            "SKIPPING LIVE LOG DUE TO ACTIVE FILTERS OR NOT ON PAGE 0",
            filters,
            page,
          );
        }
      });
    }

    return () => {
      if (socket) {
        console.log("REMOVING LIVE LOG LISTENER");
        socket.off("new_audit_log");
      }
    };
  }, [dispatch, filters, userToken, page]);

  const handleFilterChange = (name, value) => {
    setFilters((prev) => ({ ...prev, [name]: value }));
    setPage(0);
  };

  const clearFilters = () => {
    setFilters({ startDate: "", endDate: "", action: [], resource: [] });
    setPage(0);
  };

  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const hasActiveFilters = useMemo(() => {
    return (
      filters.startDate !== "" ||
      filters.endDate !== "" ||
      filters.action.length > 0 ||
      filters.resource.length > 0
    );
  }, [filters]);

  const getActiveChips = () => {
    const chips = [];
    if (filters.startDate || filters.endDate) {
      let label = "Date Range";
      if (filters.startDate && filters.endDate) {
        label = `Date: ${new Date(filters.startDate).toLocaleDateString()} - ${new Date(filters.endDate).toLocaleDateString()}`;
      } else if (filters.startDate) {
        label = `From: ${new Date(filters.startDate).toLocaleDateString()}`;
      } else if (filters.endDate) {
        label = `To: ${new Date(filters.endDate).toLocaleDateString()}`;
      }
      chips.push({
        id: "date",
        label,
        onClear: () => {
          handleFilterChange("startDate", "");
          handleFilterChange("endDate", "");
        },
      });
    }
    if (filters.action.length > 0) {
      chips.push({
        id: "action",
        label: `Actions (${filters.action.length})`,
        onClear: () => handleFilterChange("action", []),
      });
    }
    if (filters.resource.length > 0) {
      chips.push({
        id: "resource",
        label: `Resources (${filters.resource.length})`,
        onClear: () => handleFilterChange("resource", []),
      });
    }
    return chips;
  };

  const summary = useMemo(() => {
    let creations = 0;
    let deletions = 0;
    let updates = 0;

    auditLogs.forEach((log) => {
      if (log.action.includes("CREATE")) {
        creations++;
      } else if (log.action.includes("DELETE")) {
        deletions++;
      } else {
        updates++;
      }
    });

    const total = auditLogs.length || 1;
    const creationRatio = Math.round((creations / total) * 100);
    const deletionRatio = Math.round((deletions / total) * 100);
    const updateRatio = Math.max(0, 100 - creationRatio - deletionRatio);

    return {
      creations,
      deletions,
      updates,
      creationRatio,
      deletionRatio,
      updateRatio,
    };
  }, [auditLogs]);

  const toggleActionFilterGroup = (groupType) => {
    let targetActions = [];
    if (groupType === "creations") {
      targetActions = ["BUS_CREATE", "ROUTE_CREATE", "SCHEDULE_CREATE", "USER_CREATE"];
    } else if (groupType === "deletions") {
      targetActions = ["BUS_DELETE", "ROUTE_DELETE", "SCHEDULE_DELETE", "USER_DELETE"];
    } else if (groupType === "updates") {
      targetActions = [
        "BUS_UPDATE",
        "ROUTE_UPDATE",
        "SCHEDULE_UPDATE",
        "USER_UPDATE",
        "SYSTEM_CONFIG_UPDATE",
        "LOGIN",
        "LOGOUT",
      ];
    }

    const isMatching =
      filters.action.length === targetActions.length &&
      targetActions.every((act) => filters.action.includes(act));

    if (isMatching) {
      handleFilterChange("action", []);
    } else {
      handleFilterChange("action", targetActions);
    }
  };

  const isGroupActive = (groupType) => {
    let targetActions = [];
    if (groupType === "creations") {
      targetActions = ["BUS_CREATE", "ROUTE_CREATE", "SCHEDULE_CREATE", "USER_CREATE"];
    } else if (groupType === "deletions") {
      targetActions = ["BUS_DELETE", "ROUTE_DELETE", "SCHEDULE_DELETE", "USER_DELETE"];
    } else if (groupType === "updates") {
      targetActions = [
        "BUS_UPDATE",
        "ROUTE_UPDATE",
        "SCHEDULE_UPDATE",
        "USER_UPDATE",
        "SYSTEM_CONFIG_UPDATE",
        "LOGIN",
        "LOGOUT",
      ];
    }
    return (
      filters.action.length === targetActions.length &&
      targetActions.every((act) => filters.action.includes(act))
    );
  };

  const actionOptions = [
    { label: "Create Bus", value: "BUS_CREATE" },
    { label: "Update Bus", value: "BUS_UPDATE" },
    { label: "Delete Bus", value: "BUS_DELETE" },
    { label: "Create Route", value: "ROUTE_CREATE" },
    { label: "Update Route", value: "ROUTE_UPDATE" },
    { label: "Delete Route", value: "ROUTE_DELETE" },
    { label: "Create Schedule", value: "SCHEDULE_CREATE" },
    { label: "Update Schedule", value: "SCHEDULE_UPDATE" },
    { label: "Delete Schedule", value: "SCHEDULE_DELETE" },
    { label: "Create User", value: "USER_CREATE" },
    { label: "Update User", value: "USER_UPDATE" },
    { label: "Delete User", value: "USER_DELETE" },
    { label: "Activate Premium", value: "USER_PREMIUM_ACTIVATE" },
    { label: "Bulk Premium", value: "USER_PREMIUM_BULK" },
    { label: "Update Settings", value: "COLLEGE_UPDATE_SETTINGS" },
  ];

  const resourceOptions = [
    "User",
    "College",
    "Bus",
    "Route",
    "Schedule",
    "SOS",
  ];

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
    <div className="space-y-6 text-text-theme-primary">
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-border-theme pb-5">
        <div>
          <h1 className="text-2xl font-black text-text-theme-primary tracking-tight">
            System Logs
          </h1>
          <p className="text-sm font-bold text-text-theme-secondary mt-1">
            History of administrative actions and system events
          </p>
        </div>
        
        {/* Actions Toolbar */}
        <div className="flex items-center gap-3 w-full md:w-auto">
          {/* Mobile Filter Button */}
          <button
            onClick={() => setIsFilterDrawerOpen(true)}
            className="lg:hidden flex items-center justify-center gap-2 px-4 py-2.5 bg-background-paper border border-border-theme text-text-theme-secondary hover:text-text-theme-primary rounded-xl text-xs font-bold shadow-xs hover:border-[#1E90FF]/30 transition-all cursor-pointer w-full"
          >
            <FunnelIcon className="w-4 h-4 text-[#1E90FF]" />
            Filters
            {hasActiveFilters && (
              <span className="bg-rose-main text-white rounded-full w-4 h-4 flex items-center justify-center text-[9px] font-black">
                !
              </span>
            )}
          </button>
        </div>
      </div>

      {/* Grid Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8 items-start">
        {/* Desktop Sidebar Filters */}
        <div className="hidden lg:flex lg:col-span-1 bg-background-paper border border-border-theme rounded-[24px] p-6 shadow-xs sticky top-6 text-text-theme-primary h-[calc(100vh-100px)] flex-col overflow-hidden">
          <div className="flex items-center justify-between border-b border-border-theme pb-4 mb-5 shrink-0">
            <h2 className="text-xs font-black text-text-theme-secondary uppercase tracking-widest flex items-center gap-2">
              <FunnelIcon className="w-4 h-4 text-[#1E90FF]" /> Filters
            </h2>
            {hasActiveFilters && (
              <button
                onClick={clearFilters}
                className="text-[11px] font-bold text-rose-main hover:text-rose-main/80 transition-colors bg-rose-main/10 px-2.5 py-1 rounded-lg cursor-pointer"
              >
                Reset All
              </button>
            )}
          </div>
          <div className="flex-1 overflow-y-auto overflow-x-hidden custom-scrollbar pr-1">
            <FilterContent
              filters={filters}
              handleFilterChange={handleFilterChange}
              actionOptions={actionOptions}
              resourceOptions={resourceOptions}
              presets={presets}
              savePreset={savePreset}
              deletePreset={deletePreset}
              applyPreset={applyPreset}
            />
          </div>
        </div>

        {/* Logs Table and Charts */}
        <div className="lg:col-span-3 space-y-6">
          {/* Active Filter Chips Banner */}
          {hasActiveFilters && (
            <div className="flex flex-wrap items-center gap-2 p-3 bg-background-paper border border-border-theme rounded-2xl shadow-xs">
              <span className="text-[10px] font-black uppercase tracking-wider text-text-theme-secondary mr-1">
                Active:
              </span>
              {getActiveChips().map((chip) => (
                <span
                  key={chip.id}
                  className="inline-flex items-center gap-1 bg-[#1E90FF]/10 text-[#1E90FF] dark:text-[#00FFD1] text-[10px] font-bold px-2.5 py-1 rounded-lg border border-[#1E90FF]/20 shadow-xs"
                >
                  {chip.label}
                  <button
                    onClick={chip.onClear}
                    className="hover:text-rose-main p-0.5 rounded-sm transition-all cursor-pointer text-[#1E90FF] dark:text-[#00FFD1]"
                  >
                    <XCircleIcon className="w-3.5 h-3.5" />
                  </button>
                </span>
              ))}
              <button
                onClick={clearFilters}
                className="text-[11px] font-bold text-rose-main hover:text-rose-main/80 transition-colors ml-auto px-2 py-1 hover:bg-rose-main/5 rounded-lg cursor-pointer"
              >
                Clear All
              </button>
            </div>
          )}

          <ActivityChart data={auditLogs} loading={loading} />

          <LogSummaryWidget
            summary={summary}
            onToggleGroup={toggleActionFilterGroup}
            isActive={isGroupActive}
          />

          <motion.div
            key={JSON.stringify(filters) + loading}
            initial={{ opacity: 0.85, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, ease: "easeOut" }}
          >
            <LogTable
              auditLogs={auditLogs}
              loading={loading}
              formatDate={formatDate}
              stringToColor={stringToColor}
              getInitials={getInitials}
              getResourceIcon={getResourceIcon}
              setSelectedLog={setSelectedLog}
            />
          </motion.div>

          <TablePagination
            rowsPerPageOptions={[25, 50, 100]}
            component="div"
            count={logsTotal}
            rowsPerPage={rowsPerPage}
            page={page}
            onPageChange={handleChangePage}
            onRowsPerPageChange={handleChangeRowsPerPage}
            className="border border-border-theme border-t-0 bg-background-paper rounded-b-[20px]"
            sx={{
              "& .MuiTablePagination-selectLabel, & .MuiTablePagination-displayedRows":
                {
                  fontWeight: 700,
                  color: "#64748b",
                  fontSize: "0.8rem",
                },
            }}
          />
        </div>
      </div>

      {/* Mobile Filters Drawer Overlay & Slide Panel */}
      <AnimatePresence>
        {isFilterDrawerOpen && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 0.5 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsFilterDrawerOpen(false)}
              className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 lg:hidden"
            />
            {/* Slide-out Drawer */}
            <motion.div
              initial={{ x: "100%" }}
              animate={{ x: 0 }}
              exit={{ x: "100%" }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="fixed inset-y-0 right-0 w-80 bg-background-paper text-text-theme-primary z-55 flex flex-col border-l border-border-theme shadow-2xl lg:hidden p-6 overflow-y-auto overflow-x-hidden"
            >
              <div className="flex items-center justify-between border-b border-border-theme pb-4 mb-5">
                <h2 className="text-xs font-black text-text-theme-secondary uppercase tracking-widest flex items-center gap-2">
                  <FunnelIcon className="w-4 h-4 text-[#1E90FF]" /> Filters
                </h2>
                <div className="flex items-center gap-2">
                  {hasActiveFilters && (
                    <button
                      onClick={clearFilters}
                      className="text-[10px] font-black bg-rose-main/10 text-rose-main hover:bg-rose-main/20 px-2.5 py-1.5 rounded-lg transition-all"
                    >
                      Reset
                    </button>
                  )}
                  <button
                    onClick={() => setIsFilterDrawerOpen(false)}
                    className="p-1 hover:bg-background-default rounded-lg transition-all text-text-theme-secondary hover:text-text-theme-primary"
                  >
                    <XMarkIcon className="w-5 h-5" />
                  </button>
                </div>
              </div>
              <div className="flex-1">
                <FilterContent
                  filters={filters}
                  handleFilterChange={handleFilterChange}
                  actionOptions={actionOptions}
                  resourceOptions={resourceOptions}
                  presets={presets}
                  savePreset={savePreset}
                  deletePreset={deletePreset}
                  applyPreset={applyPreset}
                />
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      <LogMetadataModal
        isOpen={!!selectedLog}
        onClose={() => setSelectedLog(null)}
        log={selectedLog}
      />
    </div>
  );
};

export default Logs;
