import React from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
  Cell,
} from "recharts";
import GlassmorphicTooltip from "@/components/common/GlassmorphicTooltip";

const SubscriptionAnalytics = ({ data }) => {
  // Transform data for the chart if needed
  // Data format from backend aggregation:
  // [ { _id: { plan: 'monthly', month: 2, year: 2026 }, count: 5, totalRevenue: 150 }, ... ]

  const chartData = data.map((item) => ({
    name: `${item._id.month}/${item._id.year} (${item._id.plan})`,
    count: item.count,
    revenue: item.totalRevenue,
    plan: item._id.plan,
  }));

  const COLORS = {
    monthly: "#1E90FF",
    semester: "#00FFD1",
  };

  return (
    <div className="bg-background-paper p-6 rounded-xl shadow-sm border border-border-theme text-text-theme-primary transition-all duration-300">
      <h3 className="text-scale-h3 text-text-theme-primary mb-6">
        Subscription Trends
      </h3>
      <div className="h-80 w-full">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={chartData}>
            <CartesianGrid
              strokeDasharray="3 3"
              vertical={false}
              stroke="var(--border-color)"
            />
            <XAxis
              dataKey="name"
              axisLine={false}
              tickLine={false}
              tick={{ fill: "var(--text-secondary)", fontSize: 12 }}
            />
            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{ fill: "var(--text-secondary)", fontSize: 12 }}
            />
            <Tooltip content={<GlassmorphicTooltip />} />
            <Legend verticalAlign="top" height={36} />
            <Bar
              dataKey="count"
              name="Subscription Count"
              radius={[4, 4, 0, 0]}
            >
              {chartData.map((entry, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={COLORS[entry.plan.toLowerCase()] || "#64748B"}
                />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

export default SubscriptionAnalytics;
