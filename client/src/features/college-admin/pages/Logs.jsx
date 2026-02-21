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
  TruckIcon,
  UserGroupIcon,
  MapIcon,
  CalendarIcon,
  Cog6ToothIcon,
  InformationCircleIcon,
  AcademicCapIcon,
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
  addLiveLog,
} from "@/features/college-admin/slices/collegeAdminSlice";
import LogMetadataModal from "@/components/common/LogMetadataModal";
import ActivityChart from "@/components/common/ActivityChart";
import { getSocket, initiateSocketConnection } from "@/services/socket";
import LogTable from "../components/Logs/LogTable";
import LogFilters from "../components/Logs/LogFilters";
import { stringToColor, getInitials, getResourceIcon } from "@/utils/helpers"; // Assuming I move these or just keep them for now. Wait, I should check if they exist in utils. If not, I'll define them in a shared place or just pass them.

const Logs = () => {
  const dispatch = useDispatch();
  const { auditLogs, loading, logsTotal } = useSelector(
    (state) => state.collegeAdmin,
  );
  const [filters, setFilters] = useState({
    date: "",
    action: [],
    resource: [],
  });
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(50);
  const [selectedLog, setSelectedLog] = useState(null);
  const dateInputRef = useRef(null);

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

  const { userInfo, userToken } = useSelector((state) => state.auth);

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
    setFilters({ date: "", action: [], resource: [] });
    setPage(0);
  };

  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
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

        <LogFilters
          filters={filters}
          handleFilterChange={handleFilterChange}
          clearFilters={clearFilters}
          actionOptions={actionOptions}
          resourceOptions={resourceOptions}
          dateInputRef={dateInputRef}
        />
      </div>

      <ActivityChart data={auditLogs} loading={loading} />

      <LogTable
        auditLogs={auditLogs}
        loading={loading}
        formatDate={formatDate}
        stringToColor={stringToColor}
        getInitials={getInitials}
        getResourceIcon={getResourceIcon}
        setSelectedLog={setSelectedLog}
      />

      <TablePagination
        rowsPerPageOptions={[25, 50, 100]}
        component="div"
        count={logsTotal}
        rowsPerPage={rowsPerPage}
        page={page}
        onPageChange={handleChangePage}
        onRowsPerPageChange={handleChangeRowsPerPage}
        sx={{
          border: "1px solid #f1f5f9",
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

export default Logs;
