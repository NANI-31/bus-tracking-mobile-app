
import React, { useState } from "react";
import { Outlet, Link, useLocation, useNavigate } from "react-router-dom";
import { useDispatch, useSelector } from "react-redux";
import { logout } from "@/features/auth/slices/authSlice";
import {
  HomeIcon,
  MapPinIcon,
  MapIcon,
  ArrowLeftOnRectangleIcon,
  Bars3Icon,
  XMarkIcon,
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
import NetworkStatusIndicator from "@/components/common/NetworkStatusIndicator";
import { Avatar, Tooltip } from "@mui/material";
const CoordinatorLayout = () => {
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
    { name: "Dashboard", path: "/coordinator", icon: HomeIcon },
    { name: "Live Tracking", path: "/coordinator/tracking", icon: MapPinIcon },
    { name: "Routes", path: "/coordinator/routes", icon: MapIcon },
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
      <div className="px-4 py-6">
        <p className="text-[10px] uppercase tracking-wider font-extrabold text-slate-500 mb-4 px-3">
          {(isSidebarOpen || isMobile) ? "Coordinator Portal" : "CP"}
        </p>
        <nav className="space-y-1">
          {menuItems.map((item) => {
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.name}
                to={item.path}
                onClick={() => isMobile && setIsMobileMenuOpen(false)}
                className={`flex items-center space-x-3 px-4 py-3 rounded-xl transition-all duration-200 group relative ${
                  isActive
                    ? "bg-[#1E90FF] text-white shadow-lg shadow-blue-500/20 font-bold"
                    : "text-slate-400 hover:bg-white/5 hover:text-white"
                }`}
              >
                <item.icon className="w-5 h-5 shrink-0" />
                {(isSidebarOpen || isMobile) && <span>{item.name}</span>}
              </Link>
            );
          })}
        </nav>
      </div>
      <div className="absolute bottom-6 left-0 right-0 px-4 space-y-4">
        {(isSidebarOpen || isMobile) && userInfo && (
          <div className="flex items-center space-x-3 px-4 py-3 rounded-2xl bg-white/5 border border-white/5">
            <Avatar
              sx={{ width: 36, height: 36, bgcolor: "#1E90FF" }}
              className="shadow-sm"
            >
              {userInfo.fullName?.[0]?.toUpperCase()}
            </Avatar>
            <div className="truncate flex-1">
              <p className="text-xs font-bold text-white truncate">
                {userInfo.fullName}
              </p>
              <p className="text-[10px] text-slate-400 truncate uppercase tracking-wider font-black">
                {userInfo.role}
              </p>
            </div>
          </div>
        )}
        <button
          onClick={handleLogout}
          className="w-full flex items-center space-x-3 px-4 py-3 text-rose-400 hover:bg-rose-500/10 rounded-xl transition-all active:scale-95 cursor-pointer border-none bg-transparent"
        >
          <ArrowLeftOnRectangleIcon className="w-5 h-5 shrink-0" />
          {(isSidebarOpen || isMobile) && <span className="font-bold text-sm">Logout</span>}
        </button>
      </div>
    </>
  );
  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-800 dark:text-slate-100 flex transition-colors duration-300">
      <aside
        className={`fixed inset-y-0 left-0 z-40 bg-slate-900 text-white transition-all duration-300 border-r border-white/5 hidden lg:block ${
          isSidebarOpen ? "w-64" : "w-20"
        }`}
      >
        {sidebarContent(false)}
      </aside>
      <div className="lg:hidden">
        {isMobileMenuOpen && (
          <div
            className="fixed inset-0 z-30 bg-slate-900/60 backdrop-blur-sm"
            onClick={() => setIsMobileMenuOpen(false)}
          />
        )}
        <aside
          className={`fixed inset-y-0 left-0 z-40 w-64 bg-slate-900 text-white transition-transform duration-300 transform border-r border-white/5 ${
            isMobileMenuOpen ? "translate-x-0" : "-translate-x-full"
          }`}
        >
          {sidebarContent(true)}
        </aside>
      </div>
      <main
        className={`flex-1 min-w-0 transition-all duration-300 min-h-screen p-4 sm:p-6 lg:p-8 ${
          isSidebarOpen ? "lg:ml-64" : "lg:ml-20"
        }`}
      >
        <header className="flex items-center justify-between mb-6 h-12">
          <div className="flex items-center space-x-3">
            <button
              onClick={() => setIsMobileMenuOpen(true)}
              className="lg:hidden p-2 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800/80 text-slate-600 dark:text-slate-400 shadow-xs"
            >
              <Bars3Icon className="w-5 h-5" />
            </button>
            <NetworkStatusIndicator />
          </div>
          <div className="flex items-center space-x-4">
            <button
              onClick={toggleTheme}
              className="p-2.5 rounded-xl bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800/80 text-slate-600 dark:text-slate-400 hover:text-blue-500 shadow-xs hover:scale-105 active:scale-95 transition-all cursor-pointer"
            >
              {theme === "dark" ? (
                <SunIcon className="w-4.5 h-4.5 text-amber-400" />
              ) : (
                <MoonIcon className="w-4.5 h-4.5 text-indigo-600" />
              )}
            </button>
            {activeAlerts.length > 0 && (
              <button
                onClick={() => setIsSosManagerOpen(true)}
                className="flex items-center space-x-2 px-3 py-1.5 rounded-xl bg-rose-500 hover:bg-rose-600 text-white shadow-lg shadow-rose-500/20 active:scale-95 transition-all animate-pulse cursor-pointer border-none font-bold text-xs"
              >
                <span>SOS ALERTS ({activeAlerts.length})</span>
              </button>
            )}
          </div>
        </header>
        <SosAlertBanner
          activeAlerts={activeAlerts}
          onDismiss={() => setIsBannerDismissed(true)}
          onOpenManager={() => setIsSosManagerOpen(true)}
          style={{ display: isBannerDismissed ? "none" : "block" }}
        />
        <SosManager
          isOpen={isSosManagerOpen}
          onClose={() => setIsSosManagerOpen(false)}
          activeAlerts={activeAlerts}
          sosLogs={sosLogs}
        />
        <Outlet />
      </main>
    </div>
  );
};
export default CoordinatorLayout;
