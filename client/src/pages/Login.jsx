import React, { useState, useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { LockClosedIcon, UserIcon } from "@heroicons/react/24/solid";
import { login, clearError } from "../features/auth/slices/authSlice";

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const dispatch = useDispatch();
  const navigate = useNavigate();

  // Dev Tool State
  const [showDevTools, setShowDevTools] = useState(false);
  const [devData, setDevData] = useState({ users: [], colleges: [] });
  const [loadingDevData, setLoadingDevData] = useState(false);
  const [selectedRole, setSelectedRole] = useState(null);
  const [selectedCollege, setSelectedCollege] = useState(null);

  const fetchDevData = async () => {
    try {
      setLoadingDevData(true);
      const [usersRes, collegesRes] = await Promise.all([
        fetch("http://localhost:5000/api/users").then((res) => res.json()),
        fetch("http://localhost:5000/api/colleges").then((res) => res.json()),
      ]);
      setDevData({ users: usersRes, colleges: collegesRes });
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
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="max-w-md w-full space-y-8 bg-white p-10 rounded-xl shadow-lg"
      >
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Admin Portal Login
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Sign in to manage your transport system
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="rounded-md shadow-sm -space-y-px">
            <div className="relative">
              <UserIcon className="h-5 w-5 absolute top-3 left-3 text-gray-400" />
              <input
                id="email-address"
                name="email"
                type="text"
                autoComplete="username"
                required
                className="appearance-none rounded-none relative block w-full px-10 py-3 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Email or Phone Number"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
            <div className="relative">
              <LockClosedIcon className="h-5 w-5 absolute top-3 left-3 text-gray-400" />
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                className="appearance-none rounded-none relative block w-full px-10 py-3 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>

          {error && (
            <div className="text-red-500 text-sm text-center">
              {typeof error === "string"
                ? error
                : "Login failed. Please check your credentials."}
            </div>
          )}

          <div>
            <button
              type="submit"
              disabled={loading}
              className="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
            >
              {loading ? (
                <svg
                  className="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
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
                <span className="absolute left-0 inset-y-0 flex items-center pl-3">
                  <LockClosedIcon
                    className="h-5 w-5 text-indigo-500 group-hover:text-indigo-400"
                    aria-hidden="true"
                  />
                </span>
              )}
              {loading ? "Signing in..." : "Sign in"}
            </button>
          </div>
        </form>

        {/* Dev Tools - For Testing Only */}
        <div className="mt-6 border-t pt-4">
          <div
            className="flex justify-between items-center cursor-pointer"
            onClick={() => setShowDevTools(!showDevTools)}
          >
            <p className="text-center text-xs text-gray-400 uppercase tracking-wide">
              Dev Tools (Testing)
            </p>
            <span className="text-xs text-gray-400">
              {showDevTools ? "▼" : "▶"}
            </span>
          </div>

          {showDevTools && (
            <div className="mt-3 space-y-3">
              {/* Role Selection */}
              <div>
                <p className="text-xs text-gray-500 mb-2 font-semibold">
                  Select Role:
                </p>
                <div className="flex space-x-2">
                  <button
                    type="button"
                    onClick={() => {
                      setSelectedRole("superAdmin");
                      setSelectedCollege(null);
                      setEmail("super@admin.com");
                      setPassword("password123");
                    }}
                    className={`px-3 py-1 text-xs rounded border ${selectedRole === "superAdmin" ? "bg-indigo-100 border-indigo-500 text-indigo-700" : "bg-white border-gray-300 text-gray-700"}`}
                  >
                    Super Admin
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setSelectedRole("collegeAdmin");
                      // Fetch data if not loaded
                      if (devData.colleges.length === 0) fetchDevData();
                    }}
                    className={`px-3 py-1 text-xs rounded border ${selectedRole === "collegeAdmin" ? "bg-indigo-100 border-indigo-500 text-indigo-700" : "bg-white border-gray-300 text-gray-700"}`}
                  >
                    College Admin
                  </button>
                </div>
              </div>

              {/* College Selection (for College Admin) */}
              {selectedRole === "collegeAdmin" && (
                <div>
                  <p className="text-xs text-gray-500 mb-2 font-semibold">
                    Select College:
                  </p>
                  {loadingDevData ? (
                    <p className="text-xs text-gray-400">Loading...</p>
                  ) : (
                    <div className="flex flex-wrap gap-2">
                      {devData.colleges.map((college) => (
                        <button
                          key={college._id}
                          type="button"
                          onClick={() => setSelectedCollege(college._id)}
                          className={`px-2 py-1 text-xs rounded border ${selectedCollege === college._id ? "bg-blue-100 border-blue-500 text-blue-700" : "bg-white border-gray-300 text-gray-600"}`}
                        >
                          {college.shortName || college.name.substring(0, 10)}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* User Selection */}
              {selectedRole === "collegeAdmin" && selectedCollege && (
                <div>
                  <p className="text-xs text-gray-500 mb-2 font-semibold">
                    Select User:
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {devData.users
                      .filter(
                        (u) =>
                          u.collegeId === selectedCollege &&
                          u.role === "collegeAdmin",
                      )
                      .map((user) => (
                        <button
                          key={user._id}
                          type="button"
                          onClick={() => {
                            setEmail(user.email);
                            setPassword("a"); // Default dev password
                          }}
                          className="px-2 py-1 text-xs rounded border bg-green-50 border-green-300 text-green-700 hover:bg-green-100"
                        >
                          {user.fullName}
                        </button>
                      ))}
                    {devData.users.filter(
                      (u) =>
                        u.collegeId === selectedCollege &&
                        u.role === "collegeAdmin",
                    ).length === 0 && (
                      <p className="text-xs text-red-400">No admins found.</p>
                    )}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </motion.div>
    </div>
  );
};

export default Login;
