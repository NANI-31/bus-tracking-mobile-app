import React from "react";
import { Navigate, Outlet } from "react-router-dom";
import { useSelector } from "react-redux";

const PrivateRoute = ({ allowedRoles }) => {
  const { userInfo, userToken } = useSelector((state) => state.auth);

  // Check if user is logged in
  if (!userToken || !userInfo) {
    return <Navigate to="/login" replace />;
  }

  // Check if user has permission
  if (allowedRoles && !allowedRoles.includes(userInfo.role)) {
    // Redirect to appropriate dashboard if logged in but wrong role
    // or logout/login page
    if (userInfo.role === "collegeAdmin") {
      return <Navigate to="/college-admin" replace />;
    } else if (userInfo.role === "superAdmin") {
      return <Navigate to="/super-admin" replace />;
    } else if (userInfo.role === "busCoordinator") {
      return <Navigate to="/coordinator" replace />;
    }
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
};

export default PrivateRoute;
