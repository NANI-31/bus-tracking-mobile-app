import React from "react";
import { Box, CircularProgress, Typography } from "@mui/material";

const LoadingFallback = () => {
  return (
    <Box
      sx={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        minHeight: "60vh",
        width: "100%",
        gap: 3,
        animation: "fadeIn 0.5s ease-out",
        "@keyframes fadeIn": {
          "0%": { opacity: 0 },
          "100%": { opacity: 1 },
        },
      }}
    >
      <Box sx={{ position: "relative" }}>
        <CircularProgress
          variant="determinate"
          sx={{
            color: "rgba(30, 144, 255, 0.1)",
          }}
          size={56}
          thickness={4}
          value={100}
        />
        <CircularProgress
          variant="indeterminate"
          disableShrink
          sx={{
            color: "#1E90FF",
            animationDuration: "550ms",
            position: "absolute",
            left: 0,
            backgroundImage: "linear-gradient(135deg, #1E90FF 0%, #00FFD1 100%)",
            WebkitBackgroundClip: "text",
            "& .MuiCircularProgress-circle": {
              strokeLinecap: "round",
            },
          }}
          size={56}
          thickness={4}
        />
      </Box>
      <Typography
        variant="body2"
        sx={{
          color: "text.secondary",
          fontWeight: 500,
          letterSpacing: "0.05em",
          textTransform: "uppercase",
          animation: "pulse 1.5s infinite ease-in-out",
          "@keyframes pulse": {
            "0%, 100%": { opacity: 0.6 },
            "50%": { opacity: 1 },
          },
        }}
      >
        Loading dashboard...
      </Typography>
    </Box>
  );
};

export default LoadingFallback;
