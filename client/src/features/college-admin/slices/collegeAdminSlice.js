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
} from "../api/collegeAdminApi";

// Async Thunks

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

const initialState = {
  users: [],
  buses: [],
  routes: [],
  loading: false,
  error: null,
};

const collegeAdminSlice = createSlice({
  name: "collegeAdmin",
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      // Users
      .addCase(getUsers.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(getUsers.fulfilled, (state, action) => {
        state.loading = false;
        state.users = action.payload;
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
        state.buses = action.payload;
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
        state.routes = action.payload;
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
      });
  },
});

export default collegeAdminSlice.reducer;
