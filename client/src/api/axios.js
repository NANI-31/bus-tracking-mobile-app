import axios from "axios";
import toast from "react-hot-toast";
import { getDynamicApiUrl } from "../utils/url";

const API_URL = getDynamicApiUrl();
const BASE_URL = API_URL.endsWith("/api/v1") ? API_URL : `${API_URL}/api/v1`;

const axiosInstance = axios.create({
  baseURL: BASE_URL,
});

// Request interceptor to add the auth token
axiosInstance.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem("userToken");
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  },
);

// Response interceptor to handle errors globally
axiosInstance.interceptors.response.use(
  (response) => {
    return response;
  },
  async (error) => {
    if (!error.response) {
      // Network/Server connection error
      toast.error("Network error: Please check your internet connection or server status.", {
        id: "network-error",
      });
      return Promise.reject(error);
    }

    const { status, data } = error.response;

    if (status === 401) {
      const refreshToken = localStorage.getItem("userRefreshToken");
      if (refreshToken && !error.config._retry) {
        error.config._retry = true;
        try {
          const response = await axios.post(`${BASE_URL}/auth/refresh`, { refreshToken });
          if (response.data && response.data.accessToken) {
            const newAccessToken = response.data.accessToken;
            localStorage.setItem("userToken", newAccessToken);

            // Retry the original request
            error.config.headers.Authorization = `Bearer ${newAccessToken}`;
            return axiosInstance(error.config);
          }
        } catch (refreshError) {
          // Refresh token expired or invalid -> log out
          localStorage.removeItem("userToken");
          localStorage.removeItem("userRefreshToken");
          localStorage.removeItem("userInfo");

          toast.error("Session expired. Please log in again.", {
            id: "auth-error",
          });

          if (window.location.pathname !== "/login") {
            window.location.href = "/login";
          }
          return Promise.reject(refreshError);
        }
      }

      // No refresh token or retry already failed
      localStorage.removeItem("userToken");
      localStorage.removeItem("userRefreshToken");
      localStorage.removeItem("userInfo");

      toast.error("Session expired. Please log in again.", {
        id: "auth-error",
      });

      if (window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
      return Promise.reject(error);
    }

    switch (status) {
      case 403:
        toast.error("Access denied: You do not have permission to perform this action.", {
          id: "forbidden-error",
        });
        break;

      case 404:
        toast.error("Requested service was not found on the server.", {
          id: "not-found-error",
        });
        break;

      case 429:
        toast.error(data?.message || "Too many requests. Please try again later.", {
          id: "rate-limit-error",
        });
        break;

      case 500:
      case 502:
      case 503:
      case 504:
        toast.error("Server error: Something went wrong on our end. Please try again later.", {
          id: "server-error",
        });
        break;

      default:
        // Other errors (e.g. 400 Bad Request, 404 Not Found) are passed through to the calling service
        break;
    }

    return Promise.reject(error);
  }
);

export default axiosInstance;
