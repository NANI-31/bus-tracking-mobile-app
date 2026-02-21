import React, { useState } from "react";
import { Outlet, Link, useLocation, useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import { logout } from "@/features/auth/slices/authSlice";
import {
  ChartBarIcon,
  AcademicCapIcon,
  UserGroupIcon,
  ClipboardDocumentListIcon,
  ArrowLeftOnRectangleIcon,
  Bars3Icon,
  XMarkIcon,
  CreditCardIcon,
  MapPinIcon,
  BellIcon,
  ServerIcon,
  TicketIcon,
  PresentationChartLineIcon,
} from "@heroicons/react/24/outline";
import {
  getActiveSos,
  getSosLogs,
  addSosAlert,
  removeSosAlert,
} from "../features/common/slices/sosSlice";
import { initiateSocketConnection, joinRoom } from "@/services/socket";
import SosAlertBanner from "@/components/common/SosAlertBanner";
import SosManager from "@/components/common/SosManager";

const SuperAdminLayout = () => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const location = useLocation();
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { userInfo, userToken } = useSelector((state) => state.auth);
  const { activeAlerts, sosLogs } = useSelector((state) => state.sos);
  const [isSosManagerOpen, setIsSosManagerOpen] = useState(false);
  const [isBannerDismissed, setIsBannerDismissed] = useState(false);

  React.useEffect(() => {
    if (userInfo && userToken) {
      const socket = initiateSocketConnection(userToken);

      // Super Admin joins global tracking (which now includes global_sos join in backend)
      joinRoom("join_global_tracking");

      // Initial fetch for "all" alerts for super admin
      dispatch(getActiveSos("all"));
      dispatch(getSosLogs("all"));

      socket.on("sos_alert", (alert) => {
        dispatch(addSosAlert(alert));
        setIsBannerDismissed(false);
      });

      socket.on("sos_resolved", (data) => {
        dispatch(removeSosAlert(data));
      });

      return () => {
        socket.off("sos_alert");
        socket.off("sos_resolved");
      };
    }
  }, [userInfo, userToken, dispatch]);

  const handleLogout = () => {
    dispatch(logout());
    navigate("/login");
  };

  const menuItems = [
    { name: "Overview", path: "/super-admin", icon: ChartBarIcon },
    { name: "Colleges", path: "/super-admin/colleges", icon: AcademicCapIcon },
    { name: "Global Users", path: "/super-admin/users", icon: UserGroupIcon },
    {
      name: "Logs",
      path: "/super-admin/audit",
      icon: ClipboardDocumentListIcon,
    },
    { name: "Payments", path: "/super-admin/payments", icon: CreditCardIcon },
    { name: "Coupons", path: "/super-admin/coupons", icon: TicketIcon },
    {
      name: "Analytics",
      path: "/super-admin/analytics",
      icon: PresentationChartLineIcon,
    },
    { name: "Live Map", path: "/super-admin/tracking", icon: MapPinIcon },
    {
      name: "System Analysis",
      path: "/super-admin/analysis",
      icon: ServerIcon,
    },
  ];

  return (
    <div className="flex h-screen bg-[#F5F5F5] overflow-hidden">
      {/* Sidebar */}
      <motion.aside
        initial={{ width: isSidebarOpen ? 260 : 88 }}
        animate={{ width: isSidebarOpen ? 260 : 88 }}
        transition={{ duration: 0.4, cubicBezier: [0.4, 0, 0.2, 1] }}
        className="bg-[#2E3A59] text-white z-20 flex flex-col shadow-[4px_0_15px_rgba(0,0,0,0.1)]"
      >
        <div className="flex items-center justify-between h-20 px-6 border-b border-slate-200/50">
          <AnimatePresence>
            {isSidebarOpen && (
              <motion.div
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -10 }}
                className="flex items-center space-x-2"
              >
                <div className="w-8 h-8 rounded-xl bg-[#1E90FF] flex items-center justify-center shadow-lg shadow-blue-500/20">
                  <ServerIcon className="w-5 h-5 text-white" />
                </div>
                <span className="text-lg font-black tracking-tight text-white">
                  SuperHub
                </span>
              </motion.div>
            )}
          </AnimatePresence>
          <button
            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            className="p-2 rounded-xl hover:bg-[#3d4b6e] text-slate-300 transition-all active:scale-95"
          >
            {isSidebarOpen ? (
              <XMarkIcon className="w-5 h-5" />
            ) : (
              <Bars3Icon className="w-5 h-5" />
            )}
          </button>
        </div>

        <nav className="flex-1 py-6 space-y-1.5 overflow-y-auto px-4">
          {menuItems.map((item) => {
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.name}
                to={item.path}
                className={`flex items-center px-4 py-3 rounded-2xl transition-all duration-300 group ${
                  isActive
                    ? "bg-[#1E90FF] text-white shadow-lg shadow-blue-500/30"
                    : "text-slate-300 hover:bg-[#3d4b6e] hover:text-white"
                }`}
              >
                <item.icon
                  className={`w-5 h-5 shrink-0 transition-transform group-hover:scale-110 ${
                    isActive
                      ? "text-white"
                      : "text-[#00FFD1] group-hover:text-white"
                  }`}
                />
                <AnimatePresence>
                  {isSidebarOpen && (
                    <motion.span
                      initial={{ opacity: 0, x: -10 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: -10 }}
                      className="ml-3 font-bold text-sm tracking-wide whitespace-nowrap"
                    >
                      {item.name}
                    </motion.span>
                  )}
                </AnimatePresence>
              </Link>
            );
          })}
        </nav>

        <div className="p-6 border-t border-slate-700">
          <button
            onClick={handleLogout}
            className="flex items-center w-full px-4 py-3 text-rose-400 hover:bg-rose-500/10 rounded-2xl transition-all font-bold text-sm group"
          >
            <ArrowLeftOnRectangleIcon className="w-5 h-5 shrink-0 group-hover:translate-x-1 transition-transform" />
            <AnimatePresence>
              {isSidebarOpen && (
                <motion.span
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  className="ml-3 whitespace-nowrap"
                >
                  Terminate Session
                </motion.span>
              )}
            </AnimatePresence>
          </button>
        </div>
      </motion.aside>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto p-10">
        <SosAlertBanner
          activeAlerts={activeAlerts}
          onOpenManager={() => setIsSosManagerOpen(true)}
          onDismiss={() => setIsBannerDismissed(true)}
          style={{ display: isBannerDismissed ? "none" : "block" }}
        />

        <SosManager
          isOpen={isSosManagerOpen}
          onClose={() => setIsSosManagerOpen(false)}
          activeAlerts={activeAlerts}
          sosLogs={sosLogs}
        />

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
        >
          <Outlet />
        </motion.div>
      </main>
    </div>
  );
};

export default SuperAdminLayout;
