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
  ServerIcon,
  TicketIcon,
  PresentationChartLineIcon,
  SunIcon,
  MoonIcon,
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
import Breadcrumbs from "@/components/common/Breadcrumbs";
import NetworkStatusIndicator from "@/components/common/NetworkStatusIndicator";

const SuperAdminLayout = () => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const location = useLocation();
  const dispatch = useDispatch();
  const navigate = useNavigate();

  const [theme, setTheme] = useState(() => {
    const saved = localStorage.getItem("theme");
    if (saved) return saved;
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  });

  React.useEffect(() => {
    if (theme === "dark") {
      document.documentElement.classList.add("dark");
      document.documentElement.classList.remove("light");
    } else {
      document.documentElement.classList.add("light");
      document.documentElement.classList.remove("dark");
    }
    localStorage.setItem("theme", theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme((prev) => (prev === "dark" ? "light" : "dark"));
  };
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

  const sidebarContent = (isMobile = false) => (
    <>
      <div className="flex items-center justify-between h-20 px-6 border-b border-slate-200/50">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 rounded-xl bg-[#1E90FF] flex items-center justify-center shadow-lg shadow-blue-500/20">
            <ServerIcon className="w-5 h-5 text-white" />
          </div>
          {(isSidebarOpen || isMobile) && (
            <span className="text-lg font-black tracking-tight text-white">
              SuperHub
            </span>
          )}
        </div>
        {!isMobile && (
          <button
            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            className="p-2 rounded-xl hover:bg-[#3d4b6e] text-slate-300 transition-all active:scale-95 hidden lg:block"
          >
            {isSidebarOpen ? (
              <XMarkIcon className="w-5 h-5" />
            ) : (
              <Bars3Icon className="w-5 h-5" />
            )}
          </button>
        )}
        {isMobile && (
          <button
            onClick={() => setIsMobileMenuOpen(false)}
            className="p-2 rounded-xl hover:bg-[#3d4b6e] text-slate-300 transition-all active:scale-95 lg:hidden"
          >
            <XMarkIcon className="w-5 h-5" />
          </button>
        )}
      </div>

      <nav className="flex-1 py-6 space-y-1.5 overflow-y-auto overflow-x-hidden px-4">
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <Link
              key={item.name}
              to={item.path}
              onClick={() => isMobile && setIsMobileMenuOpen(false)}
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
                {(isSidebarOpen || isMobile) && (
                  <motion.span
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -10 }}
                    className="ml-3 text-scale-sidebar whitespace-nowrap"
                  >
                    {item.name}
                  </motion.span>
                )}
              </AnimatePresence>
            </Link>
          );
        })}
      </nav>

      <div className="p-6 border-t border-slate-700 space-y-1">
        <button
          onClick={toggleTheme}
          className="flex items-center w-full px-4 py-3 text-slate-350 hover:bg-white/5 rounded-2xl transition-all font-bold text-sm group cursor-pointer"
        >
          {theme === "dark" ? (
            <SunIcon className="w-5 h-5 shrink-0 text-[#00FFD1] group-hover:scale-110 transition-transform" />
          ) : (
            <MoonIcon className="w-5 h-5 shrink-0 text-[#1E90FF] group-hover:scale-110 transition-transform" />
          )}
          <AnimatePresence>
            {(isSidebarOpen || isMobile) && (
              <motion.span
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="ml-3 font-medium whitespace-nowrap text-slate-300 group-hover:text-white transition-colors"
              >
                {theme === "dark" ? "Light Mode" : "Dark Mode"}
              </motion.span>
            )}
          </AnimatePresence>
        </button>

        <button
          onClick={handleLogout}
          className="flex items-center w-full px-4 py-3 text-rose-400 hover:bg-rose-500/10 rounded-2xl transition-all font-bold text-sm group cursor-pointer"
        >
          <ArrowLeftOnRectangleIcon className="w-5 h-5 shrink-0 group-hover:translate-x-1 transition-transform" />
          <AnimatePresence>
            {(isSidebarOpen || isMobile) && (
              <motion.span
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="ml-3 font-medium whitespace-nowrap"
              >
                Terminate Session
              </motion.span>
            )}
          </AnimatePresence>
        </button>
      </div>
    </>
  );

  return (
    <div className="flex flex-col lg:flex-row h-screen bg-background-default text-text-theme-primary transition-colors duration-300 overflow-hidden">
      <NetworkStatusIndicator />
      {/* Mobile Header */}
      <header className="lg:hidden bg-[#2E3A59] text-white h-16 px-6 flex items-center justify-between border-b border-white/10 z-30 shadow-md">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 rounded-xl bg-[#1E90FF] flex items-center justify-center">
            <ServerIcon className="w-5 h-5 text-white" />
          </div>
          <span className="text-lg font-black tracking-tight">SuperHub</span>
        </div>
        <button
          onClick={() => setIsMobileMenuOpen(true)}
          className="p-2 rounded-xl hover:bg-white/10 text-slate-300 transition-all active:scale-95"
        >
          <Bars3Icon className="w-6 h-6" />
        </button>
      </header>

      {/* Desktop Sidebar */}
      <motion.aside
        initial={{ width: isSidebarOpen ? 260 : 88 }}
        animate={{ width: isSidebarOpen ? 260 : 88 }}
        transition={{ duration: 0.4, cubicBezier: [0.4, 0, 0.2, 1] }}
        className="bg-[#2E3A59] text-white z-20 flex-col shadow-[4px_0_15px_rgba(0,0,0,0.1)] hidden lg:flex overflow-hidden"
      >
        {sidebarContent(false)}
      </motion.aside>

      {/* Mobile/Tablet Sidebar Drawer */}
      <AnimatePresence>
        {isMobileMenuOpen && (
          <>
            {/* Overlay Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 0.5 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsMobileMenuOpen(false)}
              className="fixed inset-0 bg-black z-40 lg:hidden"
            />
            {/* Sidebar Drawer Panel */}
            <motion.aside
              initial={{ x: "-100%" }}
              animate={{ x: 0 }}
              exit={{ x: "-100%" }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="fixed inset-y-0 left-0 w-72 bg-[#2E3A59] text-white z-50 flex flex-col shadow-2xl lg:hidden"
            >
              {sidebarContent(true)}
            </motion.aside>
          </>
        )}
      </AnimatePresence>

      {/* Main Content Pane */}
      <main className="flex-1 overflow-y-auto overflow-x-hidden min-w-0 p-4 sm:p-6 lg:p-10">
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
          <Breadcrumbs />
          <Outlet />
        </motion.div>
      </main>
    </div>
  );
};

export default SuperAdminLayout;
