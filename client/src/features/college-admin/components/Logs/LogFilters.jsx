import React from "react";
import { Autocomplete, TextField } from "@mui/material";
import { XCircleIcon, CalendarDaysIcon } from "@heroicons/react/24/outline";

const LogFilters = ({
  filters,
  handleFilterChange,
  clearFilters,
  actionOptions,
  resourceOptions,
  dateInputRef,
}) => {
  return (
    <div className="flex flex-wrap items-center gap-3">
      {Object.values(filters).some((v) =>
        Array.isArray(v) ? v.length > 0 : v !== "",
      ) && (
        <button
          onClick={clearFilters}
          className="flex items-center space-x-1 text-red-500 hover:text-red-600 font-bold text-sm bg-red-50 px-3 py-2 rounded-xl border border-red-100 transition-all"
        >
          <XCircleIcon className="w-5 h-5" />
          <span>Reset Filters</span>
        </button>
      )}

      {/* Action Filter */}
      <Autocomplete
        multiple
        limitTags={1}
        options={actionOptions}
        getOptionLabel={(option) => option.label}
        value={actionOptions.filter((opt) =>
          filters.action.includes(opt.value),
        )}
        onChange={(e, newValue) => {
          handleFilterChange(
            "action",
            newValue.map((v) => v.value),
          );
        }}
        renderInput={(params) => (
          <TextField
            {...params}
            variant="outlined"
            placeholder="Actions"
            sx={{
              width: { xs: "100%", md: 240 },
              "& .MuiOutlinedInput-root": {
                borderRadius: "12px",
                bgcolor: "white",
                "& fieldset": { border: "2px solid #f1f5f9" },
                "&:hover fieldset": { borderColor: "#1E90FF" },
                "&.Mui-focused fieldset": { borderColor: "#1E90FF" },
              },
            }}
          />
        )}
        size="small"
      />

      {/* Resource Filter */}
      <Autocomplete
        multiple
        limitTags={1}
        options={resourceOptions}
        value={filters.resource}
        onChange={(e, newValue) => {
          handleFilterChange("resource", newValue);
        }}
        renderInput={(params) => (
          <TextField
            {...params}
            variant="outlined"
            placeholder="Resources"
            sx={{
              width: { xs: "100%", md: 200 },
              "& .MuiOutlinedInput-root": {
                borderRadius: "12px",
                bgcolor: "white",
                "& fieldset": { border: "2px solid #f1f5f9" },
                "&:hover fieldset": { borderColor: "#1E90FF" },
                "&.Mui-focused fieldset": { borderColor: "#1E90FF" },
              },
            }}
          />
        )}
        size="small"
      />

      <div className="relative">
        <button
          onClick={() => dateInputRef.current?.showPicker()}
          className={`flex items-center space-x-2 px-4 py-2 rounded-xl border-2 transition-all shadow-sm ${
            filters.date
              ? "bg-[#1E90FF] text-white border-[#1E90FF]"
              : "bg-white text-gray-700 border-gray-100 hover:border-[#1E90FF]/50"
          }`}
        >
          <CalendarDaysIcon className="w-5 h-5" />
          <span className="font-bold">
            {filters.date
              ? new Date(filters.date).toLocaleDateString()
              : "Select Date"}
          </span>
        </button>
        <input
          type="date"
          ref={dateInputRef}
          onChange={(e) => handleFilterChange("date", e.target.value)}
          className="absolute opacity-0 pointer-events-none"
          value={filters.date}
        />
      </div>

      <div className="hidden lg:block text-sm text-gray-500 font-medium bg-gray-50 px-3 py-2 rounded-xl border border-gray-100">
        {Object.values(filters).some((v) =>
          Array.isArray(v) ? v.length > 0 : v !== "",
        )
          ? "Filtered"
          : "Recent 50 entries"}
      </div>
    </div>
  );
};

export default LogFilters;
