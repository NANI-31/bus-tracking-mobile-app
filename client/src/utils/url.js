/**
 * Resolves the backend base URL dynamically.
 * If VITE_API_URL is configured to a local IP/localhost, it rewrites the hostname
 * to match the hostname used to access the client web page (e.g. localhost, local network IP).
 * This prevents connection drops and CORS issues when hosting the app locally.
 */
export const getDynamicApiUrl = () => {
  const envUrl = import.meta.env.VITE_API_URL;
  if (envUrl) {
    try {
      const url = new URL(envUrl);
      const isLocalEnv = 
        url.hostname === "localhost" || 
        url.hostname === "127.0.0.1" || 
        url.hostname.startsWith("192.168.") || 
        url.hostname.startsWith("10.") || 
        url.hostname.startsWith("172.");
        
      if (isLocalEnv) {
        const clientHost = window.location.hostname;
        if (clientHost === "localhost" || clientHost === "127.0.0.1") {
          url.hostname = "localhost";
        } else {
          url.hostname = clientHost;
        }
        return url.origin;
      }
      return envUrl;
    } catch (e) {
      return envUrl;
    }
  }
  return `http://${window.location.hostname}:5000`;
};
