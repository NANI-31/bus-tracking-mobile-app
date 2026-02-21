import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import * as sosApi from "@/features/common/api/sosApi";

export const getActiveSos = createAsyncThunk(
  "sos/getActiveSos",
  async (collegeId, { rejectWithValue }) => {
    try {
      return await sosApi.fetchActiveSos(collegeId);
    } catch (error) {
      return rejectWithValue(error.response.data);
    }
  },
);

export const getSosLogs = createAsyncThunk(
  "sos/getSosLogs",
  async (collegeId, { rejectWithValue }) => {
    try {
      return await sosApi.fetchSosLogs(collegeId);
    } catch (error) {
      return rejectWithValue(error.response.data);
    }
  },
);

export const resolveActiveSos = createAsyncThunk(
  "sos/resolveActiveSos",
  async ({ sosId, resolutionNotes }, { rejectWithValue }) => {
    try {
      return await sosApi.resolveSos(sosId, resolutionNotes);
    } catch (error) {
      return rejectWithValue(error.response.data);
    }
  },
);

const sosSlice = createSlice({
  name: "sos",
  initialState: {
    activeAlerts: [],
    sosLogs: [],
    loading: false,
    error: null,
  },
  reducers: {
    addSosAlert: (state, action) => {
      // Check if alert already exists to avoid duplicates from multiple channels
      if (!state.activeAlerts.find((a) => a.sos_id === action.payload.sos_id)) {
        state.activeAlerts.unshift(action.payload);
      }
    },
    removeSosAlert: (state, action) => {
      state.activeAlerts = state.activeAlerts.filter(
        (a) => a.sos_id !== action.payload.sos_id,
      );
    },
    clearSosError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(getActiveSos.pending, (state) => {
        state.loading = true;
      })
      .addCase(getActiveSos.fulfilled, (state, action) => {
        state.loading = false;
        state.activeAlerts = action.payload;
      })
      .addCase(getActiveSos.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload?.message || "Failed to fetch active SOS";
      })
      .addCase(getSosLogs.fulfilled, (state, action) => {
        state.sosLogs = action.payload;
      })
      .addCase(resolveActiveSos.fulfilled, (state, action) => {
        state.activeAlerts = state.activeAlerts.filter(
          (a) => a.sos_id !== action.meta.arg.sosId,
        );
      });
  },
});

export const { addSosAlert, removeSosAlert, clearSosError } = sosSlice.actions;
export default sosSlice.reducer;
