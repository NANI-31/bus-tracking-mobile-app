import React from "react";

const TableSkeleton = ({ rowsCount = 5, colsCount = 5 }) => {
  const rows = Array.from({ length: rowsCount });
  const cols = Array.from({ length: colsCount });

  return (
    <div className="bg-background-paper rounded-2xl shadow-sm border border-border-theme overflow-hidden transition-colors duration-300">
      <div className="min-w-full divide-y divide-border-theme">
        {/* Header skeleton */}
        <div className="bg-background-default/80 h-12 flex items-center px-6 border-b border-border-theme">
          {cols.map((_, i) => (
            <div
              key={`head-${i}`}
              className="flex-1 h-3.5 shimmer rounded-md mr-4 last:mr-0"
              style={{ width: `${60 + (i % 3) * 15}%` }}
            />
          ))}
        </div>
        {/* Rows skeletons */}
        <div className="divide-y divide-border-theme">
          {rows.map((_, rowIndex) => (
            <div key={`row-${rowIndex}`} className="h-16 flex items-center px-6">
              {cols.map((_, colIndex) => (
                <div
                  key={`cell-${rowIndex}-${colIndex}`}
                  className="flex-1 mr-4 last:mr-0"
                >
                  {colIndex === 0 ? (
                    // Avatar + Text combo for the first column
                    <div className="flex items-center space-x-3">
                      <div className="w-9 h-9 rounded-full shimmer shrink-0" />
                      <div className="space-y-2 flex-1">
                        <div className="h-3 shimmer rounded-md w-24" />
                        <div className="h-2 shimmer rounded-md w-16 opacity-75" />
                      </div>
                    </div>
                  ) : (
                    // Standard block shimmer
                    <div
                      className="h-3 shimmer rounded-md"
                      style={{ width: `${40 + (colIndex % 2) * 20}%` }}
                    />
                  )}
                </div>
              ))}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default TableSkeleton;
