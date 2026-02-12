import React from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";
import CollegeAdminLayout from "./layouts/CollegeAdminLayout";

import Dashboard from "./features/college-admin/pages/Dashboard";
import Users from "./features/college-admin/pages/Users";
import Fleet from "./features/college-admin/pages/Fleet";
import CollegeRoutes from "./features/college-admin/pages/Routes";
import Payments from "./features/college-admin/pages/Payments";

import SuperAdminLayout from "./layouts/SuperAdminLayout";
import SuperAdminDashboard from "./features/super-admin/pages/SuperAdminDashboard";
import Colleges from "./features/super-admin/pages/Colleges";
import GlobalUsers from "./features/super-admin/pages/GlobalUsers";
import AuditLogs from "./features/super-admin/pages/AuditLogs";
import GlobalPayments from "./features/super-admin/pages/GlobalPayments";

import Login from "./pages/Login";
import PrivateRoute from "./components/PrivateRoute";

function App() {
  return (
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
          </Route>
        </Route>

        {/* Super Admin Routes */}
        <Route element={<PrivateRoute allowedRoles={["superAdmin"]} />}>
          <Route path="/super-admin" element={<SuperAdminLayout />}>
            <Route index element={<SuperAdminDashboard />} />
            <Route path="colleges" element={<Colleges />} />
            <Route path="users" element={<GlobalUsers />} />
            <Route path="audit" element={<AuditLogs />} />
            <Route path="payments" element={<GlobalPayments />} />
          </Route>
        </Route>
      </Routes>
    </Router>
  );
}

export default App;
