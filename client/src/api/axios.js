import axios from "axios";

const API_URL = "http://127.0.0.1:5000/api/v1";

const axiosInstance = axios.create({
  baseURL: API_URL,
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

export default axiosInstance;
