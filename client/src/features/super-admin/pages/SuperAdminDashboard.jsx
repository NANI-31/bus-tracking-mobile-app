import React, { useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion } from "framer-motion";
import {
  AcademicCapIcon,
  UserGroupIcon,
  ShieldCheckIcon,
  ExclamationTriangleIcon,
  MapIcon,
  WrenchScrewdriverIcon,
} from "@heroicons/react/24/outline";
import { getSystemStats } from "@/features/super-admin/slices/superAdminSlice";

const StatCard = ({ title, value, icon: Icon, bgClass, textClass, delay }) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ type: "spring", stiffness: 100, damping: 15, delay }}
    whileHover={{ 
      y: -6, 
      scale: 1.025, 
      transition: { type: "spring", stiffness: 400, damping: 17 } 
    }}
    className="bg-background-paper rounded-[24px] border border-border-theme p-4 sm:p-6 flex items-center space-x-3.5 sm:space-x-4 shadow-sm hover:shadow-xl hover:shadow-primary-main/10 transition-all duration-300 cursor-pointer group text-text-theme-primary"
  >
    <div className={`p-3 sm:p-4 rounded-xl sm:rounded-2xl ${bgClass} transition-transform duration-300 group-hover:scale-110 shrink-0`}>
      <Icon className={`w-7 h-7 ${textClass}`} />
    </div>
    <div className="min-w-0 flex-1">
      <p className="text-text-theme-secondary text-[9px] sm:text-xs font-black uppercase tracking-widest mb-1 truncate">
        {title}
      </p>
      <h3 className="text-lg sm:text-2xl md:text-3xl font-black text-text-theme-primary tracking-tight truncate">{value}</h3>
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
    googleApiUsageCount: 0,
    maintenanceMode: false,
  };

  const statItems = [
    {
      title: "Registered Colleges",
      value: displayStats.totalColleges,
      icon: AcademicCapIcon,
      bgClass: "bg-[#1E90FF]/10 dark:bg-[#1E90FF]/15",
      textClass: "text-[#1E90FF]",
      delay: 0,
    },
    {
      title: "Total Users",
      value: displayStats.totalUsers,
      icon: UserGroupIcon,
      bgClass: "bg-cyan-600/10 dark:bg-cyan-500/15",
      textClass: "text-cyan-600 dark:text-cyan-400",
      delay: 0.1,
    },
    {
      title: "Active SOS Alerts",
      value: displayStats.activeAlerts,
      icon: ExclamationTriangleIcon,
      bgClass: "bg-red-600/10 dark:bg-red-500/15",
      textClass: "text-red-600 dark:text-red-400",
      delay: 0.2,
    },
    {
      title: "Audit Events (24h)",
      value: "124",
      icon: ShieldCheckIcon,
      bgClass: "bg-emerald-600/10 dark:bg-emerald-500/15",
      textClass: "text-emerald-600 dark:text-emerald-400",
      delay: 0.3,
    },
    {
      title: "Google API Calls",
      value: displayStats.googleApiUsageCount || 0,
      icon: MapIcon,
      bgClass: "bg-teal-600/10 dark:bg-teal-500/15",
      textClass: "text-teal-600 dark:text-teal-400",
      delay: 0.4,
    },
    {
      title: "Maintenance Mode",
      value: displayStats.maintenanceMode ? "Active" : "Inactive",
      icon: WrenchScrewdriverIcon,
      bgClass: displayStats.maintenanceMode
        ? "bg-amber-600/10 dark:bg-amber-500/15"
        : "bg-slate-600/10 dark:bg-slate-500/15",
      textClass: displayStats.maintenanceMode
        ? "text-amber-600 dark:text-amber-400"
        : "text-slate-600 dark:text-slate-400",
      delay: 0.5,
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
    <div className="space-y-6 sm:space-y-8">
      <div>
        <h1 className="text-scale-h1 text-slate-900">System Overview</h1>
        <p className="text-slate-500 text-xs sm:text-sm mt-1">
          Global monitoring and administration console
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
        {statItems.map((stat) => (
          <StatCard key={stat.title} {...stat} />
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 lg:gap-8">
        {/* Recent Colleges Panel */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="bg-background-paper rounded-xl shadow-sm border border-border-theme p-6 text-text-theme-primary transition-all duration-300"
        >
          <h2 className="text-scale-h3 text-text-theme-primary mb-4">
            New Colleges
          </h2>
          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 bg-background-default/50 border border-border-theme/40 rounded-lg">
              <div className="flex items-center space-x-3">
                <div className="h-10 w-10 rounded-full bg-indigo-100 dark:bg-indigo-950/50 flex items-center justify-center text-[#1E90FF] font-bold">
                  IT
                </div>
                <div>
                  <p className="font-medium text-text-theme-primary">
                    Institute of Technology
                  </p>
                  <p className="text-xs text-text-theme-secondary">Applied 2 mins ago</p>
                </div>
              </div>
              <span className="px-2 py-1 text-xs font-medium bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-300 rounded-full">
                Pending
              </span>
            </div>
            <div className="flex items-center justify-between p-3 bg-background-default/50 border border-border-theme/40 rounded-lg">
              <div className="flex items-center space-x-3">
                <div className="h-10 w-10 rounded-full bg-emerald-100 dark:bg-emerald-950/50 flex items-center justify-center text-emerald-600 font-bold">
                  SC
                </div>
                <div>
                  <p className="font-medium text-text-theme-primary">Science College</p>
                  <p className="text-xs text-text-theme-secondary">Verified 2 hours ago</p>
                </div>
              </div>
              <span className="px-2 py-1 text-xs font-medium bg-emerald-100 dark:bg-emerald-900/30 text-emerald-800 dark:text-emerald-300 rounded-full">
                Verified
              </span>
            </div>
          </div>
          <button className="w-full mt-4 py-2 text-sm text-[#1E90FF] font-medium hover:bg-indigo-500/10 rounded-lg transition-colors cursor-pointer">
            View All Colleges
          </button>
        </motion.div>

        {/* System Activity Panel */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="bg-background-paper rounded-xl shadow-sm border border-border-theme p-6 text-text-theme-primary transition-all duration-300"
        >
          <h2 className="text-scale-h3 text-text-theme-primary mb-4">
            System Alerts
          </h2>
          <div className="space-y-4">
            <div className="flex items-start space-x-3 p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
              <ExclamationTriangleIcon className="w-5 h-5 text-red-600 dark:text-red-400 mt-0.5 shrink-0" />
              <div>
                <p className="text-sm font-medium text-red-700 dark:text-red-300">
                  High SOS Activity
                </p>
                <p className="text-xs text-red-600 dark:text-red-400/80">
                  Multiple alerts detected in North Campus region.
                </p>
              </div>
            </div>
            <div className="flex items-start space-x-3 p-3 bg-blue-500/10 border border-blue-500/20 rounded-lg">
              <ShieldCheckIcon className="w-5 h-5 text-[#1E90FF] dark:text-blue-400 mt-0.5 shrink-0" />
              <div>
                <p className="text-sm font-medium text-blue-700 dark:text-blue-300">
                  System Update
                </p>
                <p className="text-xs text-[#1E90FF] dark:text-blue-400/80">
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
