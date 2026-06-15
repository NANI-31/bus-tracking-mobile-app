import { createTheme } from "@mui/material/styles";

const theme = createTheme({
  palette: {
    primary: {
      main: "#1E90FF", // Electric Blue
      light: "#60A5FA",
      dark: "#1C64F2",
      contrastText: "#ffffff",
    },
    secondary: {
      main: "#A78BFA", // Soft Purple
      light: "#C4B5FD",
      dark: "#8B5CF6",
      contrastText: "#ffffff",
    },
    accent: {
      main: "#00FFD1", // Cyan Accent
    },
    success: {
      main: "#4ADE80", // Success Green
    },
    warning: {
      main: "#FACC15", // Warning Orange
    },
    error: {
      main: "#F87171", // Error Red
    },
    background: {
      default: "#F5F5F5",
      paper: "#ffffff",
    },
    text: {
      primary: "#1F1F1F",
      secondary: "#6B7280",
      disabled: "#94a3b8",
    },
    divider: "rgba(226, 232, 240, 0.8)",
  },
  typography: {
    fontFamily: '"Inter", "Outfit", "system-ui", -apple-system, sans-serif',
    h1: { fontWeight: 900, letterSpacing: "-0.025em" },
    h2: { fontWeight: 800, letterSpacing: "-0.025em" },
    h3: { fontWeight: 800, letterSpacing: "-0.015em" },
    h4: { fontWeight: 700 },
    h5: { fontWeight: 700 },
    h6: { fontWeight: 700 },
    subtitle1: { fontWeight: 600 },
    subtitle2: { fontWeight: 600 },
    body1: { lineHeight: 1.6 },
    body2: { lineHeight: 1.6 },
    button: { fontWeight: 700, textTransform: "none" },
  },
  shape: {
    borderRadius: 16,
  },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        body: {
          backgroundColor: "#F5F5F5",
          backgroundImage:
            "radial-gradient(at 0% 0%, rgba(30, 144, 255, 0.05) 0, transparent 50%), radial-gradient(at 100% 0%, rgba(0, 255, 209, 0.03) 0, transparent 50%)",
          backgroundAttachment: "fixed",
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 24,
          border: "1px solid rgba(226, 232, 240, 0.8)",
          backgroundColor: "#ffffff",
          boxShadow:
            "0 4px 6px -1px rgba(0, 0, 0, 0.02), 0 2px 4px -2px rgba(0, 0, 0, 0.02)",
          transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
          "&:hover": {
            boxShadow:
              "0 20px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.05)",
            borderColor: "rgba(30, 144, 255, 0.2)",
          },
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          padding: "10px 24px",
          boxShadow: "none",
          "&:hover": {
            boxShadow: "0 10px 15px -3px rgba(30, 144, 255, 0.15)",
            transform: "translateY(-1px)",
          },
        },
        containedPrimary: {
          background: "linear-gradient(135deg, #1E90FF 0%, #1C64F2 100%)",
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          "& .MuiOutlinedInput-root": {
            backgroundColor: "#ffffff",
            "& fieldset": {
              borderColor: "rgba(226, 232, 240, 1)",
              borderWidth: "1px",
            },
            "&:hover fieldset": {
              borderColor: "#1E90FF",
            },
            "&.Mui-focused fieldset": {
              borderColor: "#1E90FF",
              boxShadow: "0 0 0 4px rgba(30, 144, 255, 0.1)",
            },
          },
        },
      },
    },
  },
});

export default theme;
