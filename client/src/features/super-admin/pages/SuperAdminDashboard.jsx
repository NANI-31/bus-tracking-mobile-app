import React, { useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion } from "framer-motion";
import {
  AcademicCapIcon,
  UserGroupIcon,
  ShieldCheckIcon,
  ExclamationTriangleIcon,
} from "@heroicons/react/24/outline";
import { getSystemStats } from "@/features/super-admin/slices/superAdminSlice";

const StatCard = ({ title, value, icon: Icon, color, delay }) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ duration: 0.5, delay }}
    className="bg-white rounded-xl shadow-lg border border-slate-100 p-6 flex items-center space-x-4"
  >
    <div className={`p-3 rounded-lg ${color} bg-opacity-10`}>
      <Icon className={`w-8 h-8 ${color.replace("bg-", "text-")}`} />
    </div>
    <div>
      <p className="text-slate-500 text-sm font-medium uppercase tracking-wide">
        {title}
      </p>
      <h3 className="text-3xl font-bold text-slate-800">{value}</h3>
    </div>
  </motion.div>
);

const SuperAdminDashboard = () => {
  const dispatch = useDispatch();
  const { stats, loading } = useSelector((state) => state.superAdmin);

  useEffect(() => {
    dispatch(getSystemStats());
  }, [dispatch]);

  // Fallback data if API fails or returns simpler structure
  const displayStats = stats || {
    totalColleges: 0,
    totalUsers: 0,
    activeAlerts: 0,
    systemHealth: "98%",
  };

  const statItems = [
    {
      title: "Registered Colleges",
      value: displayStats.totalColleges,
      icon: AcademicCapIcon,
      color: "bg-[#1E90FF]",
      delay: 0,
    },
    {
      title: "Total Users",
      value: displayStats.totalUsers,
      icon: UserGroupIcon,
      color: "bg-cyan-600",
      delay: 0.1,
    },
    {
      title: "Active SOS Alerts",
      value: displayStats.activeAlerts,
      icon: ExclamationTriangleIcon,
      color: "bg-red-600",
      delay: 0.2,
    },
    {
      title: "Audit Events (24h)",
      value: "124",
      icon: ShieldCheckIcon,
      color: "bg-emerald-600",
      delay: 0.3,
    },
  ];

  if (loading && !stats) {
    return (
      <div className="p-8 text-center text-slate-500">
        Loading system overview...
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">System Overview</h1>
        <p className="text-slate-500 mt-1">
          Global monitoring and administration console
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {statItems.map((stat) => (
          <StatCard key={stat.title} {...stat} />
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Recent Colleges Panel */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="bg-white rounded-xl shadow-sm border border-slate-200 p-6"
        >
          <h2 className="text-lg font-bold text-slate-800 mb-4">
            New Colleges
          </h2>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <div className="h-10 w-10 rounded-full bg-indigo-100 flex items-center justify-center text-[#1E90FF] font-bold">
                  IT
                </div>
                <div>
                  <p className="font-medium text-slate-800">
                    Institute of Technology
                  </p>
                  <p className="text-xs text-slate-500">Applied 2 mins ago</p>
                </div>
              </div>
              <span className="px-2 py-1 text-xs font-medium bg-yellow-100 text-yellow-800 rounded-full">
                Pending
              </span>
            </div>
            <div className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <div className="h-10 w-10 rounded-full bg-emerald-100 flex items-center justify-center text-emerald-600 font-bold">
                  SC
                </div>
                <div>
                  <p className="font-medium text-slate-800">Science College</p>
                  <p className="text-xs text-slate-500">Verified 2 hours ago</p>
                </div>
              </div>
              <span className="px-2 py-1 text-xs font-medium bg-emerald-100 text-emerald-800 rounded-full">
                Verified
              </span>
            </div>
          </div>
          <button className="w-full mt-4 py-2 text-sm text-[#1E90FF] font-medium hover:bg-indigo-50 rounded-lg transition-colors">
            View All Colleges
          </button>
        </motion.div>

        {/* System Activity Panel */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="bg-white rounded-xl shadow-sm border border-slate-200 p-6"
        >
          <h2 className="text-lg font-bold text-slate-800 mb-4">
            System Alerts
          </h2>
          <div className="space-y-4">
            <div className="flex items-start space-x-3 p-3 bg-red-50 rounded-lg border border-red-100">
              <ExclamationTriangleIcon className="w-5 h-5 text-red-600 mt-0.5" />
              <div>
                <p className="text-sm font-medium text-red-800">
                  High SOS Activity
                </p>
                <p className="text-xs text-red-600">
                  Multiple alerts detected in North Campus region.
                </p>
              </div>
            </div>
            <div className="flex items-start space-x-3 p-3 bg-blue-50 rounded-lg border border-blue-100">
              <ShieldCheckIcon className="w-5 h-5 text-[#1E90FF] mt-0.5" />
              <div>
                <p className="text-sm font-medium text-blue-800">
                  System Update
                </p>
                <p className="text-xs text-[#1E90FF]">
                  Patch v2.1.0 deployed successfully.
                </p>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default SuperAdminDashboard;
