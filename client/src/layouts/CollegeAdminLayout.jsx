import React, { useState } from "react";
import { Outlet, Link, useLocation, useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import { logout } from "@/features/auth/slices/authSlice";
import {
  HomeIcon,
  UsersIcon,
  TruckIcon,
  MapIcon,
  MapPinIcon,
  ArrowLeftOnRectangleIcon,
  Bars3Icon,
  XMarkIcon,
  CreditCardIcon,
  ClipboardDocumentListIcon,
  BanknotesIcon,
  SunIcon,
  MoonIcon,
} from "@heroicons/react/24/outline";
import {
  getActiveSos,
  getSosLogs,
  addSosAlert,
  removeSosAlert,
} from "../features/common/slices/sosSlice";
import {
  initiateSocketConnection,
  joinRoom,
} from "../services/socket";
import SosAlertBanner from "@/components/common/SosAlertBanner";
import SosManager from "@/components/common/SosManager";
import Breadcrumbs from "@/components/common/Breadcrumbs";
import NetworkStatusIndicator from "@/components/common/NetworkStatusIndicator";
import { Avatar, Tooltip } from "@mui/material";

const CollegeAdminLayout = () => {
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

  const [ripple, setRipple] = useState(null);

  const toggleTheme = (e) => {
    const nextTheme = theme === "dark" ? "light" : "dark";
    const x = e.clientX || window.innerWidth / 2;
    const y = e.clientY || window.innerHeight / 2;
    setRipple({ x, y, toTheme: nextTheme });
  };
  const { userInfo, userToken } = useSelector((state) => state.auth);
  const { activeAlerts, sosLogs } = useSelector((state) => state.sos);
  const [isSosManagerOpen, setIsSosManagerOpen] = useState(false);
  const [isBannerDismissed, setIsBannerDismissed] = useState(false);

  React.useEffect(() => {
    if (userInfo && userToken) {
      const socket = initiateSocketConnection(userToken);

      if (userInfo.collegeId) {
        joinRoom("join_college", userInfo.collegeId);
        dispatch(getActiveSos(userInfo.collegeId));
        dispatch(getSosLogs(userInfo.collegeId));
      }

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
    { name: "Dashboard", path: "/college-admin", icon: HomeIcon },
    { name: "Users", path: "/college-admin/users", icon: UsersIcon },
    { name: "Fleet", path: "/college-admin/fleet", icon: TruckIcon },
    { name: "Live Map", path: "/college-admin/tracking", icon: MapPinIcon },
    { name: "Routes", path: "/college-admin/routes", icon: MapIcon },
    { name: "Payments", path: "/college-admin/payments", icon: CreditCardIcon },
    { name: "Refunds", path: "/college-admin/refunds", icon: BanknotesIcon },
    {
      name: "Logs",
      path: "/college-admin/logs",
      icon: ClipboardDocumentListIcon,
    },
  ];

  const sidebarContent = (isMobile = false) => (
    <>
      <div className="flex items-center justify-between h-20 px-6 border-b border-white/5">
        <div className="flex items-center space-x-3">
          <div className="w-9 h-9 rounded-xl bg-linear-to-tr from-[#1E90FF] to-[#00FFD1] flex items-center justify-center shadow-lg shadow-blue-500/30 transition-transform duration-300 hover:scale-105">
            <MapPinIcon className="w-5 h-5 text-white animate-pulse" />
          </div>
          {(isSidebarOpen || isMobile) && (
            <span className="text-lg font-black tracking-wider bg-linear-to-r from-white via-slate-100 to-slate-300 bg-clip-text text-transparent">
              CollegeHub
            </span>
          )}
        </div>
        {!isMobile && (
          <button
            onClick={() => setIsSidebarOpen(!isSidebarOpen)}
            className="p-2 rounded-xl hover:bg-white/5 text-slate-400 hover:text-white transition-all active:scale-95 hidden lg:block"
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
            className="p-2 rounded-xl hover:bg-white/5 text-slate-400 hover:text-white transition-all active:scale-95 lg:hidden"
          >
            <XMarkIcon className="w-5 h-5" />
          </button>
        )}
      </div>

      <nav className="flex-1 py-4 space-y-1 overflow-y-auto overflow-x-hidden px-4">
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          return (
            <Tooltip
              key={item.name}
              title={item.name}
              placement="right"
              arrow
              disableHoverListener={isSidebarOpen || isMobile}
            >
              <Link
                to={item.path}
                onClick={() => isMobile && setIsMobileMenuOpen(false)}
                className={`flex items-center px-4 py-3 rounded-2xl transition-all duration-300 group ${
                  isActive
                    ? "bg-linear-to-r from-[#1E90FF] to-[#1C64F2] text-white shadow-lg shadow-blue-500/30 font-bold"
                    : "text-slate-400 hover:bg-white/5 hover:text-white hover:translate-x-1"
                }`}
              >
                <item.icon
                  className={`w-5 h-5 shrink-0 transition-all duration-300 group-hover:scale-110 ${
                    isActive
                      ? "text-white drop-shadow-[0_0_8px_rgba(255,255,255,0.5)]"
                      : "text-slate-400 group-hover:text-[#00FFD1]"
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
            </Tooltip>
          );
        })}
      </nav>

      <div className="p-4 border-t border-white/5 space-y-1">
        {/* Profile Details Badge */}
        <div className="mb-4">
          <AnimatePresence mode="wait">
            {(isSidebarOpen || isMobile) ? (
              <motion.div
                key="expanded-profile"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: 10 }}
                className="flex items-center space-x-3 p-3 bg-white/5 rounded-2xl border border-white/5 shadow-xs"
              >
                <Avatar
                  sx={{
                    bgcolor: "primary.main",
                    width: 36,
                    height: 36,
                    fontSize: "0.875rem",
                    fontWeight: 800,
                    boxShadow: "0 0 12px rgba(30, 144, 255, 0.4)",
                  }}
                >
                  {userInfo?.fullName?.split(" ").map(n => n[0]).join("").toUpperCase() || "AD"}
                </Avatar>
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-black text-white truncate">
                    {userInfo?.fullName || "College Admin"}
                  </p>
                  <p className="text-[10px] text-slate-400 truncate">
                    {userInfo?.email || "admin@college.edu"}
                  </p>
                </div>
              </motion.div>
            ) : (
              <motion.div
                key="collapsed-profile"
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.8 }}
                className="flex justify-center p-1"
              >
                <Tooltip title={`${userInfo?.fullName || "Admin"} (${userInfo?.email})`} placement="right" arrow>
                  <Avatar
                    sx={{
                      bgcolor: "primary.main",
                      width: 36,
                      height: 36,
                      fontSize: "0.875rem",
                      fontWeight: 800,
                      boxShadow: "0 0 12px rgba(30, 144, 255, 0.4)",
                      cursor: "pointer",
                    }}
                  >
                    {userInfo?.fullName?.split(" ").map(n => n[0]).join("").toUpperCase() || "AD"}
                  </Avatar>
                </Tooltip>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Action Controls */}
        <Tooltip
          title={theme === "dark" ? "Light Mode" : "Dark Mode"}
          placement="right"
          arrow
          disableHoverListener={isSidebarOpen || isMobile}
        >
          <button
            onClick={toggleTheme}
            className="flex items-center w-full px-4 py-3 text-slate-400 hover:bg-white/5 rounded-2xl transition-all font-bold text-sm group cursor-pointer"
          >
            {theme === "dark" ? (
              <SunIcon className="w-5 h-5 shrink-0 text-[#00FFD1] group-hover:rotate-45 transition-transform duration-355" />
            ) : (
              <MoonIcon className="w-5 h-5 shrink-0 text-[#1E90FF] group-hover:-rotate-12 transition-transform duration-355" />
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
        </Tooltip>

        <Tooltip
          title="Logout"
          placement="right"
          arrow
          disableHoverListener={isSidebarOpen || isMobile}
        >
          <button
            onClick={handleLogout}
            className="flex items-center w-full px-4 py-3 text-rose-450 hover:bg-rose-500/10 rounded-2xl transition-all font-bold text-sm group cursor-pointer"
          >
            <ArrowLeftOnRectangleIcon className="w-5 h-5 shrink-0 group-hover:translate-x-1 transition-transform duration-300" />
            <AnimatePresence>
              {(isSidebarOpen || isMobile) && (
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
        </Tooltip>
      </div>
    </>
  );

  return (
    <div className="flex flex-col lg:flex-row h-screen bg-background-default text-text-theme-primary transition-colors duration-300 overflow-hidden">
      <NetworkStatusIndicator />

      {/* Circular Theme Ripple Transition Overlay */}
      <AnimatePresence>
        {ripple && (
          <motion.div
            key="theme-ripple"
            initial={{
              position: "fixed",
              left: ripple.x,
              top: ripple.y,
              width: 0,
              height: 0,
              borderRadius: "50%",
              backgroundColor: ripple.toTheme === "dark" ? "#0f172a" : "#f5f5f5",
              x: "-50%",
              y: "-50%",
              zIndex: 99999,
            }}
            animate={{
              width: Math.max(window.innerWidth, window.innerHeight) * 2.8,
              height: Math.max(window.innerWidth, window.innerHeight) * 2.8,
            }}
            exit={{ opacity: 0, transition: { duration: 0.35 } }}
            onAnimationComplete={() => {
              setTheme(ripple.toTheme);
              setRipple(null);
            }}
            transition={{ duration: 0.65, ease: "easeInOut" }}
            className="pointer-events-none"
          />
        )}
      </AnimatePresence>

      {/* Mobile Header */}
      <header className="lg:hidden bg-linear-to-r from-[#0B0F19] to-[#111827] text-white h-16 px-6 flex items-center justify-between border-b border-white/5 z-30 shadow-md">
        <div className="flex items-center space-x-2">
          <div className="w-8 h-8 rounded-xl bg-linear-to-tr from-[#1E90FF] to-[#00FFD1] flex items-center justify-center shadow-md">
            <MapPinIcon className="w-5 h-5 text-white animate-pulse" />
          </div>
          <span className="text-lg font-black tracking-wider bg-linear-to-r from-white via-slate-100 to-slate-200 bg-clip-text text-transparent">CollegeHub</span>
        </div>
        <button
          onClick={() => setIsMobileMenuOpen(true)}
          className="p-2 rounded-xl hover:bg-white/5 text-slate-400 hover:text-white transition-all active:scale-95"
        >
          <Bars3Icon className="w-6 h-6" />
        </button>
      </header>

      {/* Desktop Sidebar */}
      <motion.aside
        initial={{ width: isSidebarOpen ? 260 : 88 }}
        animate={{ width: isSidebarOpen ? 260 : 88 }}
        transition={{ duration: 0.4, cubicBezier: [0.4, 0, 0.2, 1] }}
        className="bg-linear-to-b from-[#0B0F19] via-[#111827] to-[#090D16] text-white z-20 flex-col border-r border-white/5 shadow-2xl hidden lg:flex overflow-hidden"
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
              className="fixed inset-0 bg-black/60 backdrop-blur-xs z-40 lg:hidden"
            />
            {/* Sidebar Drawer Panel */}
            <motion.aside
              initial={{ x: "-100%" }}
              animate={{ x: 0 }}
              exit={{ x: "-100%" }}
              transition={{ type: "spring", damping: 25, stiffness: 200 }}
              className="fixed inset-y-0 left-0 w-72 bg-linear-to-b from-[#0B0F19] via-[#111827] to-[#090D16] text-white z-50 flex flex-col border-r border-white/5 shadow-2xl lg:hidden"
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

        <Breadcrumbs />

        <AnimatePresence mode="wait">
          <motion.div
            key={location.pathname}
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -15 }}
            transition={{ duration: 0.25, ease: "easeInOut" }}
          >
            <Outlet />
          </motion.div>
        </AnimatePresence>
      </main>
    </div>
  );
};

export default CollegeAdminLayout;
