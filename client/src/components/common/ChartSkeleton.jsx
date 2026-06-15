import React from "react";

const ChartSkeleton = ({ type = "area" }) => {
  return (
    <div className="bg-background-paper rounded-2xl shadow-sm border border-border-theme p-6 h-[380px] flex flex-col justify-between transition-colors duration-300">
      {/* Header skeleton */}
      <div className="flex justify-between items-center mb-6">
        <div className="h-4 shimmer rounded-md w-32" />
        <div className="flex space-x-3">
          <div className="h-3 shimmer rounded-md w-16" />
          <div className="h-3 shimmer rounded-md w-16" />
        </div>
      </div>

      {/* Main chart visualization mockup */}
      <div className="flex-1 w-full flex items-end relative overflow-hidden bg-background-default/30 rounded-xl p-4">
        {type === "area" ? (
          // Wave shimmer using SVG
          <svg className="w-full h-full text-slate-100 dark:text-slate-800" viewBox="0 0 100 100" preserveAspectRatio="none">
            <defs>
              <linearGradient id="shimmerGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="var(--border-color)" stopOpacity={0.4} />
                <stop offset="50%" stopColor="var(--border-color)" stopOpacity={0.85} />
                <stop offset="100%" stopColor="var(--border-color)" stopOpacity={0.4} />
              </linearGradient>
            </defs>
            <path
              d="M0,80 Q25,30 50,60 T100,20 L100,100 L0,100 Z"
              fill="url(#shimmerGrad)"
              className="opacity-70"
            />
          </svg>
        ) : (
          // Bars shimmers
          <div className="w-full h-full flex items-end justify-around pt-6">
            <div className="w-8 h-[60%] shimmer rounded-t-lg" />
            <div className="w-8 h-[40%] shimmer rounded-t-lg" />
            <div className="w-8 h-[80%] shimmer rounded-t-lg" />
            <div className="w-8 h-[50%] shimmer rounded-t-lg" />
            <div className="w-8 h-[70%] shimmer rounded-t-lg" />
          </div>
        )}
      </div>

      {/* X Axis scale label skeletons */}
      <div className="flex justify-between items-center mt-4 px-2">
        <div className="h-2.5 shimmer rounded-md w-10" />
        <div className="h-2.5 shimmer rounded-md w-10" />
        <div className="h-2.5 shimmer rounded-md w-10" />
        <div className="h-2.5 shimmer rounded-md w-10" />
        <div className="h-2.5 shimmer rounded-md w-10" />
      </div>
    </div>
  );
};

export default ChartSkeleton;
