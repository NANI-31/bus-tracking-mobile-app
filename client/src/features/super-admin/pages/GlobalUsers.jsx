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

const GlobalUsers = () => {
  const dispatch = useDispatch();
  const { users, loading } = useSelector((state) => state.superAdmin);
  const [search, setSearch] = useState("");

  useEffect(() => {
    dispatch(getGlobalUsers());
  }, [dispatch]);

  const filteredUsers = users.filter((user) => {
    return (
      user.fullName.toLowerCase().includes(search.toLowerCase()) ||
      user.email.toLowerCase().includes(search.toLowerCase())
    );
  });

  const handleDelete = (userId) => {
    if (
      window.confirm(
        "WARNING: This actions is IRREVERSIBLE. Are you sure you want to delete this user from the ENTIRE system?",
      )
    ) {
      dispatch(removeGlobalUser(userId));
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-slate-800">
          Global User Management
        </h1>
        <div className="relative">
          <MagnifyingGlassIcon className="w-5 h-5 absolute left-3 top-2.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search users by name or email..."
            className="pl-10 pr-4 py-2 w-80 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#1E90FF]"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-slate-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                User
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                College ID
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                Role
              </th>
              <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">
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
                >
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="h-10 w-10 rounded-full bg-[#00FFD1] flex items-center justify-center text-[#1E90FF] font-bold">
                        {user.fullName.charAt(0)}
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-slate-900">
                          {user.fullName}
                        </div>
                        <div className="flex items-center text-sm text-slate-500">
                          <EnvelopeIcon className="w-3 h-3 mr-1" />
                          {user.email}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="text-sm text-slate-600 font-mono">
                      {user.collegeId || "N/A"}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex flex-col space-y-1">
                      <span
                        className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full uppercase ${
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
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <button
                      onClick={() => handleDelete(user._id)}
                      className="text-red-600 hover:text-red-900 bg-red-50 p-2 rounded-lg transition-colors group"
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
                  className="px-6 py-12 text-center text-slate-500"
                >
                  No users found.
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
