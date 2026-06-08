import axios from "@/api/axios";

export const loginUser = async (credentials) => {
  try {
    console.log(credentials)
    const response = await axios.post("/auth/login", credentials);
    return response.data;
  } catch (error) {
    const responseData = error.response ? error.response.data : null;
    if (responseData) {
      if (typeof responseData === "string" && responseData.includes("<html")) {
        throw "Unable to connect to the login service. Please try again later.";
      }
      throw responseData.message || responseData;
    }
    throw error.message;
  }
};
