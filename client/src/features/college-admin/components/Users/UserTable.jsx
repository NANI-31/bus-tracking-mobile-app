import React, { useState, useMemo, useRef, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import EmptyState from "@/components/common/EmptyState";
import { stringToColor, getInitials } from "@/utils/helpers";

const SkeletonRow = ({ rowHeight }) => {
  return (
    <div
      style={{ height: `${rowHeight}px` }}
      className="flex items-center border-b border-border-theme px-4"
    >
      <div className="w-[5%] shrink-0">
        <div className="w-3.5 h-3.5 bg-border-theme rounded-sm shimmer" />
      </div>
      <div className="w-[30%] shrink-0 flex items-center pr-4">
        <div className="w-10 h-10 rounded-full bg-border-theme shrink-0 shimmer" />
        <div className="ml-4 space-y-2 flex-1">
          <div className="h-3 w-[60%] bg-border-theme rounded-md shimmer" />
          <div className="h-2 w-[80%] bg-border-theme rounded-md shimmer" />
        </div>
      </div>
      <div className="w-[15%] shrink-0">
        <div className="h-5 w-16 bg-border-theme rounded-lg shimmer" />
      </div>
      <div className="w-[15%] shrink-0">
        <div className="h-5 w-20 bg-border-theme rounded-lg shimmer" />
      </div>
      <div className="w-[20%] shrink-0 space-y-1.5">
        <div className="h-4 w-20 bg-border-theme rounded-lg shimmer" />
        <div className="h-2.5 w-24 bg-border-theme rounded-md shimmer" />
      </div>
      <div className="w-[15%] shrink-0 flex justify-end">
        <div className="h-7 w-16 bg-border-theme rounded-xl shimmer" />
      </div>
    </div>
  );
};

const UserTable = ({
  users,
  onOpenActions,
  density = "default",
  selectedIds = [],
  onSelectChange,
  loading = false,
  onInlineEdit,
  onLoadMore,
  hasMore = true,
  page = 1,
}) => {
  const scrollRef = useRef(null);
  const [scrollTop, setScrollTop] = useState(0);
  const [visibleCount, setVisibleCount] = useState(30);
  const [inlineEdit, setInlineEdit] = useState({ userId: null, field: null });

  const rowHeight = {
    compact: 58,
    default: 72,
    relaxed: 84,
  }[density] || 72;

  const visibleHeight = 480;

  const [sortConfig, setSortConfig] = useState({ key: "fullName", direction: "asc" });

  // Reset scroll when page resets to 1 (e.g. fresh search or filter applied)
  useEffect(() => {
    if (page === 1 && scrollRef.current) {
      scrollRef.current.scrollTop = 0;
      setScrollTop(0);
    }
  }, [page]);

  // Sync visibleCount with incoming users array length changes
  useEffect(() => {
    setVisibleCount(Math.max(30, users.length));
  }, [users.length]);

  const handleScroll = (e) => {
    const { scrollTop: currentScrollTop, scrollHeight, clientHeight } = e.currentTarget;
    setScrollTop(currentScrollTop);

    // If scrolled past 85% of scroll height, load next batch
    if (currentScrollTop + clientHeight >= scrollHeight - 80) {
      if (visibleCount < sortedUsers.length) {
        setVisibleCount((prev) => Math.min(prev + 30, sortedUsers.length));
      }
      if (onLoadMore && hasMore && !loading) {
        onLoadMore();
      }
    }
  };

  const handleSort = (key) => {
    let direction = "asc";
    if (sortConfig.key === key && sortConfig.direction === "asc") {
      direction = "desc";
    }
    setSortConfig({ key, direction });
  };

  const sortedUsers = useMemo(() => {
    const sortableItems = [...users];
    if (sortConfig.key !== null) {
      sortableItems.sort((a, b) => {
        let aValue = a[sortConfig.key];
        let bValue = b[sortConfig.key];

        if (sortConfig.key === "approved") {
          aValue = a.approved ? 1 : 0;
          bValue = b.approved ? 1 : 0;
        } else if (sortConfig.key === "isPremium") {
          aValue = a.isPremium ? 1 : 0;
          bValue = b.isPremium ? 1 : 0;
        } else {
          aValue = (aValue || "").toString().toLowerCase();
          bValue = (bValue || "").toString().toLowerCase();
        }

        if (aValue < bValue) {
          return sortConfig.direction === "asc" ? -1 : 1;
        }
        if (aValue > bValue) {
          return sortConfig.direction === "asc" ? 1 : -1;
        }
        return 0;
      });
    }
    return sortableItems;
  }, [users, sortConfig]);

  const displayedUsers = useMemo(() => {
    return sortedUsers.slice(0, visibleCount);
  }, [sortedUsers, visibleCount]);

  const handleToggleAll = () => {
    if (selectedIds.length === displayedUsers.length && displayedUsers.length > 0) {
      onSelectChange([]);
    } else {
      onSelectChange(displayedUsers.map((u) => u._id));
    }
  };

  const handleToggleOne = (userId) => {
    if (selectedIds.includes(userId)) {
      onSelectChange(selectedIds.filter((id) => id !== userId));
    } else {
      onSelectChange([...selectedIds, userId]);
    }
  };

  const getUserInitials = (user) => {
    if (user.fullName) {
      const parts = user.fullName.trim().split(/\s+/);
      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
      return user.fullName.substring(0, 2).toUpperCase();
    }
    return getInitials(user.email);
  };

  const startIndex = Math.max(0, Math.floor(scrollTop / rowHeight) - 2);
  const endIndex = Math.min(
    displayedUsers.length,
    Math.floor((scrollTop + visibleHeight) / rowHeight) + 2
  );

  const visibleUsers = displayedUsers.slice(startIndex, endIndex);
  const totalHeight = displayedUsers.length * rowHeight;
  const offsetY = startIndex * rowHeight;

  const columns = [
    { label: "Name", key: "fullName", width: "w-[30%] shrink-0" },
    { label: "Role", key: "role", width: "w-[15%] shrink-0" },
    { label: "Status", key: "approved", width: "w-[15%] shrink-0" },
    { label: "Premium", key: "isPremium", width: "w-[20%] shrink-0" },
    { label: "Actions", key: null, width: "w-[15%] shrink-0 text-right pr-4" },
  ];

  return (
    <div className="bg-background-paper rounded-2xl border border-border-theme shadow-sm overflow-hidden flex flex-col">
      {/* Custom Table Header */}
      <div className="flex items-center bg-background-default/90 dark:bg-slate-900/90 backdrop-blur-md border-b border-border-theme h-12 shrink-0">
        <div className="w-[5%] shrink-0 pl-4 flex items-center">
          <input
            type="checkbox"
            checked={displayedUsers.length > 0 && selectedIds.length === displayedUsers.length}
            onChange={handleToggleAll}
            className="w-3.5 h-3.5 rounded-sm text-primary-main border-border-theme focus:ring-primary-main cursor-pointer"
            disabled={loading || displayedUsers.length === 0}
          />
        </div>
        {columns.map((col) => (
          <div
            key={col.label}
            onClick={() => col.key && !loading && handleSort(col.key)}
            className={`${col.width} text-scale-table-header text-text-theme-secondary select-none font-black flex items-center gap-1 ${
              col.key && !loading ? "cursor-pointer hover:text-text-theme-primary transition-colors" : ""
            }`}
          >
            <span>{col.label}</span>
            {col.key && sortConfig.key === col.key && (
              <span className="text-[10px] text-primary-main">
                {sortConfig.direction === "asc" ? "▲" : "▼"}
              </span>
            )}
          </div>
        ))}
      </div>

      {/* Table Body / Virtualized Scroll Container */}
      <div
        ref={scrollRef}
        onScroll={handleScroll}
        style={{ height: `${visibleHeight}px` }}
        className="overflow-y-auto relative custom-scrollbar"
      >
        {loading ? (
          <div className="flex flex-col">
            {[...Array(6)].map((_, i) => (
              <SkeletonRow key={i} rowHeight={rowHeight} />
            ))}
          </div>
        ) : displayedUsers.length === 0 ? (
          <div className="py-12 px-6">
            <EmptyState
              message="No users found"
              description="Try adjusting your search criteria or selecting a different role filter."
            />
          </div>
        ) : (
          <div style={{ height: `${totalHeight}px`, width: "100%", position: "relative" }}>
            <div
              style={{
                transform: `translateY(${offsetY}px)`,
                position: "absolute",
                left: 0,
                right: 0,
              }}
            >
              <div>
                {visibleUsers.map((user) => {
                  const isRowSelected = selectedIds.includes(user._id);
                  const isEditingThisRow = inlineEdit.userId === user._id;

                  return (
                    <div
                      key={user._id}
                      style={{ height: `${rowHeight}px` }}
                      className={`flex items-center border-b border-border-theme hover:bg-background-default/60 dark:hover:bg-slate-800/40 transition-colors ${
                        isRowSelected ? "bg-primary-main/5" : ""
                      } ${isEditingThisRow ? "z-30 overflow-visible" : "z-10"}`}
                    >
                      {/* Checkbox column */}
                      <div className="w-[5%] shrink-0 pl-4 flex items-center">
                        <input
                          type="checkbox"
                          checked={isRowSelected}
                          onChange={() => handleToggleOne(user._id)}
                          className="w-3.5 h-3.5 rounded-sm text-primary-main border-border-theme focus:ring-primary-main cursor-pointer"
                        />
                      </div>

                      {/* Name Column */}
                      <div className="w-[30%] shrink-0 flex items-center pr-4">
                        <div
                          style={{ backgroundColor: stringToColor(user.email || user.fullName) }}
                          className="h-10 w-10 rounded-full flex items-center justify-center text-white font-extrabold shrink-0 shadow-sm border border-white/10 text-xs tracking-wider"
                        >
                          {getUserInitials(user)}
                        </div>
                        <div className="ml-4 truncate">
                          <div className="text-scale-table-body text-text-theme-primary font-bold truncate">
                            {user.fullName}
                          </div>
                          <div className="text-xs text-text-theme-secondary font-semibold truncate">
                            {user.email}
                          </div>
                        </div>
                      </div>

                      {/* Role Badge Column */}
                      <div className="relative w-[15%] shrink-0 select-none">
                        <span
                          onDoubleClick={() => !loading && setInlineEdit({ userId: user._id, field: "role" })}
                          title="Double-click to edit role"
                          className={`px-2.5 py-1 inline-flex text-[10px] leading-4 font-black rounded-lg border uppercase tracking-wider cursor-pointer hover:scale-105 active:scale-95 transition-transform ${
                            user.role === "admin"
                              ? "bg-secondary-main/10 text-secondary-dark dark:text-secondary-light border-secondary-main/20"
                              : user.role === "driver"
                                ? "bg-warning-main/10 text-amber-600 dark:text-warning-main border-warning-main/20"
                                : (user.role === "coordinator" || user.role === "busCoordinator")
                                  ? "bg-indigo-main/10 text-indigo-main border-indigo-main/20"
                                  : "bg-primary-main/10 text-primary-main border-primary-main/20"
                          }`}
                        >
                          {user.role}
                        </span>

                        {isEditingThisRow && inlineEdit.field === "role" && (
                          <>
                            <div
                              className="fixed inset-0 z-30 bg-transparent cursor-default"
                              onClick={(e) => {
                                e.stopPropagation();
                                setInlineEdit({ userId: null, field: null });
                              }}
                            />
                            <div className="absolute top-full left-0 mt-1 bg-background-paper border border-border-theme shadow-xl rounded-xl p-1 z-40 min-w-[120px] flex flex-col gap-0.5">
                              {["student", "driver", "busCoordinator", "admin"].map((r) => (
                                <button
                                  key={r}
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    onInlineEdit(user._id, { role: r });
                                    setInlineEdit({ userId: null, field: null });
                                  }}
                                  className={`w-full text-left px-2.5 py-1.5 rounded-lg text-[10px] font-black uppercase transition-all cursor-pointer border-none bg-transparent hover:bg-background-default hover:text-primary-main ${
                                    user.role === r ? "text-primary-main bg-primary-main/5" : "text-text-theme-primary"
                                  }`}
                                >
                                  {r}
                                </button>
                              ))}
                            </div>
                          </>
                        )}
                      </div>

                      {/* Status badge Column */}
                      <div className="relative w-[15%] shrink-0 select-none">
                        <span
                          onDoubleClick={() => !loading && setInlineEdit({ userId: user._id, field: "approved" })}
                          title="Double-click to edit status"
                          className={`px-2.5 py-1 inline-flex text-[10px] leading-4 font-black rounded-lg border uppercase tracking-wider cursor-pointer hover:scale-105 active:scale-95 transition-transform ${
                            user.approved
                              ? "bg-emerald-main/10 text-emerald-main border-emerald-main/20"
                              : "bg-warning-main/10 text-warning-main border-warning-main/20"
                          }`}
                        >
                          {user.approved ? "Approved" : "Pending"}
                        </span>

                        {isEditingThisRow && inlineEdit.field === "approved" && (
                          <>
                            <div
                              className="fixed inset-0 z-30 bg-transparent cursor-default"
                              onClick={(e) => {
                                e.stopPropagation();
                                setInlineEdit({ userId: null, field: null });
                              }}
                            />
                            <div className="absolute top-full left-0 mt-1 bg-background-paper border border-border-theme shadow-xl rounded-xl p-1 z-40 min-w-[120px] flex flex-col gap-0.5">
                              {[
                                { label: "Approved", value: true },
                                { label: "Pending", value: false },
                              ].map((s) => (
                                <button
                                  key={s.label}
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    onInlineEdit(user._id, { approved: s.value });
                                    setInlineEdit({ userId: null, field: null });
                                  }}
                                  className={`w-full text-left px-2.5 py-1.5 rounded-lg text-[10px] font-black uppercase transition-all cursor-pointer border-none bg-transparent hover:bg-background-default hover:text-primary-main ${
                                    user.approved === s.value ? "text-primary-main bg-primary-main/5" : "text-text-theme-primary"
                                  }`}
                                >
                                  {s.label}
                                </button>
                              ))}
                            </div>
                          </>
                        )}
                      </div>

                      {/* Premium Column */}
                      <div className="w-[20%] shrink-0 flex flex-col justify-center">
                        {user.isPremium ? (
                          <>
                            <span className="px-2.5 py-1 inline-flex text-[10px] leading-4 font-black rounded-lg border uppercase tracking-wider bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20 w-fit">
                              ★ Premium
                            </span>
                            <span className="text-[10px] text-text-theme-secondary font-semibold mt-1">
                              Until {new Date(user.premiumUntil).toLocaleDateString()}
                            </span>
                          </>
                        ) : (
                          <span className="text-text-theme-secondary text-xs italic font-semibold">
                            Standard
                          </span>
                        )}
                      </div>

                      {/* Actions Column */}
                      <div className="w-[15%] shrink-0 text-right pr-4">
                        <button
                          onClick={() => onOpenActions(user)}
                          className="inline-flex items-center space-x-1.5 bg-[#1E90FF]/10 hover:bg-[#1E90FF] hover:text-white text-primary-main px-3 py-1.5 rounded-xl transition-all duration-200 active:scale-95 font-black text-xs cursor-pointer border border-[#1E90FF]/25 hover:border-transparent hover:shadow-md hover:shadow-primary-main/20"
                        >
                          <span>Manage</span>
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default UserTable;
