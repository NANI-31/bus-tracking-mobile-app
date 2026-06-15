import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import {
  fetchSystemStats,
  fetchColleges,
  fetchCollegeById,
  verifyCollege,
  fetchGlobalUsers,
  deleteGlobalUser,
  fetchAuditLogs,
  fetchTransactions,
  fetchGlobalBuses,
  toggleCollegeManualPremium,
  fetchStorageStats,
  fetchCollegeStorageHistory,
  fetchAdvancedAnalytics,
  wipeCollegeData,
  createCollege,
  unsuspendCollege,
  suspendCollege,
} from "../api/superAdminApi";

// Thunks
export const createCollegeAction = createAsyncThunk(
  "superAdmin/createCollege",
  async (collegeData, { rejectWithValue }) => {
    try {
      const response = await createCollege(collegeData);
      return response;
    } catch (error) {
      return rejectWithValue(error);
    }
  },
);

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

export const unsuspendCollegeAction = createAsyncThunk(
  "superAdmin/unsuspendCollege",
  async (collegeId, { rejectWithValue }) => {
    try {
      const response = await unsuspendCollege(collegeId);
      return response;
    } catch (error) {
      return rejectWithValue(error);
    }
  },
);

export const suspendCollegeAction = createAsyncThunk(
  "superAdmin/suspendCollege",
  async ({ collegeId, reason }, { rejectWithValue }) => {
    try {
      const response = await suspendCollege(collegeId, reason);
      return response;
    } catch (error) {
      return rejectWithValue(error);
    }
  },
);

export const getCollegeDetailsAction = createAsyncThunk(
  "superAdmin/getCollegeDetails",
  async (collegeId, { rejectWithValue }) => {
    try {
      const response = await fetchCollegeById(collegeId);
      return response;
    } catch (error) {
      return rejectWithValue(error);
    }
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

export const getAdvancedAnalytics = createAsyncThunk(
  "superAdmin/getAdvancedAnalytics",
  async (params) => {
    const response = await fetchAdvancedAnalytics(params);
    return response;
  },
);

export const wipeCollegeDataAction = createAsyncThunk(
  "superAdmin/wipeCollegeData",
  async ({ collegeId, deleteCollegeRecord }, { rejectWithValue }) => {
    try {
      const response = await wipeCollegeData(collegeId, deleteCollegeRecord);
      return { collegeId, deleteCollegeRecord, response };
    } catch (error) {
      return rejectWithValue(error);
    }
  },
);

const initialState = {
  stats: null,
  colleges: [],
  selectedCollege: null,
  users: [],
  auditLogs: [],
  logsTotal: 0,
  logsLimit: 50,
  logsSkip: 0,
  transactions: [],
  buses: [],
  storageStats: null,
  collegeStorageHistory: [],
  advancedAnalytics: null,
  analyticsLoading: false,
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
        if (state.selectedCollege?._id === action.payload._id) {
          state.selectedCollege = action.payload;
        }
      })
      .addCase(unsuspendCollegeAction.fulfilled, (state, action) => {
        const index = state.colleges.findIndex(
          (c) => c._id === action.payload._id,
        );
        if (index !== -1) state.colleges[index] = action.payload;
        if (state.selectedCollege?._id === action.payload._id) {
          state.selectedCollege = action.payload;
        }
      })
      .addCase(suspendCollegeAction.fulfilled, (state, action) => {
        const index = state.colleges.findIndex(
          (c) => c._id === action.payload._id,
        );
        if (index !== -1) state.colleges[index] = action.payload;
        if (state.selectedCollege?._id === action.payload._id) {
          state.selectedCollege = action.payload;
        }
      })
      .addCase(toggleManualPremiumAction.fulfilled, (state, action) => {
        const index = state.colleges.findIndex(
          (c) => c._id === action.payload._id,
        );
        if (index !== -1) state.colleges[index] = action.payload;
        if (state.selectedCollege?._id === action.payload._id) {
          state.selectedCollege = action.payload;
        }
      })
      .addCase(getCollegeDetailsAction.pending, (state) => {
        state.loading = true;
        state.selectedCollege = null;
      })
      .addCase(getCollegeDetailsAction.fulfilled, (state, action) => {
        state.loading = false;
        state.selectedCollege = action.payload;
      })
      .addCase(getCollegeDetailsAction.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload || action.error.message;
      })
      .addCase(wipeCollegeDataAction.fulfilled, (state, action) => {
        if (action.payload.deleteCollegeRecord) {
          state.colleges = state.colleges.filter(
            (c) => c._id !== action.payload.collegeId,
          );
        }
        // If not deleted, we might want to refresh its stats but usually wipe is destructive enough to just remove it or keep it empty.
      })
      .addCase(createCollegeAction.fulfilled, (state, action) => {
        state.colleges = [action.payload, ...state.colleges];
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
        if (Array.isArray(action.payload)) {
          state.auditLogs = action.payload;
          state.logsTotal = action.payload.length;
        } else {
          state.auditLogs = action.payload.logs || [];
          state.logsTotal = action.payload.total || 0;
          state.logsLimit = action.payload.limit || 50;
          state.logsSkip = action.payload.skip || 0;
        }
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
      })

      // Advanced Analytics
      .addCase(getAdvancedAnalytics.pending, (state) => {
        state.analyticsLoading = true;
      })
      .addCase(getAdvancedAnalytics.fulfilled, (state, action) => {
        state.analyticsLoading = false;
        state.advancedAnalytics = action.payload;
      })
      .addCase(getAdvancedAnalytics.rejected, (state, action) => {
        state.analyticsLoading = false;
        state.error = action.error.message;
      });
  },
});

export const { updateGlobalBusLocation, addLiveLog } = superAdminSlice.actions;

export default superAdminSlice.reducer;
