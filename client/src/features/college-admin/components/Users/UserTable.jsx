import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import EmptyState from "@/components/common/EmptyState";

const UserTable = ({ users, onOpenActions, density = "default" }) => {
  const paddingTh = {
    compact: "px-4 py-2",
    default: "px-6 py-3.5",
    relaxed: "px-8 py-5",
  }[density] || "px-6 py-3.5";

  const paddingTd = {
    compact: "px-4 py-2",
    default: "px-6 py-4",
    relaxed: "px-8 py-6",
  }[density] || "px-6 py-4";

  return (
    <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-x-auto max-h-[600px] overflow-y-auto">
      <table className="min-w-full divide-y divide-slate-100">
        <thead className="bg-slate-50/95 backdrop-blur-xs sticky top-0 z-10">
          <tr>
            <th className={`${paddingTh} text-left text-scale-table-header text-slate-500`}>
              Name
            </th>
            <th className={`${paddingTh} text-left text-scale-table-header text-slate-500`}>
              Role
            </th>
            <th className={`${paddingTh} text-left text-scale-table-header text-slate-500`}>
              Status
            </th>
            <th className={`${paddingTh} text-left text-scale-table-header text-slate-500`}>
              Premium
            </th>
            <th className={`${paddingTh} text-right text-scale-table-header text-slate-500`}>
              Actions
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-slate-100">
          <AnimatePresence>
            {users.map((user) => (
              <motion.tr
                key={user._id}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                layout
                className="hover:bg-slate-50/50 transition-colors"
              >
                <td className={`${paddingTd} whitespace-nowrap`}>
                  <div className="flex items-center">
                    <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold shrink-0">
                      {user.fullName.charAt(0)}
                    </div>
                    <div className="ml-4">
                      <div className="text-scale-table-body text-gray-900">
                        {user.fullName}
                      </div>
                      <div className="text-xs text-gray-500">{user.email}</div>
                    </div>
                  </div>
                </td>
                <td className={`${paddingTd} whitespace-nowrap`}>
                  <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800 uppercase">
                    {user.role}
                  </span>
                </td>
                <td className={`${paddingTd} whitespace-nowrap`}>
                  {user.approved ? (
                    <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                      Approved
                    </span>
                  ) : (
                    <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800">
                      Pending
                    </span>
                  )}
                </td>
                <td className={`${paddingTd} whitespace-nowrap`}>
                  {user.isPremium ? (
                    <div className="flex flex-col">
                      <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-indigo-100 text-[#1E90FF]">
                        Premium
                      </span>
                      <span className="text-[10px] text-gray-400 mt-1">
                        Until {new Date(user.premiumUntil).toLocaleDateString()}
                      </span>
                    </div>
                  ) : (
                    <span className="text-gray-400 text-xs italic">
                      Standard
                    </span>
                  )}
                </td>
                <td className={`${paddingTd} whitespace-nowrap text-right text-sm font-medium`}>
                  <button
                    onClick={() => onOpenActions(user)}
                    className="text-[#1E90FF] hover:text-indigo-900 bg-indigo-50 px-3 py-1.5 rounded-lg transition-all active:scale-95 font-bold"
                  >
                    Open
                  </button>
                </td>
              </motion.tr>
            ))}
          </AnimatePresence>
          {users.length === 0 && (
            <tr>
              <td colSpan="5" className="px-6 py-12">
                <EmptyState 
                  message="No users found"
                  description="Try adjusting your search criteria or selecting a different role filter."
                />
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
};

export default UserTable;
