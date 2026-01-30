import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import {
  fetchSystemStats,
  fetchColleges,
  verifyCollege,
  fetchGlobalUsers,
  deleteGlobalUser,
  fetchAuditLogs,
} from "../api/superAdminApi";

// Thunks
export const getSystemStats = createAsyncThunk(
  "superAdmin/getSystemStats",
  async () => {
    const response = await fetchSystemStats();
    return response;
  },
);

export const getColleges = createAsyncThunk(
  "superAdmin/getColleges",
  async (params) => {
    const response = await fetchColleges(params);
    return response; // Expecting { data: [], total: 0 } or []
  },
);

export const verifyCollegeAction = createAsyncThunk(
  "superAdmin/verifyCollege",
  async (collegeId) => {
    const response = await verifyCollege(collegeId);
    return response; // Updated college object
  },
);

export const getGlobalUsers = createAsyncThunk(
  "superAdmin/getGlobalUsers",
  async (params) => {
    const response = await fetchGlobalUsers(params);
    return response;
  },
);

export const removeGlobalUser = createAsyncThunk(
  "superAdmin/removeGlobalUser",
  async (userId) => {
    await deleteGlobalUser(userId);
    return userId;
  },
);

export const getAuditLogs = createAsyncThunk(
  "superAdmin/getAuditLogs",
  async (params) => {
    const response = await fetchAuditLogs(params);
    return response;
  },
);

const initialState = {
  stats: null,
  colleges: [],
  users: [],
  auditLogs: [],
  loading: false,
  error: null,
};

const superAdminSlice = createSlice({
  name: "superAdmin",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      // Stats
      .addCase(getSystemStats.pending, (state) => {
        state.loading = true;
      })
      .addCase(getSystemStats.fulfilled, (state, action) => {
        state.loading = false;
        state.stats = action.payload;
      })
      .addCase(getSystemStats.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message;
      })

      // Colleges
      .addCase(getColleges.fulfilled, (state, action) => {
        // Handle different response structures if necessary
        state.colleges = Array.isArray(action.payload)
          ? action.payload
          : action.payload.data || [];
      })
      .addCase(verifyCollegeAction.fulfilled, (state, action) => {
        const index = state.colleges.findIndex(
          (c) => c._id === action.payload._id,
        );
        if (index !== -1) state.colleges[index] = action.payload;
      })

      // Users
      .addCase(getGlobalUsers.fulfilled, (state, action) => {
        state.users = Array.isArray(action.payload)
          ? action.payload
          : action.payload.data || [];
      })
      .addCase(removeGlobalUser.fulfilled, (state, action) => {
        state.users = state.users.filter((u) => u._id !== action.payload);
      })

      // Audit Logs
      .addCase(getAuditLogs.pending, (state) => {
        state.loading = true;
      })
      .addCase(getAuditLogs.fulfilled, (state, action) => {
        state.loading = false;
        state.auditLogs = Array.isArray(action.payload)
          ? action.payload
          : action.payload.logs || [];
      })
      .addCase(getAuditLogs.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message;
      });
  },
});

export default superAdminSlice.reducer;
