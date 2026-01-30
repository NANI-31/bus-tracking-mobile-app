import axios from "axios";

const API_URL = "http://localhost:5000/api/v1/auth"; // Adjust based on your server config

export const loginUser = async (credentials) => {
  try {
    const response = await axios.post(`${API_URL}/login`, credentials);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : error.message;
  }
};
