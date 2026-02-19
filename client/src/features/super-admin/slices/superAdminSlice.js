import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import {
  fetchSystemStats,
  fetchColleges,
  verifyCollege,
  fetchGlobalUsers,
  deleteGlobalUser,
  fetchAuditLogs,
  fetchTransactions,
  fetchGlobalBuses,
  toggleCollegeManualPremium,
  fetchStorageStats,
  fetchCollegeStorageHistory,
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

export const getTransactions = createAsyncThunk(
  "superAdmin/getTransactions",
  async (params) => {
    const response = await fetchTransactions(params);
    return response;
  },
);

export const getGlobalBuses = createAsyncThunk(
  "superAdmin/getGlobalBuses",
  async () => {
    const response = await fetchGlobalBuses();
    return response;
  },
);

export const toggleManualPremiumAction = createAsyncThunk(
  "superAdmin/toggleManualPremium",
  async ({ collegeId, allowManualPremium }) => {
    const response = await toggleCollegeManualPremium(
      collegeId,
      allowManualPremium,
    );
    return response;
  },
);

export const getStorageStats = createAsyncThunk(
  "superAdmin/getStorageStats",
  async () => {
    const response = await fetchStorageStats();
    return response;
  },
);

export const getCollegeStorageHistory = createAsyncThunk(
  "superAdmin/getCollegeStorageHistory",
  async ({ collegeId, startDate, endDate }, { rejectWithValue }) => {
    try {
      const response = await fetchCollegeStorageHistory(
        collegeId,
        startDate,
        endDate,
      );
      return response;
    } catch (error) {
      return rejectWithValue(error);
    }
  },
);

const initialState = {
  stats: null,
  colleges: [],
  users: [],
  auditLogs: [],
  transactions: [],
  buses: [],
  storageStats: null,
  collegeStorageHistory: [],
  loading: false,
  error: null,
};

const superAdminSlice = createSlice({
  name: "superAdmin",
  initialState,
  reducers: {
    updateGlobalBusLocation: (state, action) => {
      const { busId, location, speed, heading, timestamp } = action.payload;
      const index = state.buses.findIndex((bus) => bus._id === busId);
      if (index !== -1) {
        state.buses[index] = {
          ...state.buses[index],
          lastLocation: {
            ...location,
            timestamp: timestamp || new Date().toISOString(),
          },
          speed: speed || 0,
          heading: heading || 0,
        };
      }
    },
    addLiveLog: (state, action) => {
      // Prepend new log and keep only last 50 if no filter is active
      state.auditLogs = [action.payload, ...state.auditLogs].slice(0, 100);
    },
  },
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
      .addCase(toggleManualPremiumAction.fulfilled, (state, action) => {
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
      })

      // Transactions
      .addCase(getTransactions.pending, (state) => {
        state.loading = true;
      })
      .addCase(getTransactions.fulfilled, (state, action) => {
        state.loading = false;
        state.transactions = Array.isArray(action.payload)
          ? action.payload
          : action.payload.transactions || [];
      })
      .addCase(getTransactions.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message;
      })

      // Buses
      .addCase(getGlobalBuses.fulfilled, (state, action) => {
        state.buses = Array.isArray(action.payload) ? action.payload : [];
      })

      // Storage Stats
      .addCase(getStorageStats.pending, (state) => {
        state.loading = true;
      })
      .addCase(getStorageStats.fulfilled, (state, action) => {
        state.loading = false;
        state.storageStats = action.payload;
      })
      .addCase(getStorageStats.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message;
      })
      .addCase(getCollegeStorageHistory.pending, (state) => {
        state.loading = true;
      })
      .addCase(getCollegeStorageHistory.fulfilled, (state, action) => {
        state.loading = false;
        state.collegeStorageHistory = action.payload;
      })
      .addCase(getCollegeStorageHistory.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message;
      });
  },
});

export const { updateGlobalBusLocation, addLiveLog } = superAdminSlice.actions;

export default superAdminSlice.reducer;
