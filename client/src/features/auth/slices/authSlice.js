import { createSlice, createAsyncThunk } from "@reduxjs/toolkit";
import { loginUser } from "@/features/auth/api/authApi";

// Get token from local storage if it exists
const token = localStorage.getItem("userToken");
const user = JSON.parse(localStorage.getItem("userInfo"));

export const login = createAsyncThunk(
  "auth/login",
  async (credentials, { rejectWithValue }) => {
    try {
      const data = await loginUser(credentials);

      // Store user details and jwt token in local storage to keep user logged in between page refreshes
      localStorage.setItem("userToken", data.token);
      localStorage.setItem("userInfo", JSON.stringify(data.user)); // Assuming data.user contains role, etc.

      return data;
    } catch (error) {
      if (error.response && error.response.data.message) {
        return rejectWithValue(error.response.data.message);
      } else if (error.message) {
        return rejectWithValue(error.message);
      }
      return rejectWithValue(error);
    }
  },
);

const initialState = {
  loading: false,
  userInfo: user || null, // Contains role, name, email
  userToken: token || null,
  error: null,
  success: false,
};

const authSlice = createSlice({
  name: "auth",
  initialState,
  reducers: {
    logout: (state) => {
      localStorage.removeItem("userToken");
      localStorage.removeItem("userInfo");
      state.loading = false;
      state.userInfo = null;
      state.userToken = null;
      state.error = null;
    },
    clearError: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(login.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(login.fulfilled, (state, action) => {
        state.loading = false;
        state.userInfo = action.payload.user;
        state.userToken = action.payload.token;
        state.success = true;
      })
      .addCase(login.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
  },
});

export const { logout, clearError } = authSlice.actions;

export default authSlice.reducer;
