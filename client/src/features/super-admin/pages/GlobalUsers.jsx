import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  UserGroupIcon,
  TrashIcon,
  MagnifyingGlassIcon,
  EnvelopeIcon,
} from "@heroicons/react/24/outline";
import {
  getGlobalUsers,
  removeGlobalUser,
} from "@/features/super-admin/slices/superAdminSlice";
import DensitySelector from "@/components/common/DensitySelector";
import EmptyState from "@/components/common/EmptyState";

const GlobalUsers = () => {
  const dispatch = useDispatch();
  const { users, loading } = useSelector((state) => state.superAdmin);
  const [search, setSearch] = useState("");
  const [density, setDensity] = useState("default");

  useEffect(() => {
    dispatch(getGlobalUsers());
  }, [dispatch]);

  const filteredUsers = (Array.isArray(users) ? users : []).filter((user) => {
    return (
      user.fullName.toLowerCase().includes(search.toLowerCase()) ||
      user.email.toLowerCase().includes(search.toLowerCase())
    );
  });

  const handleDelete = (userId) => {
    if (
      window.confirm(
        "WARNING: This action is IRREVERSIBLE. Are you sure you want to delete this user from the ENTIRE system?",
      )
    ) {
      dispatch(removeGlobalUser(userId));
    }
  };

  const paddingTh = {
    compact: "px-4 py-2",
    default: "px-6 py-3",
    relaxed: "px-8 py-5",
  }[density] || "px-6 py-3";

  const paddingTd = {
    compact: "px-4 py-2",
    default: "px-6 py-4",
    relaxed: "px-8 py-6",
  }[density] || "px-6 py-4";

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row gap-4 justify-between sm:items-center">
        <h1 className="text-scale-h1 text-slate-800">
          Global User Management
        </h1>
        <div className="flex flex-col sm:flex-row gap-3 sm:items-center w-full sm:w-auto">
          <DensitySelector currentDensity={density} onChange={setDensity} />
          <div className="relative w-full sm:w-80">
            <MagnifyingGlassIcon className="w-5 h-5 absolute left-3 top-2.5 text-slate-400" />
            <input
              type="text"
              placeholder="Search users by name or email..."
              className="pl-10 pr-4 py-2 w-full border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1E90FF] bg-white"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>
      </div>

      <div className="bg-background-paper rounded-xl shadow-sm border border-border-theme overflow-x-auto max-h-[600px] overflow-y-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-slate-50/95 dark:bg-slate-800/95 backdrop-blur-xs sticky top-0 z-10">
            <tr>
              <th className={`${paddingTh} text-left text-scale-table-header text-slate-500`}>
                User
              </th>
              <th className={`${paddingTh} text-left text-scale-table-header text-slate-500`}>
                College ID
              </th>
              <th className={`${paddingTh} text-left text-scale-table-header text-slate-500`}>
                Role
              </th>
              <th className={`${paddingTh} text-right text-scale-table-header text-slate-500`}>
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            <AnimatePresence>
              {filteredUsers.map((user) => (
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
                      <div className="h-10 w-10 rounded-full bg-[#00FFD1] flex items-center justify-center text-[#1E90FF] font-bold shrink-0">
                        {user.fullName.charAt(0)}
                      </div>
                      <div className="ml-4">
                        <div className="text-scale-table-body text-slate-900">
                          {user.fullName}
                        </div>
                        <div className="flex items-center text-sm text-slate-500">
                          <EnvelopeIcon className="w-3 h-3 mr-1" />
                          {user.email}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className={`${paddingTd} whitespace-nowrap`}>
                    <span className="text-sm text-slate-600 font-mono">
                      {user.collegeId || "N/A"}
                    </span>
                  </td>
                  <td className={`${paddingTd} whitespace-nowrap`}>
                    <div className="flex flex-col space-y-1">
                      <span
                        className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full uppercase w-fit ${
                          user.role === "admin"
                            ? "bg-purple-100 text-purple-800"
                            : user.role === "driver"
                              ? "bg-orange-100 text-orange-800"
                              : "bg-slate-100 text-slate-800"
                        }`}
                      >
                        {user.role}
                      </span>
                      {user.isPremium && (
                        <span className="px-2 inline-flex text-[10px] leading-4 font-bold rounded-full bg-amber-100 text-amber-600 border border-amber-200 uppercase w-fit">
                          ★ Premium
                        </span>
                      )}
                    </div>
                  </td>
                  <td className={`${paddingTd} whitespace-nowrap text-right text-sm font-medium`}>
                    <button
                      onClick={() => handleDelete(user._id)}
                      className="text-red-600 hover:text-red-900 bg-red-50 p-2 rounded-lg transition-all active:scale-95 group"
                      title="Delete User Globally"
                    >
                      <TrashIcon className="w-5 h-5 group-hover:scale-110 transition-transform" />
                    </button>
                  </td>
                </motion.tr>
              ))}
            </AnimatePresence>
            {filteredUsers.length === 0 && (
              <tr>
                <td
                  colSpan="4"
                  className="px-6 py-12"
                >
                  <EmptyState 
                    message="No global users found"
                    description="No user records match the specified search phrase."
                    icon={UserGroupIcon}
                  />
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default GlobalUsers;
