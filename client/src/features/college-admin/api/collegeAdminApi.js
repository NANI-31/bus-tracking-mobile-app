import axios from "axios";

const API_URL = "http://localhost:5000/api/v1"; // Update with your backend URL

// User Management
export const fetchUsers = async () => {
  try {
    const response = await axios.get(`${API_URL}/users`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const updateUser = async (userId, data) => {
  try {
    const response = await axios.put(`${API_URL}/users/${userId}`, data);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const deleteUser = async (userId) => {
  try {
    const response = await axios.delete(`${API_URL}/users/${userId}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

// Bus Management
export const fetchBuses = async () => {
  try {
    const response = await axios.get(`${API_URL}/buses`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const addBus = async (busData) => {
  try {
    const response = await axios.post(`${API_URL}/buses`, busData);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const updateBus = async (busId, busData) => {
  try {
    const response = await axios.put(`${API_URL}/buses/${busId}`, busData);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const deleteBus = async (busId) => {
  try {
    const response = await axios.delete(`${API_URL}/buses/${busId}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

// Route Management
export const fetchRoutes = async () => {
  try {
    const response = await axios.get(`${API_URL}/routes`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const addRoute = async (routeData) => {
  try {
    const response = await axios.post(`${API_URL}/routes`, routeData);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const updateRoute = async (routeId, routeData) => {
  try {
    const response = await axios.put(`${API_URL}/routes/${routeId}`, routeData);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};

export const deleteRoute = async (routeId) => {
  try {
    const response = await axios.delete(`${API_URL}/routes/${routeId}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};
