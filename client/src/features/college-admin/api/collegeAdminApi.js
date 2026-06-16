import axios from "@/api/axios";

// User Management
export const fetchUsers = async (params = {}) => {
  try {
    const response = await axios.get("/users", { params });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const updateUser = async (userId, data) => {
  try {
    const response = await axios.put(`/users/${userId}`, data);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const deleteUser = async (userId) => {
  try {
    const response = await axios.delete(`/users/${userId}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

// Bus Management
export const fetchBuses = async () => {
  try {
    const response = await axios.get("/buses");
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const addBus = async (busData) => {
  try {
    const response = await axios.post("/buses", busData);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const updateBus = async (busId, busData) => {
  try {
    const response = await axios.put(`/buses/${busId}`, busData);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const deleteBus = async (busId) => {
  try {
    const response = await axios.delete(`/buses/${busId}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

// Route Management
export const fetchRoutes = async () => {
  try {
    const response = await axios.get("/routes");
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const addRoute = async (routeData) => {
  try {
    const response = await axios.post("/routes", routeData);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const updateRoute = async (routeId, routeData) => {
  try {
    const response = await axios.put(`/routes/${routeId}`, routeData);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const deleteRoute = async (routeId) => {
  try {
    const response = await axios.delete(`/routes/${routeId}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};
// Payments & Transactions
export const fetchTransactions = async (params) => {
  try {
    const response = await axios.get("/payments/transactions", {
      params,
    });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const activateManualPremium = async (userId, planType) => {
  try {
    const response = await axios.post("/users/manual-premium", {
      userId,
      planType,
    });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const bulkActivatePremium = async (formData) => {
  try {
    const response = await axios.post("/users/bulk-premium", formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
    });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const fetchCollegeStats = async () => {
  try {
    const response = await axios.get("/admin/college/stats");
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const fetchCollege = async (collegeId) => {
  try {
    const response = await axios.get(`/colleges/${collegeId}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const fetchStorageHistory = async (params = {}) => {
  try {
    const response = await axios.get("/admin/college/storage-history", {
      params,
    });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const fetchAuditLogs = async (filters = {}) => {
  try {
    const response = await axios.get("/admin/audit-logs", {
      params: filters,
    });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

// Admin Refund Management & Analytics
export const fetchRefundRequests = async () => {
  try {
    const response = await axios.get("/payments/admin/refund-requests");
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const resolveRefundRequest = async (
  transactionId,
  status,
  adminComment,
) => {
  try {
    const response = await axios.post("/payments/admin/resolve-refund", {
      transactionId,
      status,
      adminComment,
    });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const fetchSubscriptionAnalytics = async () => {
  try {
    const response = await axios.get("/payments/admin/analytics");
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};
