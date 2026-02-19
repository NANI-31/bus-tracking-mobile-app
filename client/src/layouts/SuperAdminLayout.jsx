import React, { useState } from "react";
import { Outlet, Link, useLocation, useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import { logout } from "../features/auth/slices/authSlice";
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
} from "@heroicons/react/24/outline";
import {
  getActiveSos,
  getSosLogs,
  addSosAlert,
  removeSosAlert,
} from "../features/common/slices/sosSlice";
import { initiateSocketConnection } from "../services/socket";
import SosAlertBanner from "../components/common/SosAlertBanner";
import SosManager from "../components/common/SosManager";

const SuperAdminLayout = () => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const location = useLocation();
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const { user } = useSelector((state) => state.auth);
  const { activeAlerts, sosLogs } = useSelector((state) => state.sos);
  const [isSosManagerOpen, setIsSosManagerOpen] = useState(false);
  const [isBannerDismissed, setIsBannerDismissed] = useState(false);

  React.useEffect(() => {
    if (user && user.token) {
      const socket = initiateSocketConnection(user.token);

      // Super Admin joins global tracking (which now includes global_sos join in backend)
      socket.emit("join_global_tracking");

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
  }, [user, dispatch]);

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
    { name: "Live Map", path: "/super-admin/tracking", icon: MapPinIcon },
    {
      name: "System Analysis",
      path: "/super-admin/analysis",
      icon: ServerIcon,
    },
  ];

  return (
    <div className="flex h-screen bg-gray-100 overflow-hidden">
      {/* Sidebar */}
      <motion.aside
        initial={{ width: isSidebarOpen ? 240 : 80 }}
        animate={{ width: isSidebarOpen ? 240 : 80 }}
        transition={{ duration: 0.3, type: "spring", stiffness: 100 }}
        className="bg-slate-900 text-white shadow-xl z-20 flex flex-col"
      >
        <div className="flex items-center justify-between h-16 px-4 border-b border-slate-700">
          <AnimatePresence>
            {isSidebarOpen && (
              <motion.span
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="text-xl font-bold bg-linear-to-r from-indigo-400 to-cyan-400 bg-clip-text text-transparent"
              >
                Super Admin
              </motion.span>
            )}
          </AnimatePresence>
          <button
            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            className="p-1 rounded-md hover:bg-slate-800 text-slate-400"
          >
            {isSidebarOpen ? (
              <XMarkIcon className="w-6 h-6" />
            ) : (
              <Bars3Icon className="w-6 h-6" />
            )}
          </button>
        </div>

        <nav className="flex-1 py-4 space-y-1 overflow-y-auto">
          {menuItems.map((item) => {
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.name}
                to={item.path}
                className={`flex items-center px-4 py-3 mx-2 rounded-lg transition-colors ${
                  isActive
                    ? "bg-indigo-600 text-white shadow-lg shadow-indigo-500/30"
                    : "text-slate-400 hover:bg-slate-800 hover:text-white"
                }`}
              >
                <item.icon className="w-6 h-6 shrink-0" />
                <AnimatePresence>
                  {isSidebarOpen && (
                    <motion.span
                      initial={{ opacity: 0, x: -10 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: -10 }}
                      className="ml-3 font-medium whitespace-nowrap"
                    >
                      {item.name}
                    </motion.span>
                  )}
                </AnimatePresence>
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-slate-700">
          <button
            onClick={handleLogout}
            className="flex items-center w-full px-4 py-2 text-red-400 hover:bg-red-500/10 rounded-lg transition-colors"
          >
            <ArrowLeftOnRectangleIcon className="w-6 h-6 shrink-0" />
            <AnimatePresence>
              {isSidebarOpen && (
                <motion.span
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  exit={{ opacity: 0 }}
                  className="ml-3 font-medium whitespace-nowrap"
                >
                  Logout
                </motion.span>
              )}
            </AnimatePresence>
          </button>
        </div>
      </motion.aside>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto bg-slate-50 p-8">
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
