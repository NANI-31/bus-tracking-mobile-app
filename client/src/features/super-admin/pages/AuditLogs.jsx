import React, { useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  ClipboardDocumentListIcon,
  UserIcon,
  ClockIcon,
  CodeBracketIcon,
} from "@heroicons/react/24/outline";
import { getAuditLogs } from "../slices/superAdminSlice";

const AuditLogs = () => {
  const dispatch = useDispatch();
  const { auditLogs, loading } = useSelector((state) => state.superAdmin);

  useEffect(() => {
    dispatch(getAuditLogs());
  }, [dispatch]);

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString();
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-slate-800">System Audit Logs</h1>
        <div className="text-sm text-slate-500">Showing recent 50 entries</div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-slate-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Timestamp
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Action
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Actor
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Target
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                  Details
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              <AnimatePresence>
                {auditLogs.map((log) => (
                  <motion.tr
                    key={log._id}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    layout
                  >
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-600">
                      <div className="flex items-center">
                        <ClockIcon className="w-4 h-4 mr-1 text-slate-400" />
                        {formatDate(log.createdAt)}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-slate-100 text-slate-800 border border-slate-200">
                        {log.action}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-600">
                      <div className="flex items-center">
                        <UserIcon className="w-4 h-4 mr-1 text-slate-400" />
                        {log.userEmail}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-600">
                      {log.targetId || log.resource || "N/A"}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                      <div className="flex items-center space-x-2 group relative cursor-pointer">
                        <CodeBracketIcon className="w-5 h-5 text-indigo-400" />
                        <span className="text-xs text-indigo-500 underline">
                          View JSON
                        </span>

                        {/* Simple tooltip for details */}
                        <div className="absolute hidden group-hover:block z-10 w-64 p-2 mt-6 -ml-20 overflow-hidden text-xs font-light text-white bg-slate-800 rounded shadow-lg">
                          <pre>
                            {JSON.stringify(
                              log.details || log.metadata,
                              null,
                              2,
                            ) || "No details"}
                          </pre>
                        </div>
                      </div>
                    </td>
                  </motion.tr>
                ))}
              </AnimatePresence>
              {auditLogs.length === 0 && !loading && (
                <tr>
                  <td
                    colSpan="5"
                    className="px-6 py-12 text-center text-slate-500"
                  >
                    <ClipboardDocumentListIcon className="w-16 h-16 mx-auto mb-4 text-slate-300" />
                    No audit logs found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default AuditLogs;
