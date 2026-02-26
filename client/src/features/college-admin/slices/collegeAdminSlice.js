import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import {
  fetchUsers,
  updateUser,
  deleteUser,
  fetchBuses,
  addBus,
  updateBus,
  deleteBus,
  fetchRoutes,
  addRoute,
  updateRoute,
  deleteRoute,
  fetchTransactions,
  activateManualPremium,
  bulkActivatePremium,
  fetchCollege,
  fetchAuditLogs,
  fetchRefundRequests,
  resolveRefundRequest,
  fetchSubscriptionAnalytics,
  fetchCollegeStats,
  fetchStorageHistory,
} from "../api/collegeAdminApi";

// Async Thunks

export const getStorageHistory = createAsyncThunk(
  "collegeAdmin/getStorageHistory",
  async (params = {}) => {
    const response = await fetchStorageHistory(params);
    return response;
  },
);

export const getCollegeStats = createAsyncThunk(
  "collegeAdmin/getCollegeStats",
  async () => {
    const response = await fetchCollegeStats();
    return response;
  },
);

// Users
export const getUsers = createAsyncThunk("collegeAdmin/getUsers", async () => {
  const response = await fetchUsers();
  return response;
});

export const editUser = createAsyncThunk(
  "collegeAdmin/editUser",
  async ({ userId, data }) => {
    const response = await updateUser(userId, data);
    return response;
  },
);

export const removeUser = createAsyncThunk(
  "collegeAdmin/removeUser",
  async (userId) => {
    const response = await deleteUser(userId);
    return userId; // Return userId to filter out from state
  },
);

// Buses
export const getBuses = createAsyncThunk("collegeAdmin/getBuses", async () => {
  const response = await fetchBuses();
  return response;
});

export const createBus = createAsyncThunk(
  "collegeAdmin/createBus",
  async (busData) => {
    const response = await addBus(busData);
    return response;
  },
);

export const modifyBus = createAsyncThunk(
  "collegeAdmin/modifyBus",
  async ({ busId, busData }) => {
    const response = await updateBus(busId, busData);
    return response;
  },
);

export const removeBus = createAsyncThunk(
  "collegeAdmin/removeBus",
  async (busId) => {
    const response = await deleteBus(busId);
    return busId;
  },
);

// Routes
export const getRoutes = createAsyncThunk(
  "collegeAdmin/getRoutes",
  async () => {
    const response = await fetchRoutes();
    return response;
  },
);

export const createRoute = createAsyncThunk(
  "collegeAdmin/createRoute",
  async (routeData) => {
    const response = await addRoute(routeData);
    return response;
  },
);

export const modifyRoute = createAsyncThunk(
  "collegeAdmin/modifyRoute",
  async ({ routeId, routeData }) => {
    const response = await updateRoute(routeId, routeData);
    return response;
  },
);

export const removeRoute = createAsyncThunk(
  "collegeAdmin/removeRoute",
  async (routeId) => {
    const response = await deleteRoute(routeId);
    return routeId;
  },
);

export const getTransactions = createAsyncThunk(
  "collegeAdmin/getTransactions",
  async (params) => {
    const response = await fetchTransactions(params);
    return response;
  },
);

export const activateUserPremium = createAsyncThunk(
  "collegeAdmin/activateUserPremium",
  async ({ userId, planType }) => {
    const response = await activateManualPremium(userId, planType);
    return response; // Should include updated user or status
  },
);

export const bulkUploadPremium = createAsyncThunk(
  "collegeAdmin/bulkUploadPremium",
  async (formData) => {
    const response = await bulkActivatePremium(formData);
    return response;
  },
);

export const getCollege = createAsyncThunk(
  "collegeAdmin/getCollege",
  async (collegeId) => {
    const response = await fetchCollege(collegeId);
    return response;
  },
);

export const getAuditLogs = createAsyncThunk(
  "collegeAdmin/getAuditLogs",
  async (filters = {}) => {
    const response = await fetchAuditLogs(filters);
    return response;
  },
);

export const getRefundRequests = createAsyncThunk(
  "collegeAdmin/getRefundRequests",
  async () => {
    const response = await fetchRefundRequests();
    return response;
  },
);

export const resolveRefund = createAsyncThunk(
  "collegeAdmin/resolveRefund",
  async ({ transactionId, status, adminComment }) => {
    const response = await resolveRefundRequest(
      transactionId,
      status,
      adminComment,
    );
    return { transactionId, status, response };
  },
);

export const getSubscriptionAnalytics = createAsyncThunk(
  "collegeAdmin/getSubscriptionAnalytics",
  async () => {
    const response = await fetchSubscriptionAnalytics();
    return response;
  },
);

const initialState = {
  users: [],
  buses: [],
  routes: [],
  transactions: [],
  refundRequests: [],
  analytics: [],
  auditLogs: [],
  collegeStats: null,
  storageHistory: [],
  logsTotal: 0,
  logsLimit: 50,
  logsSkip: 0,
  currentCollege: null,
  loading: false,
  error: null,
};

const collegeAdminSlice = createSlice({
  name: "collegeAdmin",
  initialState,
  reducers: {
    updateBusLocation: (state, action) => {
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
      // Prepend new log and keep only last 100
      state.auditLogs = [action.payload, ...state.auditLogs].slice(0, 100);
    },
  },
  extraReducers: (builder) => {
    builder
      // Users
      .addCase(getUsers.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getUsers.fulfilled, (state, action) => {
        state.loading = false;
        state.users = Array.isArray(action.payload) ? action.payload : [];
      })
      .addCase(getUsers.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message;
      })
      .addCase(editUser.fulfilled, (state, action) => {
        const index = state.users.findIndex(
          (user) => user._id === action.payload._id,
        );
        if (index !== -1) {
          state.users[index] = action.payload;
        }
      })
      .addCase(activateUserPremium.fulfilled, (state, action) => {
        // Find user in state and update their premium status if possible
        // Note: Backend returns { message, premiumUntil }, we might need to re-fetch or use updateUser logic
        // But for UI simplicity, we can assume the user list might need refresh or we update in-place if payload includes user
      })

      .addCase(removeUser.fulfilled, (state, action) => {
        state.users = state.users.filter((user) => user._id !== action.payload);
      })

      // Buses
      .addCase(getBuses.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getBuses.fulfilled, (state, action) => {
        state.loading = false;
        state.buses = Array.isArray(action.payload) ? action.payload : [];
      })
      .addCase(getBuses.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message;
      })
      .addCase(createBus.fulfilled, (state, action) => {
        state.buses.push(action.payload);
      })
      .addCase(modifyBus.fulfilled, (state, action) => {
        const index = state.buses.findIndex(
          (bus) => bus._id === action.payload._id,
        );
        if (index !== -1) {
          state.buses[index] = action.payload;
        }
      })
      .addCase(removeBus.fulfilled, (state, action) => {
        state.buses = state.buses.filter((bus) => bus._id !== action.payload);
      })

      // Routes
      .addCase(getRoutes.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getRoutes.fulfilled, (state, action) => {
        state.loading = false;
        state.routes = Array.isArray(action.payload) ? action.payload : [];
      })
      .addCase(getRoutes.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message;
      })
      .addCase(createRoute.fulfilled, (state, action) => {
        state.routes.push(action.payload);
      })
      .addCase(modifyRoute.fulfilled, (state, action) => {
        const index = state.routes.findIndex(
          (route) => route._id === action.payload._id,
        );
        if (index !== -1) {
          state.routes[index] = action.payload;
        }
      })
      .addCase(removeRoute.fulfilled, (state, action) => {
        state.routes = state.routes.filter(
          (route) => route._id !== action.payload,
        );
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
      .addCase(getCollege.fulfilled, (state, action) => {
        state.currentCollege = action.payload;
      })
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
      .addCase(getRefundRequests.pending, (state) => {
        state.loading = true;
      })
      .addCase(getRefundRequests.fulfilled, (state, action) => {
        state.loading = false;
        state.refundRequests = action.payload;
      })
      .addCase(getRefundRequests.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message;
      })
      .addCase(resolveRefund.fulfilled, (state, action) => {
        state.refundRequests = state.refundRequests.filter(
          (req) => req._id !== action.payload.transactionId,
        );
      })
      .addCase(getSubscriptionAnalytics.fulfilled, (state, action) => {
        state.analytics = action.payload;
      })
      .addCase(getCollegeStats.fulfilled, (state, action) => {
        state.collegeStats = action.payload;
      })
      .addCase(getStorageHistory.fulfilled, (state, action) => {
        state.storageHistory = action.payload;
      });
  },
});

export const { updateBusLocation, addLiveLog } = collegeAdminSlice.actions;

export default collegeAdminSlice.reducer;
