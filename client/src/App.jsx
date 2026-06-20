import React, { lazy, Suspense } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";

// Loading Fallback
import LoadingFallback from "@/components/common/LoadingFallback";

// Layouts
const CollegeAdminLayout = lazy(() => import("@/layouts/CollegeAdminLayout"));
const SuperAdminLayout = lazy(() => import("@/layouts/SuperAdminLayout"));
const CoordinatorLayout = lazy(() => import("@/layouts/CoordinatorLayout"));

// Coordinator Pages
const CoordinatorDashboard = lazy(() => import("@/features/coordinator/pages/CoordinatorDashboard"));
const CoordinatorLiveTracking = lazy(() => import("@/features/coordinator/pages/CoordinatorLiveTracking"));
const CoordinatorRoutes = lazy(() => import("@/features/coordinator/pages/CoordinatorRoutes"));

// College Admin Pages
const Dashboard = lazy(() => import("@/features/college-admin/pages/Dashboard"));
const Users = lazy(() => import("@/features/college-admin/pages/Users"));
const Fleet = lazy(() => import("@/features/college-admin/pages/Fleet"));
const CollegeRoutes = lazy(() => import("@/features/college-admin/pages/Routes"));
const Payments = lazy(() => import("@/features/college-admin/pages/Payments"));
const LiveTracking = lazy(() => import("@/features/college-admin/pages/LiveTracking"));
const CollegeLogs = lazy(() => import("@/features/college-admin/pages/Logs"));
const RefundDashboard = lazy(() => import("@/features/college-admin/pages/RefundDashboard"));

// Super Admin Pages
const SuperAdminDashboard = lazy(() => import("@/features/super-admin/pages/SuperAdminDashboard"));
const Colleges = lazy(() => import("@/features/super-admin/pages/Colleges"));
const CollegeDetails = lazy(() => import("@/features/super-admin/pages/CollegeDetails"));
const GlobalUsers = lazy(() => import("@/features/super-admin/pages/GlobalUsers"));
const AuditLogs = lazy(() => import("@/features/super-admin/pages/AuditLogs"));
const GlobalPayments = lazy(() => import("@/features/super-admin/pages/GlobalPayments"));
const AdvancedAnalytics = lazy(() => import("@/features/super-admin/pages/AdvancedAnalytics"));
const GlobalTracking = lazy(() => import("@/features/super-admin/pages/GlobalTracking"));
const SystemAnalysis = lazy(() => import("@/features/super-admin/pages/SystemAnalysis"));
const SubscriptionPlans = lazy(() => import("@/features/super-admin/pages/SubscriptionPlans"));


// Auth & Other Pages
const Login = lazy(() => import("@/pages/Login"));
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
        <Toaster
          position="top-right"
          reverseOrder={false}
          toastOptions={{
            className: "glass-toast",
            success: {
              className: "glass-toast glass-toast-success",
            },
            error: {
              className: "glass-toast glass-toast-error",
            },
          }}
        />
        <Router>
          <Suspense fallback={<LoadingFallback />}>
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
                  <Route path="analytics" element={<AdvancedAnalytics />} />
                  <Route path="tracking" element={<GlobalTracking />} />
                  <Route path="analysis" element={<SystemAnalysis />} />
                  <Route path="plans" element={<SubscriptionPlans />} />
                </Route>
              </Route>

              {/* Coordinator Routes */}
              <Route element={<PrivateRoute allowedRoles={["busCoordinator"]} />}>
                <Route path="/coordinator" element={<CoordinatorLayout />}>
                  <Route index element={<CoordinatorDashboard />} />
                  <Route path="tracking" element={<CoordinatorLiveTracking />} />
                  <Route path="routes" element={<CoordinatorRoutes />} />
                </Route>
              </Route>
            </Routes>
          </Suspense>
        </Router>
      </APIProvider>
    </ThemeProvider>
  );
}

export default App;
