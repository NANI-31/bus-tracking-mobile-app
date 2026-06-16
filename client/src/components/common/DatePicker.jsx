import React, { useState, useMemo, useRef, useEffect } from "react";
import { createPortal } from "react-dom";
import { motion, AnimatePresence } from "framer-motion";
import {
  CalendarIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  XMarkIcon,
} from "@heroicons/react/24/outline";

const DatePicker = ({ value, onChange, placeholder = "Select Date", className = "" }) => {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef(null);
  const buttonRef = useRef(null);
  const [coords, setCoords] = useState({ top: 0, left: 0 });

  // Update coordinates when open
  useEffect(() => {
    const updateCoords = () => {
      if (isOpen && buttonRef.current) {
        const rect = buttonRef.current.getBoundingClientRect();
        const dropdownHeight = 310; // Estimated dropdown height

        let targetLeft = rect.left;
        // Smart placement logic: if it overflows right, align right
        if (targetLeft + 240 > window.innerWidth) {
          targetLeft = rect.right - 240;
        }
        // Constraint check: do not overflow left edge of screen
        targetLeft = Math.max(10, targetLeft);

        // Smart vertical placement logic: if it overflows bottom and there is room above, flip it
        let targetTop = rect.bottom + 8;
        const spaceBelow = window.innerHeight - rect.bottom;
        const spaceAbove = rect.top;

        if (spaceBelow < dropdownHeight && spaceAbove > dropdownHeight) {
          targetTop = rect.top - dropdownHeight - 8;
        }

        setCoords({
          top: targetTop,
          left: targetLeft,
        });
      }
    };

    if (isOpen) {
      updateCoords();
      window.addEventListener("resize", updateCoords);
      window.addEventListener("scroll", updateCoords, true);
    }

    return () => {
      window.removeEventListener("resize", updateCoords);
      window.removeEventListener("scroll", updateCoords, true);
    };
  }, [isOpen]);

  // Parse initial selected date or default to today
  const selectedDate = useMemo(() => {
    if (!value) return null;
    const d = new Date(value);
    return isNaN(d.getTime()) ? null : d;
  }, [value]);

  // View state for navigation in the calendar (defaults to selected or today)
  const [viewDate, setViewDate] = useState(() => {
    return selectedDate ? new Date(selectedDate) : new Date();
  });

  // Keep viewDate synchronized if value changes externally
  useEffect(() => {
    if (selectedDate) {
      setViewDate(new Date(selectedDate));
    }
  }, [selectedDate]);

  const viewMonth = viewDate.getMonth();
  const viewYear = viewDate.getFullYear();

  const months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  const weekdays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];

  // Navigate to previous month
  const handlePrevMonth = (e) => {
    e.stopPropagation();
    setViewDate(new Date(viewYear, viewMonth - 1, 1));
  };

  // Navigate to next month
  const handleNextMonth = (e) => {
    e.stopPropagation();
    setViewDate(new Date(viewYear, viewMonth + 1, 1));
  };

  // Select a day
  const handleSelectDay = (day, isCurrentMonth) => {
    let targetYear = viewYear;
    let targetMonth = viewMonth;
    
    if (isCurrentMonth === "prev") {
      targetMonth = viewMonth - 1;
      if (targetMonth < 0) {
        targetMonth = 11;
        targetYear -= 1;
      }
    } else if (isCurrentMonth === "next") {
      targetMonth = viewMonth + 1;
      if (targetMonth > 11) {
        targetMonth = 0;
        targetYear += 1;
      }
    }

    const d = new Date(targetYear, targetMonth, day);
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, "0");
    const dd = String(d.getDate()).padStart(2, "0");
    const dateStr = `${yyyy}-${mm}-${dd}`;
    
    onChange(dateStr);
    setIsOpen(false);
  };

  // Clear selection
  const handleClear = (e) => {
    e.stopPropagation();
    onChange("");
    setIsOpen(false);
  };

  // Calculate calendar days
  const calendarCells = useMemo(() => {
    const cells = [];
    
    // First day of current month (0 = Sunday, 6 = Saturday)
    const firstDayIndex = new Date(viewYear, viewMonth, 1).getDay();
    
    // Number of days in current month
    const totalDays = new Date(viewYear, viewMonth + 1, 0).getDate();
    
    // Number of days in previous month
    const prevMonthTotalDays = new Date(viewYear, viewMonth, 0).getDate();

    // Previous month filler days
    for (let i = firstDayIndex - 1; i >= 0; i--) {
      cells.push({
        day: prevMonthTotalDays - i,
        monthType: "prev"
      });
    }

    // Current month days
    for (let i = 1; i <= totalDays; i++) {
      cells.push({
        day: i,
        monthType: "current"
      });
    }

    // Next month filler days (fill up to standard 42 calendar grid cells)
    const remaining = 42 - cells.length;
    for (let i = 1; i <= remaining; i++) {
      cells.push({
        day: i,
        monthType: "next"
      });
    }

    return cells;
  }, [viewMonth, viewYear]);

  // Click outside to close helper
  useEffect(() => {
    const handleOutsideClick = (e) => {
      const calendarEl = document.getElementById("datepicker-portal-dropdown");
      if (
        containerRef.current &&
        !containerRef.current.contains(e.target) &&
        (!calendarEl || !calendarEl.contains(e.target))
      ) {
        setIsOpen(false);
      }
    };
    if (isOpen) {
      document.addEventListener("mousedown", handleOutsideClick);
    }
    return () => {
      document.removeEventListener("mousedown", handleOutsideClick);
    };
  }, [isOpen]);

  const formatDateLabel = () => {
    if (!selectedDate) return placeholder;
    const day = String(selectedDate.getDate()).padStart(2, "0");
    const month = String(selectedDate.getMonth() + 1).padStart(2, "0");
    const year = selectedDate.getFullYear();
    return `${day}/${month}/${year}`;
  };

  const isToday = (day, monthType) => {
    if (monthType !== "current") return false;
    const today = new Date();
    return (
      today.getDate() === day &&
      today.getMonth() === viewMonth &&
      today.getFullYear() === viewYear
    );
  };

  const isSelected = (day, monthType) => {
    if (!selectedDate || monthType !== "current") return false;
    return (
      selectedDate.getDate() === day &&
      selectedDate.getMonth() === viewMonth &&
      selectedDate.getFullYear() === viewYear
    );
  };

  return (
    <div className={`relative ${className}`} ref={containerRef}>
      {/* Date Trigger Button */}
      <button
        ref={buttonRef}
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl border text-xs font-semibold transition-all cursor-pointer ${
          value
            ? "border-primary-main bg-primary-main/5 text-primary-main"
            : "border-border-theme bg-background-paper text-text-theme-secondary hover:border-primary-main/50"
        }`}
      >
        <span className="font-bold flex items-center gap-1.5 truncate">
          <CalendarIcon className="w-4 h-4 text-primary-main" />
          {formatDateLabel()}
        </span>
        {value && (
          <XMarkIcon
            onClick={handleClear}
            className="w-3.5 h-3.5 text-text-theme-secondary hover:text-rose-main transition-colors ml-1"
          />
        )}
      </button>

      {/* Calendar Dropdown */}
      {createPortal(
        <AnimatePresence>
          {isOpen && (
            <motion.div
              id="datepicker-portal-dropdown"
              initial={{ opacity: 0, y: 10, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: 10, scale: 0.95 }}
              transition={{ duration: 0.15, ease: "easeOut" }}
              style={{
                position: "fixed",
                top: `${coords.top}px`,
                left: `${coords.left}px`,
                width: "240px",
                zIndex: 9999,
              }}
              className="bg-slate-100/98! dark:bg-slate-950/98! backdrop-blur-md border border-primary-main/30 rounded-2xl shadow-2xl p-3 select-none text-text-theme-primary"
            >
              {/* Header controls */}
              <div className="flex justify-between items-center mb-3">
                <button
                  type="button"
                  onClick={handlePrevMonth}
                  className="p-1.5 hover:bg-slate-200/60 dark:hover:bg-slate-800/60 rounded-lg text-text-theme-secondary hover:text-text-theme-primary transition-colors cursor-pointer border-none bg-transparent"
                >
                  <ChevronLeftIcon className="w-4 h-4" />
                </button>
                <span className="text-xs font-black text-text-theme-primary tracking-tight">
                  {months[viewMonth]} {viewYear}
                </span>
                <button
                  type="button"
                  onClick={handleNextMonth}
                  className="p-1.5 hover:bg-slate-200/60 dark:hover:bg-slate-800/60 rounded-lg text-text-theme-secondary hover:text-text-theme-primary transition-colors cursor-pointer border-none bg-transparent"
                >
                  <ChevronRightIcon className="w-4 h-4" />
                </button>
              </div>

              {/* Weekdays */}
              <div className="grid grid-cols-7 text-center text-[10px] font-black text-text-theme-secondary mb-2 uppercase tracking-wider">
                {weekdays.map((w) => (
                  <div key={w} className="py-1">
                    {w}
                  </div>
                ))}
              </div>

              {/* Calendar Grid */}
              <div className="grid grid-cols-7 gap-1 text-center">
                {calendarCells.map((cell, idx) => {
                  const current = cell.monthType === "current";
                  const selected = isSelected(cell.day, cell.monthType);
                  const today = isToday(cell.day, cell.monthType);

                  return (
                    <div
                      key={idx}
                      onClick={() => handleSelectDay(cell.day, cell.monthType)}
                      className={`text-[11px] font-bold py-1.5 rounded-lg transition-all cursor-pointer flex items-center justify-center relative h-[26px] w-[26px] mx-auto ${
                        !current
                          ? "text-slate-400 dark:text-slate-600 opacity-40 hover:bg-slate-200/50 dark:hover:bg-slate-800/50"
                          : selected
                            ? "bg-primary-main text-white font-black shadow-md shadow-primary-main/20"
                            : today
                              ? "bg-primary-main/10 text-primary-main border border-primary-main/30 font-black"
                              : "text-text-theme-primary hover:bg-slate-200/60 dark:hover:bg-slate-800/60 hover:text-primary-main"
                      }`}
                    >
                      {cell.day}
                    </div>
                  );
                })}
              </div>
            </motion.div>
          )}
        </AnimatePresence>,
        document.body
      )}
    </div>
  );
};

export default DatePicker;
