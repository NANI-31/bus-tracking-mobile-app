import axios from "@/api/axios";

// System Stats
export const fetchSystemStats = async () => {
  try {
    // Mapped to /api/admin/super/stats
    const response = await axios.get("/admin/super/stats");
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const fetchStorageStats = async () => {
  try {
    const response = await axios.get("/admin/super/storage-stats");
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const fetchCollegeStorageHistory = async (
  collegeId,
  startDate,
  endDate,
) => {
  try {
    const params = {};
    if (startDate) params.startDate = startDate;
    if (endDate) params.endDate = endDate;

    const response = await axios.get(
      `/admin/super/colleges/${collegeId}/storage-history`,
      { params },
    );
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

// College Management
export const fetchColleges = async (params) => {
  try {
    // This remains /api/colleges as it is a public/shared resource
    const response = await axios.get("/colleges", { params });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const verifyCollege = async (collegeId) => {
  try {
    // Mapped to /api/admin/super/colleges/:id/verify
    const response = await axios.put(
      `/admin/super/colleges/${collegeId}/verify`,
    );
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const updateCollegeStatus = async (collegeId, status) => {
  // Currently only suspend is implemented backend side in super admin routes
  try {
    if (status === "suspended") {
      // Mapped to /api/admin/super/colleges/:id/suspend
      const response = await axios.put(
        `/admin/super/colleges/${collegeId}/suspend`,
      );
      return response.data;
    }
    // Fallback or other status updates if implemented
    const response = await axios.put(`/colleges/${collegeId}`, {
      status,
    });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const toggleCollegeManualPremium = async (
  collegeId,
  allowManualPremium,
) => {
  try {
    const response = await axios.put(
      `/colleges/${collegeId}/toggle-manual-premium`,
      { allowManualPremium },
    );
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

// Global User Management
export const fetchGlobalUsers = async (params) => {
  try {
    const response = await axios.get("/users", { params });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const deleteGlobalUser = async (userId) => {
  try {
    const response = await axios.delete(`/users/${userId}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

// Audit Logs
export const fetchAuditLogs = async (params) => {
  try {
    const response = await axios.get("/admin/audit-logs", { params });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};
// Global Bus Management
export const fetchGlobalBuses = async () => {
  try {
    const response = await axios.get("/buses");
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

// Coupons
export const fetchCoupons = async () => {
  try {
    const response = await axios.get("/payments/admin/coupons");
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const createCoupon = async (couponData) => {
  try {
    const response = await axios.post("/payments/admin/coupons", couponData);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const updateCoupon = async (id, couponData) => {
  try {
    const response = await axios.put(
      `/payments/admin/coupons/${id}`,
      couponData,
    );
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const deleteCoupon = async (id) => {
  try {
    const response = await axios.delete(`/payments/admin/coupons/${id}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

// Advanced Analytics
export const fetchAdvancedAnalytics = async (params) => {
  try {
    const response = await axios.get("/payments/admin/advanced-analytics", {
      params,
    });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};
