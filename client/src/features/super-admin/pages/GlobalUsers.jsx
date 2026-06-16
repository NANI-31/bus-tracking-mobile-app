import React, { useEffect, useState, useMemo, useRef } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  UserGroupIcon,
  TrashIcon,
  MagnifyingGlassIcon,
  EnvelopeIcon,
  CheckCircleIcon,
} from "@heroicons/react/24/outline";
import {
  getGlobalUsers,
  removeGlobalUser,
  editGlobalUser,
} from "@/features/super-admin/slices/superAdminSlice";
import DensitySelector from "@/components/common/DensitySelector";
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
      <div className="w-[35%] shrink-0 flex items-center pr-4">
        <div className="w-10 h-10 rounded-full bg-border-theme shrink-0 shimmer" />
        <div className="ml-4 space-y-2 flex-1">
          <div className="h-3 w-[60%] bg-border-theme rounded-md shimmer" />
          <div className="h-2 w-[80%] bg-border-theme rounded-md shimmer" />
        </div>
      </div>
      <div className="w-[15%] shrink-0">
        <div className="h-4.5 w-16 bg-border-theme rounded-md shimmer" />
      </div>
      <div className="w-[15%] shrink-0">
        <div className="h-5 w-16 bg-border-theme rounded-lg shimmer" />
      </div>
      <div className="w-[15%] shrink-0">
        <div className="h-5 w-16 bg-border-theme rounded-lg shimmer" />
      </div>
      <div className="w-[15%] shrink-0 flex justify-end">
        <div className="h-8 w-8 bg-border-theme rounded-xl shimmer" />
      </div>
    </div>
  );
};

const GlobalUsers = () => {
  const dispatch = useDispatch();
  const { users, loading } = useSelector((state) => state.superAdmin);
  const [search, setSearch] = useState("");
  const [density, setDensity] = useState("default");
  const [selectedIds, setSelectedIds] = useState([]);
  const [sortConfig, setSortConfig] = useState({ key: "fullName", direction: "asc" });
  const [scrollTop, setScrollTop] = useState(0);
  const scrollRef = useRef(null);

  const rowHeight = {
    compact: 58,
    default: 72,
    relaxed: 84,
  }[density] || 72;

  const visibleHeight = 480;

  const [inlineEdit, setInlineEdit] = useState({ userId: null, field: null });
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  // Fetch users when search or page changes
  useEffect(() => {
    const fetchParams = {
      page,
      limit: 30,
      search: search.trim() || undefined,
    };
    dispatch(getGlobalUsers(fetchParams)).then((action) => {
      if (action.payload) {
        const response = action.payload;
        const isPaginated = response && response.users !== undefined;
        const fetchedCount = isPaginated ? response.users.length : response.length;
        if (fetchedCount < 30) {
          setHasMore(false);
        } else {
          setHasMore(true);
        }
      }
    });
  }, [dispatch, search, page]);

  // Reset page when search changes
  useEffect(() => {
    setPage(1);
    setHasMore(true);
    setSelectedIds([]);
  }, [search]);

  // Reset scroll when page resets to 1 (e.g. fresh search applied)
  useEffect(() => {
    if (page === 1 && scrollRef.current) {
      scrollRef.current.scrollTop = 0;
      setScrollTop(0);
    }
  }, [page]);

  const handleInlineEdit = (userId, data) => {
    dispatch(editGlobalUser({ userId, data }));
  };

  const sortedUsers = useMemo(() => {
    const sortableItems = Array.isArray(users) ? [...users] : [];
    if (sortConfig.key !== null) {
      sortableItems.sort((a, b) => {
        let aValue = a[sortConfig.key];
        let bValue = b[sortConfig.key];

        if (sortConfig.key === "isPremium") {
          aValue = a.isPremium ? 1 : 0;
          bValue = b.isPremium ? 1 : 0;
        } else if (sortConfig.key === "approved") {
          aValue = a.approved ? 1 : 0;
          bValue = b.approved ? 1 : 0;
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

  const handleDelete = (userId) => {
    if (
      window.confirm(
        "WARNING: This action is IRREVERSIBLE. Are you sure you want to delete this user from the ENTIRE system?",
      )
    ) {
      dispatch(removeGlobalUser(userId)).then(() => {
        dispatch(getGlobalUsers());
      });
    }
  };

  const handleBulkDelete = async () => {
    if (
      window.confirm(
        `WARNING: This action is IRREVERSIBLE. Are you sure you want to delete all ${selectedIds.length} selected users from the ENTIRE system?`,
      )
    ) {
      await Promise.all(selectedIds.map((id) => dispatch(removeGlobalUser(id))));
      dispatch(getGlobalUsers());
      setSelectedIds([]);
    }
  };

  const handleToggleAll = () => {
    if (selectedIds.length === sortedUsers.length && sortedUsers.length > 0) {
      setSelectedIds([]);
    } else {
      setSelectedIds(sortedUsers.map((u) => u._id));
    }
  };

  const handleToggleOne = (userId) => {
    if (selectedIds.includes(userId)) {
      setSelectedIds(selectedIds.filter((id) => id !== userId));
    } else {
      setSelectedIds([...selectedIds, userId]);
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

  const handleScroll = (e) => {
    const { scrollTop: currentScrollTop, scrollHeight, clientHeight } = e.currentTarget;
    setScrollTop(currentScrollTop);

    // If scrolled past 85% of scroll height, load next batch
    if (currentScrollTop + clientHeight >= scrollHeight - 80) {
      if (hasMore && !loading) {
        setPage((prev) => prev + 1);
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

  const startIndex = Math.max(0, Math.floor(scrollTop / rowHeight) - 2);
  const endIndex = Math.min(
    sortedUsers.length,
    Math.floor((scrollTop + visibleHeight) / rowHeight) + 2
  );

  const visibleUsers = sortedUsers.slice(startIndex, endIndex);
  const totalHeight = sortedUsers.length * rowHeight;
  const offsetY = startIndex * rowHeight;

  const columns = [
    { label: "User", key: "fullName", width: "w-[35%] shrink-0" },
    { label: "College ID", key: "collegeId", width: "w-[15%] shrink-0" },
    { label: "Role", key: "role", width: "w-[15%] shrink-0" },
    { label: "Status", key: "approved", width: "w-[15%] shrink-0" },
    { label: "Actions", key: null, width: "w-[15%] shrink-0 text-right pr-4" },
  ];

  return (
    <div className="space-y-6 text-text-theme-primary">
      <div className="flex flex-col sm:flex-row gap-4 justify-between sm:items-center">
        <div>
          <h1 className="text-scale-h1 text-text-theme-primary">
            Global User Management
          </h1>
          <p className="text-text-theme-secondary text-xs sm:text-sm mt-1">
            Monitor and manage user accounts across the entire application ecosystem
          </p>
        </div>
        <div className="flex flex-col sm:flex-row gap-3 sm:items-center w-full sm:w-auto">
          <DensitySelector currentDensity={density} onChange={setDensity} />
          <div className="relative w-full sm:w-80">
            <MagnifyingGlassIcon className="w-4 h-4 absolute left-3.5 top-3.5 text-text-theme-secondary" />
            <input
              type="text"
              placeholder="Search users by name or email..."
              className="pl-10 pr-4 py-2.5 w-full border border-border-theme rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-main/40 focus:border-primary-main bg-background-paper text-text-theme-primary text-xs font-semibold"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>
      </div>

      <div className="bg-background-paper rounded-2xl border border-border-theme overflow-hidden flex flex-col shadow-sm">
        {/* Table Header */}
        <div className="flex items-center bg-background-default/90 dark:bg-slate-900/90 backdrop-blur-md border-b border-border-theme h-12 shrink-0">
          <div className="w-[5%] shrink-0 pl-4 flex items-center">
            <input
              type="checkbox"
              checked={sortedUsers.length > 0 && selectedIds.length === sortedUsers.length}
              onChange={handleToggleAll}
              className="w-3.5 h-3.5 rounded-sm text-primary-main border-border-theme focus:ring-primary-main cursor-pointer"
              disabled={loading || sortedUsers.length === 0}
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

        {/* Scroll Body */}
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
          ) : sortedUsers.length === 0 ? (
            <div className="py-12 px-6">
              <EmptyState
                message="No global users found"
                description="No user records match the specified search phrase."
                icon={UserGroupIcon}
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

                        {/* Name/Email Column */}
                        <div className="w-[35%] shrink-0 flex items-center pr-4">
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
                            <div className="flex items-center text-[10px] text-text-theme-secondary font-semibold mt-0.5 truncate">
                              <EnvelopeIcon className="w-3 h-3 mr-1 text-text-theme-secondary shrink-0" />
                              {user.email}
                            </div>
                          </div>
                        </div>

                        {/* College ID Column */}
                        <div className="w-[15%] shrink-0">
                          <span className="text-xs text-text-theme-secondary font-mono font-bold">
                            {user.collegeId || "N/A"}
                          </span>
                        </div>

                        {/* Role Badge Column */}
                        <div className="relative w-[15%] shrink-0 select-none">
                          <span
                            onDoubleClick={() => !loading && setInlineEdit({ userId: user._id, field: "role" })}
                            title="Double-click to edit role"
                            className={`px-2.5 py-1 inline-flex text-[10px] leading-4 font-black rounded-lg border uppercase tracking-wider cursor-pointer hover:scale-105 active:scale-95 transition-transform ${
                              user.role === "admin" || user.role === "collegeAdmin"
                                ? "bg-secondary-main/10 text-secondary-dark dark:text-secondary-light border-secondary-main/20"
                                : user.role === "driver"
                                  ? "bg-warning-main/10 text-amber-600 dark:text-warning-main border-warning-main/20"
                                  : user.role === "coordinator" || user.role === "busCoordinator"
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
                                {["student", "driver", "coordinator", "collegeAdmin", "superAdmin"].map((r) => (
                                  <button
                                    key={r}
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      handleInlineEdit(user._id, { role: r });
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
                                      handleInlineEdit(user._id, { approved: s.value });
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

                        {/* Actions Column */}
                        <div className="w-[15%] shrink-0 text-right pr-4">
                          <button
                            onClick={() => handleDelete(user._id)}
                            className="text-rose-main hover:text-white bg-rose-main/10 hover:bg-rose-main p-2 rounded-xl transition-all duration-200 active:scale-95 border border-rose-main/20 hover:border-transparent hover:shadow-md hover:shadow-rose-main/20 group cursor-pointer inline-flex items-center justify-center"
                            title="Delete User Globally"
                          >
                            <TrashIcon className="w-4 h-4 group-hover:rotate-6 transition-transform" />
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

      <AnimatePresence>
        {selectedIds.length > 0 && (
          <motion.div
            initial={{ y: 100, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: 100, opacity: 0 }}
            transition={{ type: "spring", stiffness: 260, damping: 20 }}
            className="fixed bottom-6 left-6 right-6 lg:left-[270px] z-50 bg-background-paper/85 dark:bg-slate-900/85 backdrop-blur-lg border border-border-theme shadow-2xl rounded-2xl p-4 flex flex-col md:flex-row items-center justify-between gap-4 max-w-4xl mx-auto"
          >
            <div className="flex items-center space-x-3">
              <div className="bg-primary-main/10 text-primary-main p-2 rounded-xl border border-primary-main/20 flex items-center justify-center">
                <CheckCircleIcon className="w-5 h-5 text-primary-main" />
              </div>
              <div>
                <p className="text-xs font-black text-text-theme-primary uppercase tracking-wider">
                  {selectedIds.length} Users Selected
                </p>
                <p className="text-[10px] text-text-theme-secondary font-bold">
                  Perform a bulk operation on selected accounts globally
                </p>
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <button
                onClick={handleBulkDelete}
                className="inline-flex items-center gap-1.5 bg-rose-main/10 hover:bg-rose-main hover:text-white text-rose-main px-3.5 py-2 rounded-xl transition-all duration-200 text-xs font-black cursor-pointer border border-rose-main/20 hover:border-transparent active:scale-95 hover:shadow-md hover:shadow-rose-main/10"
              >
                <TrashIcon className="w-4 h-4" />
                Delete Globally
              </button>

              <button
                onClick={() => setSelectedIds([])}
                className="px-3.5 py-2 rounded-xl hover:bg-background-default text-text-theme-secondary hover:text-text-theme-primary transition-all text-xs font-black border border-transparent cursor-pointer"
              >
                Cancel
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default GlobalUsers;
