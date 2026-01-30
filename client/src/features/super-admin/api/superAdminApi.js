import axios from "axios";

const API_URL = "http://localhost:5000/api/v1"; // Update with your backend URL

// System Stats
export const fetchSystemStats = async () => {
  try {
    // Mapped to /api/admin/super/stats
    const response = await axios.get(`${API_URL}/admin/super/stats`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

// College Management
export const fetchColleges = async (params) => {
  try {
    // This remains /api/colleges as it is a public/shared resource
    const response = await axios.get(`${API_URL}/colleges`, { params });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const verifyCollege = async (collegeId) => {
  try {
    // Mapped to /api/admin/super/colleges/:id/verify
    const response = await axios.put(
      `${API_URL}/admin/super/colleges/${collegeId}/verify`,
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
        `${API_URL}/admin/super/colleges/${collegeId}/suspend`,
      );
      return response.data;
    }
    // Fallback or other status updates if implemented
    const response = await axios.put(`${API_URL}/colleges/${collegeId}`, {
      status,
    });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

// Global User Management
export const fetchGlobalUsers = async (params) => {
  try {
    const response = await axios.get(`${API_URL}/users`, { params });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const deleteGlobalUser = async (userId) => {
  try {
    const response = await axios.delete(`${API_URL}/users/${userId}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

// Audit Logs
export const fetchAuditLogs = async (params) => {
  try {
    const response = await axios.get(`${API_URL}/admin/audit-logs`, { params });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};
