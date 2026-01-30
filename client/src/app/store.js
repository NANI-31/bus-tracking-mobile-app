import { configureStore } from "@reduxjs/toolkit";
import collegeAdminReducer from "../features/college-admin/slices/collegeAdminSlice";
import superAdminReducer from "../features/super-admin/slices/superAdminSlice";
import authReducer from "../features/auth/slices/authSlice";

export const store = configureStore({
  reducer: {
    collegeAdmin: collegeAdminReducer,
    superAdmin: superAdminReducer,
    auth: authReducer,
  },
});
