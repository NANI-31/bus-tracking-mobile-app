import React, { useMemo } from "react";
import { LineChart } from "@mui/x-charts/LineChart";
import { Box, Paper, Typography, useTheme } from "@mui/material";
import { motion } from "framer-motion";

const ActivityChart = ({ data, loading }) => {
  const theme = useTheme();

  const chartData = useMemo(() => {
    if (!data || data.length === 0) return [];

    // Group logs by hour for the last 24 hours or just the current set
    const groups = {};
    data.forEach((log) => {
      const date = new Date(log.createdAt);
      date.setMinutes(0, 0, 0);
      const key = date.getTime();
      groups[key] = (groups[key] || 0) + 1;
    });

    // Sort keys and format for chart
    return Object.keys(groups)
      .sort()
      .map((key) => ({
        time: new Date(parseInt(key)),
        count: groups[key],
      }));
  }, [data]);

  if (loading && (!data || data.length === 0)) {
    return (
      <Paper
        elevation={0}
        sx={{
          p: 3,
          border: "1px solid #e2e8f0",
          borderRadius: "16px",
          height: 200,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Typography
          color="textSecondary"
          variant="body2"
          sx={{ fontWeight: 600 }}
        >
          Analyzing activity trends...
        </Typography>
      </Paper>
    );
  }

  if (!data || data.length === 0) return null;

  return (
    <Box
      component={motion.div}
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      sx={{ mb: 4 }}
    >
      <Paper
        elevation={0}
        sx={{
          p: { xs: 2, md: 3 },
          border: "1px solid #e2e8f0",
          borderRadius: "16px",
          bgcolor: "rgba(255, 255, 255, 0.8)",
          backdropFilter: "blur(12px)",
        }}
      >
        <Typography
          variant="subtitle2"
          sx={{
            mb: 2,
            fontWeight: 800,
            color: "#64748b",
            textTransform: "uppercase",
            letterSpacing: "0.05em",
          }}
        >
          Activity Density (Recent Logs)
        </Typography>
        <Box sx={{ width: "100%", height: 200 }}>
          <LineChart
            dataset={chartData}
            xAxis={[
              {
                dataKey: "time",
                scaleType: "time",
                valueFormatter: (value) =>
                  value.toLocaleTimeString([], {
                    hour: "2-digit",
                    minute: "2-digit",
                  }),
              },
            ]}
            series={[
              {
                dataKey: "count",
                area: true,
                color: theme.palette.primary.main,
                showMark: false,
                curve: "linear",
              },
            ]}
            height={200}
            margin={{ top: 10, bottom: 30, left: 30, right: 10 }}
            slotProps={{
              legend: { hidden: true },
            }}
            sx={{
              ".MuiLineElement-root": {
                strokeWidth: 3,
              },
              ".MuiAreaElement-root": {
                fill: `linear-gradient(to bottom, ${theme.palette.primary.light}, transparent)`,
                opacity: 0.1,
              },
            }}
          />
        </Box>
      </Paper>
    </Box>
  );
};

export default ActivityChart;
