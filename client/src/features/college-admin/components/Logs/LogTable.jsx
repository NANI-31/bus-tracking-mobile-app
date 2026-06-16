import React from "react";
import { motion, AnimatePresence } from "framer-motion";
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
  Avatar,
  Skeleton,
  Tooltip,
} from "@mui/material";
import {
  ClockIcon,
  CodeBracketIcon,
  ClipboardDocumentListIcon,
} from "@heroicons/react/24/outline";

const LogTable = ({
  auditLogs,
  loading,
  formatDate,
  stringToColor,
  getInitials,
  getResourceIcon,
  setSelectedLog,
}) => {
  return (
    <TableContainer
      component={Paper}
      elevation={0}
      sx={{
        borderRadius: "16px",
        border: "1px solid #f1f5f9",
        overflow: "auto",
      }}
    >
      <Table stickyHeader>
        <TableHead>
          <TableRow>
            <th className="pl-4 pr-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase bg-slate-50 border-l-4 border-transparent">
              TIMESTAMP
            </th>
            <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase bg-slate-50">
              ACTION
            </th>
            <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase bg-slate-50">
              ACTOR
            </th>
            <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase bg-slate-50">
              TARGET
            </th>
            <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase bg-slate-50">
              DETAILS
            </th>
          </TableRow>
        </TableHead>
        <TableBody>
          {loading && (!auditLogs || auditLogs.length === 0) ? (
            [...Array(10)].map((_, i) => (
              <TableRow key={i}>
                <TableCell
                  sx={{
                    py: 2,
                    borderLeft: "4px solid transparent",
                    pl: 2.5,
                  }}
                >
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
                    sx={{ display: "flex", flexDirection: "column", gap: 0.5 }}
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
                  layout
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95 }}
                  hover
                  sx={{
                    transition: "all 0.2s ease-in-out, border-left 0s, background-color 0.2s ease-in-out",
                    "&:hover": {
                      bgcolor: "rgba(30, 144, 255, 0.04) !important",
                      transform: "scale(1.002)",
                    },
                    "&:last-child td, &:last-child th": { border: 0 },
                  }}
                >
                  <TableCell
                    sx={{
                      borderLeft: `4px solid var(--${
                        log.action.includes("DELETE")
                          ? "rose-main"
                          : log.action.includes("CREATE")
                            ? "emerald-main"
                            : "indigo-main"
                      })`,
                      pl: 2.5,
                    }}
                  >
                    <div className="flex items-center text-gray-500 font-medium text-xs">
                      <ClockIcon className="w-4 h-4 mr-2 text-gray-300" />
                      {formatDate(log.createdAt)}
                    </div>
                  </TableCell>
                  <TableCell>
                    <span
                      className={`px-3 py-1.5 inline-flex text-[10px] leading-4 font-black rounded-lg border uppercase tracking-wider shadow-sm transition-all hover:shadow-md ${
                        log.action.includes("DELETE")
                          ? "bg-rose-main/10 text-rose-main border-rose-main/20"
                          : log.action.includes("CREATE")
                            ? "bg-emerald-main/10 text-emerald-main border-emerald-main/20"
                            : "bg-indigo-main/10 text-indigo-main border-indigo-main/20"
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
                          bgcolor: stringToColor(
                            log.userEmail || log.userName || "System",
                          ),
                          color: "#fff",
                          boxShadow: "0 2px 8px -2px rgba(0,0,0,0.2)",
                        }}
                      >
                        {getInitials(log.userEmail || log.userName)}
                      </Avatar>
                      <Typography
                        variant="body2"
                        sx={{ fontWeight: 600, color: "#475569" }}
                      >
                        {log.userEmail || log.userName || "System"}
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
                            ? "bg-emerald-main/10 border-emerald-main/20 text-emerald-main"
                            : "bg-slate-500/10 border-slate-500/20 text-slate-500 dark:text-slate-400"
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
                <div className="flex flex-col items-center text-gray-400">
                  <ClipboardDocumentListIcon className="w-12 h-12 mb-2 opacity-20" />
                  <p className="font-bold">No audit logs found</p>
                </div>
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </TableContainer>
  );
};

export default LogTable;
