import React, { useState, useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { LockClosedIcon, UserIcon } from "@heroicons/react/24/solid";
import { 
  SunIcon, 
  MoonIcon, 
  CommandLineIcon, 
  BuildingOfficeIcon, 
  UserCircleIcon, 
  ChevronDownIcon, 
  ChevronUpIcon 
} from "@heroicons/react/24/outline";
import { login, clearError } from "@/features/auth/slices/authSlice";
import { getDynamicApiUrl } from "@/utils/url";

const Login = () => {
  const [email, setEmail] = useState("ad@kkr.ac.in");
  const [password, setPassword] = useState("a");
  const dispatch = useDispatch();
  const navigate = useNavigate();

  // Theme State
  const [theme, setTheme] = useState(() => {
    const saved = localStorage.getItem("theme");
    if (saved) return saved;
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  });

  useEffect(() => {
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

  // Dev Tool State
  const [showDevTools, setShowDevTools] = useState(false);
  const [devData, setDevData] = useState({ users: [], colleges: [] });
  const [loadingDevData, setLoadingDevData] = useState(false);
  const [selectedRole, setSelectedRole] = useState(null);
  const [selectedCollege, setSelectedCollege] = useState(null);

  const fetchDevData = async () => {
    try {
      setLoadingDevData(true);
      const API_URL = getDynamicApiUrl();
      const BASE_URL = API_URL.endsWith("/api/v1") ? API_URL : `${API_URL}/api/v1`;

      const [usersRes, collegesRes] = await Promise.all([
        fetch(`${BASE_URL}/users/dev-list`).then((res) => res.json()),
        fetch(`${BASE_URL}/colleges`).then((res) => res.json()),
      ]);
      setDevData({
        users: Array.isArray(usersRes) ? usersRes : [],
        colleges: Array.isArray(collegesRes) ? collegesRes : [],
      });
    } catch (err) {
      console.error("Failed to fetch dev data", err);
    } finally {
      setLoadingDevData(false);
    }
  };

  const { loading, error, userInfo, userToken } = useSelector(
    (state) => state.auth,
  );

  useEffect(() => {
    // Redirect if already logged in
    if (userInfo && userToken) {
      if (userInfo.role === "superAdmin") {
        navigate("/super-admin");
      } else if (userInfo.role === "collegeAdmin") {
        navigate("/college-admin");
      } else if (userInfo.role === "busCoordinator") {
        navigate("/coordinator");
      }
    }
  }, [userInfo, userToken, navigate]);

  useEffect(() => {
    return () => {
      dispatch(clearError());
    };
  }, [dispatch]);

  const handleSubmit = (e) => {
    e.preventDefault();
    dispatch(login({ email, password }));
  };

  return (
    <div className="min-h-screen relative flex items-center justify-center bg-background-default text-text-theme-primary transition-colors duration-300 overflow-hidden px-4 sm:px-6 lg:px-8 font-sans">
      
      {/* Background Decorative Blur Blobs */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden z-0">
        <div className="absolute top-[-15%] left-[-15%] w-[50%] h-[50%] rounded-full bg-linear-to-br from-primary-main/20 to-secondary-main/25 blur-[120px] dark:from-primary-dark/10 dark:to-secondary-dark/10" />
        <div className="absolute bottom-[-15%] right-[-15%] w-[50%] h-[50%] rounded-full bg-linear-to-tl from-accent-main/15 to-primary-light/10 blur-[130px] dark:from-accent-main/5 dark:to-primary-dark/5" />
      </div>

      {/* Floating Theme Switcher */}
      <div className="absolute top-6 right-6 z-20">
        <button
          onClick={toggleTheme}
          className="p-2.5 rounded-full bg-background-paper/60 dark:bg-slate-900/60 backdrop-blur-md border border-white/20 dark:border-slate-800/80 text-text-theme-secondary hover:text-text-theme-primary shadow-lg hover:scale-110 active:scale-95 transition-all duration-200 cursor-pointer"
          aria-label="Toggle theme"
        >
          {theme === "dark" ? (
            <SunIcon className="w-5 h-5 text-amber-400" />
          ) : (
            <MoonIcon className="w-5 h-5 text-indigo-600" />
          )}
        </button>
      </div>

      {/* Login Card */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className="relative max-w-md w-full bg-background-paper/75 dark:bg-slate-900/50 backdrop-blur-xl border border-white/20 dark:border-slate-800/80 p-8 sm:p-10 rounded-[32px] shadow-2xl z-10 transition-all duration-300"
      >
        <div className="flex flex-col items-center">
          {/* Logo representation */}
          <div className="relative flex items-center justify-center w-16 h-16 rounded-2xl bg-linear-to-tr from-primary-main/15 to-secondary-main/15 border border-primary-main/30 dark:border-primary-main/20 text-primary-main shadow-inner mb-5 overflow-hidden group">
            <div className="absolute inset-0 bg-primary-main/10 scale-0 group-hover:scale-100 transition-transform duration-300 rounded-2xl" />
            <svg 
              className="w-8 h-8 text-primary-main relative z-10 transition-transform duration-500 group-hover:rotate-360" 
              fill="none" 
              viewBox="0 0 24 24" 
              stroke="currentColor" 
              strokeWidth="2"
            >
              <rect x="3" y="4" width="18" height="12" rx="2" ry="2"></rect>
              <line x1="7" y1="20" x2="7" y2="16"></line>
              <line x1="17" y1="20" x2="17" y2="16"></line>
              <circle cx="7.5" cy="11.5" r="1.5"></circle>
              <circle cx="16.5" cy="11.5" r="1.5"></circle>
              <path d="M12 4v4"></path>
              <path d="M7 16h10"></path>
            </svg>
          </div>
          
          <h2 className="text-center text-3xl font-extrabold tracking-tight bg-linear-to-r from-primary-main via-primary-dark to-secondary-dark bg-clip-text text-transparent dark:from-primary-light dark:to-secondary-light">
            Admin Portal Login
          </h2>
          <p className="mt-2 text-center text-sm text-text-theme-secondary font-medium">
            Sign in to manage your transport system
          </p>
        </div>

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          {/* Inputs Section */}
          <div className="space-y-4">
            <div className="space-y-1.5 group">
              <label htmlFor="email-address" className="block text-xs font-bold text-text-theme-secondary tracking-wide uppercase px-1 group-focus-within:text-primary-main transition-colors">
                Email Address / Phone
              </label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                  <UserIcon className="h-5 w-5 text-text-theme-secondary group-focus-within:text-primary-main transition-colors" />
                </span>
                <input
                  id="email-address"
                  name="email"
                  type="text"
                  autoComplete="username"
                  required
                  className="appearance-none block w-full pl-11 pr-4 py-3.5 bg-background-paper/30 dark:bg-slate-950/20 border border-border-theme focus:border-primary-main focus:ring-4 focus:ring-primary-main/15 rounded-xl focus:outline-none transition-all duration-300 text-sm font-medium"
                  placeholder="admin@college.edu"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </div>
            </div>

            <div className="space-y-1.5 group">
              <label htmlFor="password" className="block text-xs font-bold text-text-theme-secondary tracking-wide uppercase px-1 group-focus-within:text-primary-main transition-colors">
                Password
              </label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                  <LockClosedIcon className="h-5 w-5 text-text-theme-secondary group-focus-within:text-primary-main transition-colors" />
                </span>
                <input
                  id="password"
                  name="password"
                  type="password"
                  autoComplete="current-password"
                  required
                  className="appearance-none block w-full pl-11 pr-4 py-3.5 bg-background-paper/30 dark:bg-slate-950/20 border border-border-theme focus:border-primary-main focus:ring-4 focus:ring-primary-main/15 rounded-xl focus:outline-none transition-all duration-300 text-sm font-medium"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
              </div>
            </div>
          </div>

          {/* Error Alert */}
          {error && (
            <motion.div
              initial={{ opacity: 0, y: -8 }}
              animate={{ opacity: 1, y: 0 }}
              className="p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-500 text-xs text-center font-semibold"
            >
              {typeof error === "string"
                ? error
                : "Login failed. Please check your credentials."}
            </motion.div>
          )}

          {/* Sign In Button */}
          <div>
            <button
              type="submit"
              disabled={loading}
              className="group relative w-full flex justify-center items-center py-3.5 px-4 bg-linear-to-r from-primary-main via-primary-dark to-secondary-dark hover:from-primary-light hover:to-secondary-main text-white text-sm font-semibold rounded-xl focus:outline-none focus:ring-4 focus:ring-primary-main/30 disabled:opacity-50 shadow-lg shadow-primary-main/25 hover:shadow-xl hover:shadow-primary-main/45 active:scale-[0.98] transition-all duration-300 cursor-pointer"
            >
              {loading ? (
                <svg
                  className="animate-spin h-5 w-5 text-white mr-2"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    className="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    strokeWidth="4"
                  ></circle>
                  <path
                    className="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  ></path>
                </svg>
              ) : (
                <LockClosedIcon
                  className="h-4 w-4 mr-2 text-white/80 group-hover:scale-110 transition-transform"
                  aria-hidden="true"
                />
              )}
              {loading ? "Signing in..." : "Sign in"}
            </button>
          </div>
        </form>

        {/* Dev Tools - Collapsible Assistant */}
        <div className="mt-8 border-t border-border-theme/40 pt-5">
          <button
            type="button"
            onClick={() => {
              setShowDevTools(!showDevTools);
              if (!showDevTools && devData.colleges.length === 0) {
                fetchDevData();
              }
            }}
            className="w-full flex justify-between items-center py-2.5 px-3.5 rounded-xl bg-background-default/50 hover:bg-background-default border border-border-theme/30 text-text-theme-secondary hover:text-text-theme-primary transition-all duration-200 text-xs font-bold uppercase tracking-wider"
          >
            <span className="flex items-center gap-2">
              <CommandLineIcon className="w-4 h-4" />
              Dev Assistant
            </span>
            {showDevTools ? (
              <ChevronUpIcon className="w-4.5 h-4.5" />
            ) : (
              <ChevronDownIcon className="w-4.5 h-4.5" />
            )}
          </button>

          {showDevTools && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: "auto" }}
              className="mt-4 space-y-4 bg-background-default/30 border border-border-theme/30 rounded-2xl p-4 overflow-hidden"
            >
              {/* Role Selection */}
              <div className="space-y-2">
                <label className="text-[10px] uppercase tracking-wider font-bold text-text-theme-secondary block">
                  Autofill Role
                </label>
                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      setSelectedRole("superAdmin");
                      setSelectedCollege(null);
                      setEmail("super@admin.com");
                      setPassword("password123");
                    }}
                    className={`flex-1 py-2 px-3 rounded-lg border text-xs font-bold transition-all duration-200 cursor-pointer ${
                      selectedRole === "superAdmin"
                        ? "bg-emerald-500/15 border-emerald-500/30 text-emerald-600 dark:text-emerald-400 shadow-sm shadow-emerald-500/10"
                        : "bg-background-paper/40 border-border-theme text-text-theme-secondary hover:text-text-theme-primary hover:bg-background-paper"
                    }`}
                  >
                    Super Admin
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setSelectedRole("collegeAdmin");
                      if (devData.colleges.length === 0) fetchDevData();
                    }}
                    className={`flex-1 py-2 px-3 rounded-lg border text-xs font-bold transition-all duration-200 cursor-pointer ${
                      selectedRole === "collegeAdmin"
                        ? "bg-violet-500/15 border-violet-500/30 text-violet-600 dark:text-violet-400 shadow-sm shadow-violet-500/10"
                        : "bg-background-paper/40 border-border-theme text-text-theme-secondary hover:text-text-theme-primary hover:bg-background-paper"
                    }`}
                  >
                    College Admin
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setSelectedRole("coordinator");
                      setSelectedCollege(null);
                      setEmail("c@kkr.ac.in");
                      setPassword("a");
                    }}
                    className={`flex-1 py-2 px-3 rounded-lg border text-xs font-bold transition-all duration-200 cursor-pointer ${
                      selectedRole === "coordinator"
                        ? "bg-blue-500/15 border-blue-500/30 text-blue-600 dark:text-blue-400 shadow-sm shadow-blue-500/10"
                        : "bg-background-paper/40 border-border-theme text-text-theme-secondary hover:text-text-theme-primary hover:bg-background-paper"
                    }`}
                  >
                    Coordinator
                  </button>
                </div>
              </div>

              {/* College Selection */}
              {selectedRole === "collegeAdmin" && (
                <div className="space-y-2">
                  <label className="text-[10px] uppercase tracking-wider font-bold text-text-theme-secondary block">
                    Select College
                  </label>
                  {loadingDevData ? (
                    <div className="flex items-center gap-2 text-xs text-text-theme-secondary py-1">
                      <svg className="animate-spin h-3.5 w-3.5 text-text-theme-secondary" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      <span>Fetching schools...</span>
                    </div>
                  ) : (
                    <div className="grid grid-cols-2 gap-1.5 max-h-32 overflow-y-auto pr-1">
                      {devData.colleges.map((college) => (
                        <button
                          key={college._id}
                          type="button"
                          onClick={() => setSelectedCollege(college._id)}
                          className={`py-1.5 px-2 rounded-md border text-[11px] font-semibold transition-all duration-150 text-left truncate flex items-center gap-1.5 cursor-pointer ${
                            selectedCollege === college._id
                              ? "bg-primary-main/15 border-primary-main/30 text-primary-dark dark:text-primary-light"
                              : "bg-background-paper/20 border-border-theme/50 text-text-theme-secondary hover:bg-background-paper/50 hover:text-text-theme-primary"
                          }`}
                        >
                          <BuildingOfficeIcon className="w-3.5 h-3.5 shrink-0" />
                          <span className="truncate">{college.shortName || college.name}</span>
                        </button>
                      ))}
                      {devData.colleges.length === 0 && (
                        <p className="text-[11px] text-text-theme-secondary col-span-2">No colleges available.</p>
                      )}
                    </div>
                  )}
                </div>
              )}

              {/* User Selection */}
              {selectedRole === "collegeAdmin" && selectedCollege && (
                <div className="space-y-2">
                  <label className="text-[10px] uppercase tracking-wider font-bold text-text-theme-secondary block">
                    Select Test Admin Profile
                  </label>
                  <div className="grid grid-cols-2 gap-1.5 max-h-32 overflow-y-auto pr-1">
                    {devData.users
                      .filter((u) => u.collegeId === selectedCollege && u.role === "collegeAdmin")
                      .map((user) => (
                        <button
                          key={user._id}
                          type="button"
                          onClick={() => {
                            setEmail(user.email);
                            setPassword("a");
                          }}
                          className="py-1.5 px-2 rounded-md border bg-sky-500/10 border-sky-500/20 text-sky-600 dark:text-sky-400 hover:bg-sky-500/15 text-[11px] font-bold text-left truncate flex items-center gap-1.5 transition-all duration-150 cursor-pointer"
                        >
                          <UserCircleIcon className="w-3.5 h-3.5 shrink-0" />
                          <span className="truncate">{user.fullName}</span>
                        </button>
                      ))}
                    {devData.users.filter((u) => u.collegeId === selectedCollege && u.role === "collegeAdmin").length === 0 && (
                      <p className="text-[11px] text-red-400 col-span-2">No admins found.</p>
                    )}
                  </div>
                </div>
              )}

            </motion.div>
          )}
        </div>
      </motion.div>
    </div>
  );
};

export default Login;

