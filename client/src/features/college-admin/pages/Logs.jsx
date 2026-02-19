import React, { useEffect, useState, useRef } from "react";
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
} from "@heroicons/react/24/outline";
import { getAuditLogs, addLiveLog } from "../slices/collegeAdminSlice";
import LogMetadataModal from "../../../components/common/LogMetadataModal";
import { getSocket, initiateSocketConnection } from "../../../services/socket";

const Logs = () => {
  const dispatch = useDispatch();
  const { auditLogs, loading } = useSelector((state) => state.collegeAdmin);
  const [filters, setFilters] = useState({
    date: "",
    action: "",
    resource: "",
  });
  const [selectedLog, setSelectedLog] = useState(null);
  const dateInputRef = useRef(null);

  useEffect(() => {
    // Remove empty strings from filters
    const activeFilters = Object.fromEntries(
      Object.entries(filters).filter(([_, v]) => v !== ""),
    );
    dispatch(getAuditLogs(activeFilters));
  }, [dispatch, filters]);

  const { user } = useSelector((state) => state.auth);

  useEffect(() => {
    let socket = getSocket();
    if (!socket && user?.token) {
      socket = initiateSocketConnection(user.token);
    }

    if (socket) {
      console.log("SETTING UP LIVE LOG LISTENER");
      socket.on("new_audit_log", (newLog) => {
        console.log("RECEIVED LIVE LOG:", newLog);
        const hasFilters = Object.values(filters).some((v) => v !== "");
        if (!hasFilters) {
          console.log("ADDING LIVE LOG TO REDUX");
          dispatch(addLiveLog(newLog));
        } else {
          console.log("SKIPPING LIVE LOG DUE TO ACTIVE FILTERS", filters);
        }
      });
    }

    return () => {
      if (socket) {
        console.log("REMOVING LIVE LOG LISTENER");
        socket.off("new_audit_log");
      }
    };
  }, [dispatch, filters, user?.token]);

  const handleFilterChange = (name, value) => {
    setFilters((prev) => ({ ...prev, [name]: value }));
  };

  const clearFilters = () => {
    setFilters({ date: "", action: "", resource: "" });
  };

  const actionOptions = [
    { label: "All Actions", value: "" },
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
    { label: "All Resources", value: "" },
    { label: "User", value: "User" },
    { label: "College", value: "College" },
    { label: "Bus", value: "Bus" },
    { label: "Route", value: "Route" },
    { label: "Schedule", value: "Schedule" },
    { label: "SOS", value: "SOS" },
  ];

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString();
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">System Logs</h1>
          <p className="text-sm text-gray-500">
            History of administrative actions and system events
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {Object.values(filters).some((v) => v !== "") && (
            <button
              onClick={clearFilters}
              className="flex items-center space-x-1 text-red-500 hover:text-red-600 font-bold text-sm bg-red-50 px-3 py-2 rounded-xl border border-red-100 transition-all"
            >
              <XCircleIcon className="w-5 h-5" />
              <span>Reset Filters</span>
            </button>
          )}

          {/* Action Filter */}
          <div className="relative group">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <TagIcon className="h-4 w-4 text-gray-400 group-hover:text-blue-500" />
            </div>
            <select
              value={filters.action}
              onChange={(e) => handleFilterChange("action", e.target.value)}
              className="pl-9 pr-10 py-2 bg-white border-2 border-gray-100 rounded-xl text-sm font-bold text-gray-700 outline-none hover:border-blue-400 transition-all cursor-pointer appearance-none shadow-sm"
            >
              {actionOptions.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
            <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
              <FunnelIcon className="h-3 w-3 text-gray-400" />
            </div>
          </div>

          {/* Resource Filter */}
          <div className="relative group">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Square3Stack3DIcon className="h-4 w-4 text-gray-400 group-hover:text-purple-500" />
            </div>
            <select
              value={filters.resource}
              onChange={(e) => handleFilterChange("resource", e.target.value)}
              className="pl-9 pr-10 py-2 bg-white border-2 border-gray-100 rounded-xl text-sm font-bold text-gray-700 outline-none hover:border-purple-400 transition-all cursor-pointer appearance-none shadow-sm"
            >
              {resourceOptions.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
            <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
              <FunnelIcon className="h-3 w-3 text-gray-400" />
            </div>
          </div>

          <div className="relative">
            <button
              onClick={() => dateInputRef.current?.showPicker()}
              className={`flex items-center space-x-2 px-4 py-2 rounded-xl border-2 transition-all shadow-sm ${
                filters.date
                  ? "bg-blue-600 text-white border-blue-600"
                  : "bg-white text-gray-700 border-gray-100 hover:border-blue-400"
              }`}
            >
              <CalendarDaysIcon className="w-5 h-5" />
              <span className="font-bold">
                {filters.date
                  ? new Date(filters.date).toLocaleDateString()
                  : "Select Date"}
              </span>
            </button>
            <input
              type="date"
              ref={dateInputRef}
              onChange={(e) => handleFilterChange("date", e.target.value)}
              className="absolute opacity-0 pointer-events-none"
              value={filters.date}
            />
          </div>

          <div className="hidden lg:block text-sm text-gray-500 font-medium bg-gray-50 px-3 py-2 rounded-xl border border-gray-100">
            {Object.values(filters).some((v) => v !== "")
              ? "Filtered"
              : "Recent 50 entries"}
          </div>
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50/50">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">
                  Timestamp
                </th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">
                  Action
                </th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">
                  Admin
                </th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">
                  Target
                </th>
                <th className="px-6 py-4 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">
                  Details
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-100">
              <AnimatePresence>
                {auditLogs.map((log) => (
                  <motion.tr
                    key={log._id}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    layout
                    className="hover:bg-gray-50/50 transition-colors"
                  >
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">
                      <div className="flex items-center">
                        <ClockIcon className="w-4 h-4 mr-1.5 text-gray-400" />
                        {formatDate(log.createdAt)}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span
                        className={`px-2.5 py-1 inline-flex text-[10px] leading-5 font-black rounded-lg border uppercase tracking-widest ${
                          log.action.includes("DELETE")
                            ? "bg-red-50 text-red-700 border-red-100"
                            : log.action.includes("CREATE")
                              ? "bg-green-50 text-green-700 border-green-100"
                              : "bg-blue-50 text-blue-700 border-blue-100"
                        }`}
                      >
                        {log.action.replace(/_/g, " ")}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600 font-medium">
                      <div className="flex items-center">
                        <UserIcon className="w-4 h-4 mr-1.5 text-gray-400" />
                        {log.userEmail || log.userName || "System"}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700 font-bold">
                      <div className="flex flex-col">
                        <span className="text-gray-900">
                          {log.resourceName || log.resource}
                        </span>
                        <span className="text-[10px] text-gray-400 font-mono italic">
                          {log.resourceId}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <button
                        onClick={() => setSelectedLog(log)}
                        className="flex items-center space-x-2 px-3 py-1.5 bg-indigo-50 text-indigo-600 rounded-xl font-bold hover:bg-indigo-100 transition-all border border-indigo-100 group"
                      >
                        <CodeBracketIcon className="w-5 h-5 text-indigo-400 group-hover:scale-110 transition-transform" />
                        <span className="text-xs">Metadata</span>
                      </button>
                    </td>
                  </motion.tr>
                ))}
              </AnimatePresence>
              {auditLogs.length === 0 && !loading && (
                <tr>
                  <td colSpan="5" className="px-6 py-20 text-center">
                    <div className="flex flex-col items-center">
                      <ClipboardDocumentListIcon className="w-16 h-16 text-gray-200 mb-4" />
                      <p className="text-gray-400 font-bold text-lg">
                        No log entries found
                      </p>
                      <p className="text-gray-300 text-sm">
                        System events will appear here as they occur
                      </p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <LogMetadataModal
        isOpen={!!selectedLog}
        onClose={() => setSelectedLog(null)}
        log={selectedLog}
      />
    </div>
  );
};

export default Logs;
