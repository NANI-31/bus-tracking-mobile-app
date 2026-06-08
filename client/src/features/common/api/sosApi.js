// import axios from "axios";

// const API_URL = "http://localhost:5000/api/sos";

// const getAuthHeader = () => {
//   const token = localStorage.getItem("token");
//   return {
//     headers: {
//       Authorization: `Bearer ${token}`,
//     },
//   };
// };

import axios from "@/api/axios";
export const fetchActiveSos = async (collegeId) => {
  // const response = await axios.get(
  //   `${API_URL}/active/${collegeId}`,
  //   getAuthHeader(),
  // );
    const response = await axios.get(`/sos/active/${collegeId}`);
  return response.data;
};

export const fetchSosLogs = async (collegeId) => {
  // const response = await axios.get(
  //   `${API_URL}/logs/${collegeId}`,
  //   getAuthHeader(),
  // );
    const response = await axios.get(`/sos/logs/${collegeId}`);
  return response.data;
};

export const resolveSos = async (sosId, resolutionNotes) => {
  // const response = await axios.put(
  //   `${API_URL}/${sosId}/resolve`,
  //   { resolutionNotes },
  //   getAuthHeader(),
  // );
  const response = await axios.put(`/sos/${sosId}/resolve`, { resolutionNotes });
  return response.data;
};
