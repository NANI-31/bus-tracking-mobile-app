import React from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";
import CollegeAdminLayout from "@/layouts/CollegeAdminLayout";

import Dashboard from "@/features/college-admin/pages/Dashboard";
import Users from "@/features/college-admin/pages/Users";
import Fleet from "@/features/college-admin/pages/Fleet";
import CollegeRoutes from "@/features/college-admin/pages/Routes";
import Payments from "@/features/college-admin/pages/Payments";
import LiveTracking from "@/features/college-admin/pages/LiveTracking";
import CollegeLogs from "@/features/college-admin/pages/Logs";
import RefundDashboard from "@/features/college-admin/pages/RefundDashboard";

import SuperAdminLayout from "@/layouts/SuperAdminLayout";
import SuperAdminDashboard from "@/features/super-admin/pages/SuperAdminDashboard";
import Colleges from "@/features/super-admin/pages/Colleges";
import CollegeDetails from "@/features/super-admin/pages/CollegeDetails";
import GlobalUsers from "@/features/super-admin/pages/GlobalUsers";
import AuditLogs from "@/features/super-admin/pages/AuditLogs";
import GlobalPayments from "@/features/super-admin/pages/GlobalPayments";
import GlobalTracking from "@/features/super-admin/pages/GlobalTracking";
import SystemAnalysis from "@/features/super-admin/pages/SystemAnalysis";
import CouponManager from "@/features/super-admin/pages/CouponManager";
import AdvancedAnalytics from "@/features/super-admin/pages/AdvancedAnalytics";

import Login from "@/pages/Login";
import PrivateRoute from "@/components/PrivateRoute";
import { Toaster } from "react-hot-toast";
import { APIProvider } from "@vis.gl/react-google-maps";

import { ThemeProvider, CssBaseline } from "@mui/material";
import theme from "./theme";

const GOOGLE_MAPS_API_KEY =
  import.meta.env.VITE_GOOGLE_MAPS_API_KEY ||
  "AIzaSyDsWdJ_AOzgNt-_SQk2AbTaxv1r6pShx-A";

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <APIProvider apiKey={GOOGLE_MAPS_API_KEY}>
        <Toaster position="top-right" reverseOrder={false} />
        <Router>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/" element={<Navigate to="/login" replace />} />

            {/* College Admin Routes */}
            <Route element={<PrivateRoute allowedRoles={["collegeAdmin"]} />}>
              <Route path="/college-admin" element={<CollegeAdminLayout />}>
                <Route index element={<Dashboard />} />
                <Route path="users" element={<Users />} />
                <Route path="fleet" element={<Fleet />} />
                <Route path="routes" element={<CollegeRoutes />} />
                <Route path="payments" element={<Payments />} />
                <Route path="refunds" element={<RefundDashboard />} />
                <Route path="tracking" element={<LiveTracking />} />
                <Route path="logs" element={<CollegeLogs />} />
              </Route>
            </Route>

            {/* Super Admin Routes */}
            <Route element={<PrivateRoute allowedRoles={["superAdmin"]} />}>
              <Route path="/super-admin" element={<SuperAdminLayout />}>
                <Route index element={<SuperAdminDashboard />} />
                <Route path="colleges" element={<Colleges />} />
                <Route path="colleges/:id" element={<CollegeDetails />} />
                <Route path="users" element={<GlobalUsers />} />
                <Route path="audit" element={<AuditLogs />} />
                <Route path="payments" element={<GlobalPayments />} />
                <Route path="coupons" element={<CouponManager />} />
                <Route path="analytics" element={<AdvancedAnalytics />} />
                <Route path="tracking" element={<GlobalTracking />} />
                <Route path="analysis" element={<SystemAnalysis />} />
              </Route>
            </Route>
          </Routes>
        </Router>
      </APIProvider>
    </ThemeProvider>
  );
}

export default App;
