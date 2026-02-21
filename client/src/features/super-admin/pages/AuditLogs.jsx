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
  AcademicCapIcon,
  TruckIcon,
  UserGroupIcon,
  MapIcon,
  CalendarIcon,
  Cog6ToothIcon,
  InformationCircleIcon,
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
  Autocomplete,
  TextField,
} from "@mui/material";
import {
  getAuditLogs,
  getColleges,
  addLiveLog,
} from "../slices/superAdminSlice";
import LogMetadataModal from "@/components/common/LogMetadataModal";
import ActivityChart from "@/components/common/ActivityChart";
import { getSocket, initiateSocketConnection } from "@/services/socket";

// Helper for consistency in colors based on string
const stringToColor = (string) => {
  let hash = 0;
  for (let i = 0; i < string.length; i++) {
    hash = string.charCodeAt(i) + ((hash << 5) - hash);
  }
  let color = "#";
  for (let i = 0; i < 3; i++) {
    const value = (hash >> (i * 8)) & 0xff;
    color += `00${value.toString(16)}`.slice(-2);
  }
  return color;
};

const getInitials = (email) => {
  if (!email) return "?";
  return email.split("@")[0].substring(0, 2).toUpperCase();
};

const getResourceIcon = (resource) => {
  switch (resource?.toLowerCase()) {
    case "user":
      return <UserGroupIcon className="w-4 h-4" />;
    case "bus":
      return <TruckIcon className="w-4 h-4" />;
    case "college":
      return <AcademicCapIcon className="w-4 h-4" />;
    case "route":
      return <MapIcon className="w-4 h-4" />;
    case "schedule":
      return <CalendarIcon className="w-4 h-4" />;
    case "config":
      return <Cog6ToothIcon className="w-4 h-4" />;
    default:
      return <InformationCircleIcon className="w-4 h-4" />;
  }
};

const AuditLogs = () => {
  const dispatch = useDispatch();
  const { auditLogs, colleges, loading, logsTotal } = useSelector(
    (state) => state.superAdmin,
  );
  const [filters, setFilters] = useState({
    date: "",
    action: [],
    resource: [],
    collegeId: "",
  });
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(50);
  const [selectedLog, setSelectedLog] = useState(null);
  const dateInputRef = useRef(null);

  useEffect(() => {
    if (colleges.length === 0) {
      dispatch(getColleges());
    }
  }, [dispatch, colleges.length]);

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
    { label: "System Config", value: "SYSTEM_CONFIG_UPDATE" },
    { label: "Login", value: "LOGIN" },
    { label: "Logout", value: "LOGOUT" },
  ];

  const resourceOptions = [
    "User",
    "College",
    "Bus",
    "Route",
    "Schedule",
    "SOS",
  ];

  const { userToken } = useSelector((state) => state.auth);

  useEffect(() => {
    let socket = getSocket();
    if (!socket && userToken) {
      socket = initiateSocketConnection(userToken);
    }

    if (socket) {
      console.log("SETTING UP LIVE LOG LISTENER (GLOBAL)");
      socket.on("new_audit_log", (newLog) => {
        console.log("RECEIVED LIVE LOG (GLOBAL):", newLog);
        const hasFilters = Object.values(filters).some((v) => v !== "");
        // Only add live log if on page 0 and no filters
        if (!hasFilters && page === 0) {
          console.log("ADDING LIVE LOG TO REDUX (GLOBAL)");
          dispatch(addLiveLog(newLog));
        } else {
          console.log(
            "SKIPPING LIVE LOG DUE TO ACTIVE FILTERS OR NOT ON PAGE 0 (GLOBAL)",
            filters,
            page,
          );
        }
      });
    }

    return () => {
      if (socket) {
        console.log("REMOVING LIVE LOG LISTENER (GLOBAL)");
        socket.off("new_audit_log");
      }
    };
  }, [dispatch, filters, userToken, page]);

  const handleFilterChange = (name, value) => {
    setFilters((prev) => ({ ...prev, [name]: value }));
    setPage(0);
  };

  const clearFilters = () => {
    setFilters({ date: "", action: [], resource: [], collegeId: "" });
    setPage(0);
  };

  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString();
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4">
        <h1 className="text-2xl font-bold text-slate-800">System Logs</h1>
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

          {/* College Filter */}
          <div className="relative group">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <AcademicCapIcon className="h-4 w-4 text-slate-400 group-hover:text-indigo-500" />
            </div>
            <select
              value={filters.collegeId}
              onChange={(e) => handleFilterChange("collegeId", e.target.value)}
              className="pl-9 pr-10 py-2 bg-white border-2 border-slate-100 rounded-xl text-sm font-bold text-slate-700 outline-none hover:border-[#1E90FF]/50 transition-all cursor-pointer appearance-none shadow-sm"
            >
              <option value="">All Colleges</option>
              {colleges.map((college) => (
                <option key={college._id} value={college._id}>
                  {college.name}
                </option>
              ))}
            </select>
            <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
              <FunnelIcon className="h-3 w-3 text-slate-400" />
            </div>
          </div>

          {/* Action Filter */}
          <Autocomplete
            multiple
            limitTags={1}
            options={actionOptions}
            getOptionLabel={(option) => option.label}
            value={actionOptions.filter((opt) =>
              filters.action.includes(opt.value),
            )}
            onChange={(e, newValue) => {
              handleFilterChange(
                "action",
                newValue.map((v) => v.value),
              );
            }}
            renderInput={(params) => (
              <TextField
                {...params}
                variant="outlined"
                placeholder="Actions"
                sx={{
                  width: { xs: "100%", md: 240 },
                  "& .MuiOutlinedInput-root": {
                    borderRadius: "12px",
                    bgcolor: "white",
                    "& fieldset": { border: "2px solid #f1f5f9" },
                    "&:hover fieldset": { borderColor: "#1E90FF" },
                    "&.Mui-focused fieldset": { borderColor: "#1E90FF" },
                  },
                }}
              />
            )}
            size="small"
          />

          {/* Resource Filter */}
          <Autocomplete
            multiple
            limitTags={1}
            options={resourceOptions}
            value={filters.resource}
            onChange={(e, newValue) => {
              handleFilterChange("resource", newValue);
            }}
            renderInput={(params) => (
              <TextField
                {...params}
                variant="outlined"
                placeholder="Resources"
                sx={{
                  width: { xs: "100%", md: 200 },
                  "& .MuiOutlinedInput-root": {
                    borderRadius: "12px",
                    bgcolor: "white",
                    "& fieldset": { border: "2px solid #f1f5f9" },
                    "&:hover fieldset": { borderColor: "#1E90FF" },
                    "&.Mui-focused fieldset": { borderColor: "#1E90FF" },
                  },
                }}
              />
            )}
            size="small"
          />

          <div className="relative">
            <button
              onClick={() => dateInputRef.current?.showPicker()}
              className={`flex items-center space-x-2 px-4 py-2 rounded-xl border-2 transition-all shadow-sm ${
                filters.date
                  ? "bg-[#1E90FF] text-white border-[#1E90FF]"
                  : "bg-white text-slate-700 border-slate-200 hover:border-[#1E90FF]/50"
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

          <div className="hidden xl:block text-sm text-slate-500 font-medium bg-slate-100 px-3 py-2 rounded-xl border border-slate-200">
            {Object.values(filters).some((v) => v !== "")
              ? "Filtered"
              : "Showing recent 50 entries"}
          </div>
        </div>
      </div>

      <ActivityChart data={auditLogs} loading={loading} />

      <TableContainer
        component={Paper}
        elevation={0}
        sx={{
          borderRadius: "16px",
          border: "1px solid #e2e8f0",
          overflow: "hidden",
        }}
      >
        <Table stickyHeader>
          <TableHead>
            <TableRow>
              <TableCell
                sx={{ fontWeight: 800, color: "#64748b", bgcolor: "#f8fafc" }}
              >
                TIMESTAMP
              </TableCell>
              <TableCell
                sx={{ fontWeight: 800, color: "#64748b", bgcolor: "#f8fafc" }}
              >
                ACTION
              </TableCell>
              <TableCell
                sx={{ fontWeight: 800, color: "#64748b", bgcolor: "#f8fafc" }}
              >
                ACTOR
              </TableCell>
              <TableCell
                sx={{ fontWeight: 800, color: "#64748b", bgcolor: "#f8fafc" }}
              >
                TARGET
              </TableCell>
              <TableCell
                sx={{ fontWeight: 800, color: "#64748b", bgcolor: "#f8fafc" }}
              >
                DETAILS
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              // Skeleton Rows
              [...Array(10)].map((_, i) => (
                <TableRow key={i}>
                  <TableCell sx={{ py: 2 }}>
                    <Skeleton variant="text" width={140} />
                  </TableCell>
                  <TableCell sx={{ py: 2 }}>
                    <Skeleton variant="rounded" width={100} height={24} />
                  </TableCell>
                  <TableCell sx={{ py: 2 }}>
                    <div className="flex items-center space-x-2">
                      <Skeleton variant="circular" width={32} height={32} />
                      <Skeleton variant="text" width={120} />
                    </div>
                  </TableCell>
                  <TableCell sx={{ py: 2 }}>
                    <Box
                      sx={{
                        display: "flex",
                        flexDirection: "column",
                        gap: 0.5,
                      }}
                    >
                      <Skeleton variant="text" width={150} />
                      <Skeleton variant="text" width={100} height={12} />
                    </Box>
                  </TableCell>
                  <TableCell sx={{ py: 2 }}>
                    <Skeleton variant="circular" width={28} height={28} />
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <AnimatePresence mode="popLayout">
                {auditLogs.map((log) => (
                  <TableRow
                    key={log._id}
                    component={motion.tr}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    hover
                    sx={{
                      transition: "all 0.2s ease-in-out",
                      "&:hover": {
                        bgcolor: "rgba(30, 144, 255, 0.04) !important",
                        transform: "scale(1.002)",
                      },
                      "&:last-child td, &:last-child th": { border: 0 },
                    }}
                  >
                    <TableCell>
                      <div className="flex items-center text-slate-500 font-medium">
                        <ClockIcon className="w-4 h-4 mr-2 text-slate-300" />
                        {formatDate(log.createdAt)}
                      </div>
                    </TableCell>
                    <TableCell>
                      <span
                        className={`px-3 py-1.5 inline-flex text-[10px] leading-4 font-black rounded-lg border uppercase tracking-wider shadow-sm transition-all hover:shadow-md ${
                          log.action.includes("DELETE")
                            ? "bg-red-50 text-red-700 border-red-100"
                            : log.action.includes("CREATE")
                              ? "bg-emerald-50 text-emerald-700 border-emerald-100"
                              : "bg-indigo-50 text-indigo-700 border-indigo-100"
                        }`}
                      >
                        {log.action.replace(/_/g, " ")}
                      </span>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center space-x-3">
                        <Avatar
                          sx={{
                            width: 32,
                            height: 32,
                            fontSize: "0.75rem",
                            fontWeight: 800,
                            bgcolor: stringToColor(log.userEmail || "System"),
                            color: "#fff",
                            boxShadow: "0 2px 8px -2px rgba(0,0,0,0.2)",
                          }}
                        >
                          {getInitials(log.userEmail)}
                        </Avatar>
                        <Typography
                          variant="body2"
                          sx={{ fontWeight: 600, color: "#475569" }}
                        >
                          {log.userEmail}
                        </Typography>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Box
                        sx={{ display: "flex", alignItems: "center", gap: 1.5 }}
                      >
                        <div
                          className={`p-2 rounded-xl border ${
                            log.action.includes("CREATE")
                              ? "bg-emerald-50 border-emerald-100 text-emerald-600"
                              : "bg-slate-50 border-slate-100 text-slate-500"
                          }`}
                        >
                          {getResourceIcon(log.resource)}
                        </div>
                        <Box sx={{ display: "flex", flexDirection: "column" }}>
                          <Typography
                            variant="body2"
                            sx={{ fontWeight: 800, color: "#1e293b" }}
                          >
                            {log.resourceName || log.resource}
                          </Typography>
                          <Typography
                            variant="caption"
                            sx={{
                              color: "#94a3b8",
                              opacity: 0.8,
                              fontFamily: "monospace",
                            }}
                          >
                            {log.resourceId}
                          </Typography>
                        </Box>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Tooltip title="View Metadata" arrow>
                        <button
                          onClick={() => setSelectedLog(log)}
                          className="p-2 text-[#1E90FF] hover:bg-white hover:text-[#1C64F2] rounded-xl transition-all border border-transparent shadow-sm hover:shadow-blue-200/50 hover:border-blue-100 group"
                        >
                          <CodeBracketIcon className="w-5 h-5 group-hover:rotate-12 transition-transform" />
                        </button>
                      </Tooltip>
                    </TableCell>
                  </TableRow>
                ))}
              </AnimatePresence>
            )}
            {!loading && auditLogs.length === 0 && (
              <TableRow>
                <TableCell colSpan={5} align="center" sx={{ py: 10 }}>
                  <div className="flex flex-col items-center text-slate-400">
                    <ClipboardDocumentListIcon className="w-12 h-12 mb-2 opacity-20" />
                    <p className="font-bold">No audit logs found</p>
                  </div>
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      <TablePagination
        rowsPerPageOptions={[25, 50, 100]}
        component="div"
        count={logsTotal}
        rowsPerPage={rowsPerPage}
        page={page}
        onPageChange={handleChangePage}
        onRowsPerPageChange={handleChangeRowsPerPage}
        sx={{
          border: "1px solid #e2e8f0",
          borderTop: 0,
          borderBottomLeftRadius: "16px",
          borderBottomRightRadius: "16px",
          bgcolor: "#f8fafc",
          "& .MuiTablePagination-selectLabel, & .MuiTablePagination-displayedRows":
            {
              fontWeight: 700,
              color: "#64748b",
              fontSize: "0.8rem",
            },
        }}
      />

      <LogMetadataModal
        isOpen={!!selectedLog}
        onClose={() => setSelectedLog(null)}
        log={selectedLog}
      />
    </div>
  );
};

export default AuditLogs;
