import React, { useEffect, useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { motion, AnimatePresence } from "framer-motion";
import {
  CheckCircleIcon,
  XCircleIcon,
  TrashIcon,
  MagnifyingGlassIcon,
  FunnelIcon,
  CloudArrowUpIcon,
  ShieldCheckIcon,
  CurrencyDollarIcon,
} from "@heroicons/react/24/outline";
import {
  getUsers,
  editUser,
  removeUser,
  getCollege,
  activateUserPremium,
  bulkUploadPremium,
} from "../slices/collegeAdminSlice";
import ConfirmationModal from "@/components/common/ConfirmationModal";

import UserTable from "../components/Users/UserTable";
import BulkPremiumModal from "../components/Users/BulkPremiumModal";
import UserActionModal from "../components/Users/UserActionModal";
import DensitySelector from "@/components/common/DensitySelector";

const Users = () => {
  const dispatch = useDispatch();
  const { users, currentCollege, loading } = useSelector(
    (state) => state.collegeAdmin,
  );
  const { userInfo } = useSelector((state) => state.auth);
  const [filter, setFilter] = useState("all");
  const [search, setSearch] = useState("");
  const [bulkModal, setBulkModal] = useState(false);
  const [uploadFile, setUploadFile] = useState(null);
  const [planType, setPlanType] = useState("monthly");
  const [deleteModal, setDeleteModal] = useState({
    isOpen: false,
    userId: null,
  });
  const [actionModal, setActionModal] = useState({
    isOpen: false,
    userId: null,
  });
  const [density, setDensity] = useState("default");
  const [selectedIds, setSelectedIds] = useState([]);

  useEffect(() => {
    if (userInfo?.collegeId) {
      dispatch(getCollege(userInfo.collegeId));
    }
  }, [dispatch, userInfo?.collegeId]);

  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  // Fetch users when filter, search, or page changes
  useEffect(() => {
    const fetchParams = {
      page,
      limit: 30,
      search: search.trim() || undefined,
      role: filter === "all" ? undefined : filter,
    };
    dispatch(getUsers(fetchParams)).then((action) => {
      if (action.payload?.response) {
        const { response } = action.payload;
        const isPaginated = response && response.users !== undefined;
        const fetchedCount = isPaginated ? response.users.length : response.length;
        if (fetchedCount < 30) {
          setHasMore(false);
        } else {
          setHasMore(true);
        }
      }
    });
  }, [dispatch, filter, search, page]);

  // Reset page and selection when filter or search changes
  useEffect(() => {
    setPage(1);
    setHasMore(true);
    setSelectedIds([]);
  }, [filter, search]);

  const handleApprove = (userId) => {
    dispatch(editUser({ userId, data: { approved: true } }));
  };

  const handleReject = (userId) => {
    dispatch(editUser({ userId, data: { approved: false } }));
  };

  const handleInlineEdit = (userId, data) => {
    dispatch(editUser({ userId, data }));
  };

  const handleDelete = (userId) => {
    setDeleteModal({ isOpen: true, userId });
  };

  const confirmDelete = () => {
    if (deleteModal.userId) {
      dispatch(removeUser(deleteModal.userId));
      setDeleteModal({ isOpen: false, userId: null });
    }
  };

  const handleActivatePremium = (userId, type) => {
    dispatch(activateUserPremium({ userId, planType: type })).then(() => {
      dispatch(getUsers()); // Refresh list
    });
  };

  const handleBulkUpload = (e) => {
    e.preventDefault();
    if (!uploadFile) return;

    const formData = new FormData();
    formData.append("file", uploadFile);
    formData.append("planType", planType);

    dispatch(bulkUploadPremium(formData)).then(() => {
      setBulkModal(false);
      setUploadFile(null);
      dispatch(getUsers());
    });
  };

  const handleOpenActions = (user) => {
    setActionModal({ isOpen: true, userId: user._id });
  };

  const selectedUser = users.find((u) => u._id === actionModal.userId);

  // Bulk Actions
  const handleBulkApprove = async () => {
    if (window.confirm(`Are you sure you want to approve all ${selectedIds.length} selected users?`)) {
      await Promise.all(
        selectedIds.map((id) => dispatch(editUser({ userId: id, data: { approved: true } })))
      );
      dispatch(getUsers());
      setSelectedIds([]);
    }
  };

  const handleBulkReject = async () => {
    if (window.confirm(`Are you sure you want to suspend/reject all ${selectedIds.length} selected users?`)) {
      await Promise.all(
        selectedIds.map((id) => dispatch(editUser({ userId: id, data: { approved: false } })))
      );
      dispatch(getUsers());
      setSelectedIds([]);
    }
  };

  const handleBulkPremium = async () => {
    if (window.confirm(`Are you sure you want to activate Premium for all ${selectedIds.length} selected users?`)) {
      await Promise.all(
        selectedIds.map((id) => dispatch(activateUserPremium({ userId: id, planType: "monthly" })))
      );
      dispatch(getUsers());
      setSelectedIds([]);
    }
  };

  const handleBulkDelete = async () => {
    if (window.confirm(`WARNING: This will permanently delete all ${selectedIds.length} selected users. Proceed?`)) {
      await Promise.all(
        selectedIds.map((id) => dispatch(removeUser(id)))
      );
      dispatch(getUsers());
      setSelectedIds([]);
    }
  };

  return (
    <div className="space-y-6 text-text-theme-primary">
      <div className="flex flex-col lg:flex-row gap-4 justify-between lg:items-center">
        <div>
          <h1 className="text-scale-h1 text-text-theme-primary">User Management</h1>
          <p className="text-text-theme-secondary text-xs sm:text-sm mt-1">
            Manage students, drivers, and coordinators in your college fleet
          </p>
        </div>
        <div className="flex flex-col sm:flex-row gap-3 sm:items-center w-full lg:w-auto">
          <DensitySelector currentDensity={density} onChange={setDensity} />
          {currentCollege?.allowManualPremium && (
            <button
              onClick={() => setBulkModal(true)}
              className="flex items-center justify-center space-x-2 bg-primary-main text-white px-4 py-2.5 rounded-xl hover:bg-primary-dark transition-all duration-200 shadow-md hover:shadow-primary-main/20 text-xs font-black cursor-pointer active:scale-95 border-none"
            >
              <CloudArrowUpIcon className="w-4 h-4 text-white" />
              <span>Bulk Premium</span>
            </button>
          )}
          <div className="relative flex-1 sm:w-64">
            <MagnifyingGlassIcon className="w-4 h-4 absolute left-3.5 top-3.5 text-text-theme-secondary" />
            <input
              type="text"
              placeholder="Search users..."
              className="pl-10 pr-4 py-2.5 w-full border border-border-theme rounded-xl focus:outline-none focus:ring-2 focus:ring-primary-main/40 focus:border-primary-main bg-background-paper text-text-theme-primary text-xs font-semibold"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <select
            className="border border-border-theme rounded-xl px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-primary-main/40 focus:border-primary-main bg-background-paper text-text-theme-primary cursor-pointer w-full sm:w-auto font-bold text-xs"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          >
            <option value="all">All Roles</option>
            <option value="student">Student</option>
            <option value="driver">Driver</option>
            <option value="busCoordinator">Coordinator</option>
          </select>
        </div>
      </div>

      <UserTable
        users={users}
        onOpenActions={handleOpenActions}
        density={density}
        selectedIds={selectedIds}
        onSelectChange={setSelectedIds}
        loading={loading}
        onInlineEdit={handleInlineEdit}
        onLoadMore={() => setPage((prev) => prev + 1)}
        hasMore={hasMore}
        page={page}
      />

      <ConfirmationModal
        isOpen={deleteModal.isOpen}
        onClose={() => setDeleteModal({ isOpen: false, userId: null })}
        onConfirm={confirmDelete}
        title="Delete User"
        message="Are you sure you want to permanentely delete this user? This action cannot be undone."
        confirmText="Delete"
      />

      <BulkPremiumModal
        isOpen={bulkModal}
        onClose={() => setBulkModal(false)}
        onSubmit={handleBulkUpload}
        planType={planType}
        setPlanType={setPlanType}
        uploadFile={uploadFile}
        setUploadFile={setUploadFile}
      />

      <UserActionModal
        isOpen={actionModal.isOpen}
        onClose={() => setActionModal({ isOpen: false, userId: null })}
        selectedUser={selectedUser}
        handleApprove={handleApprove}
        handleReject={handleReject}
        handleActivatePremium={handleActivatePremium}
        handleDelete={(userId) => {
          handleDelete(userId);
          setActionModal({ isOpen: false, userId: null });
        }}
        currentCollege={currentCollege}
      />

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
                  Perform a bulk operation on selected accounts
                </p>
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-2">
              <button
                onClick={handleBulkApprove}
                className="inline-flex items-center gap-1.5 bg-emerald-main/10 hover:bg-emerald-main hover:text-white text-emerald-main px-3.5 py-2 rounded-xl transition-all duration-200 text-xs font-black cursor-pointer border border-emerald-main/20 hover:border-transparent active:scale-95 hover:shadow-md hover:shadow-emerald-main/10"
              >
                <CheckCircleIcon className="w-4 h-4" />
                Approve
              </button>

              <button
                onClick={handleBulkReject}
                className="inline-flex items-center gap-1.5 bg-warning-main/10 hover:bg-warning-main hover:text-white text-warning-main px-3.5 py-2 rounded-xl transition-all duration-200 text-xs font-black cursor-pointer border border-warning-main/20 hover:border-transparent active:scale-95 hover:shadow-md hover:shadow-warning-main/10"
              >
                <XCircleIcon className="w-4 h-4" />
                Suspend
              </button>

              {currentCollege?.allowManualPremium && (
                <button
                  onClick={handleBulkPremium}
                  className="inline-flex items-center gap-1.5 bg-amber-500/10 hover:bg-amber-500 hover:text-white text-amber-600 dark:text-amber-400 dark:hover:text-white px-3.5 py-2 rounded-xl transition-all duration-200 text-xs font-black cursor-pointer border border-amber-500/20 hover:border-transparent active:scale-95 hover:shadow-md hover:shadow-amber-500/10"
                >
                  <ShieldCheckIcon className="w-4 h-4" />
                  Premium
                </button>
              )}

              <button
                onClick={handleBulkDelete}
                className="inline-flex items-center gap-1.5 bg-rose-main/10 hover:bg-rose-main hover:text-white text-rose-main px-3.5 py-2 rounded-xl transition-all duration-200 text-xs font-black cursor-pointer border border-rose-main/20 hover:border-transparent active:scale-95 hover:shadow-md hover:shadow-rose-main/10"
              >
                <TrashIcon className="w-4 h-4" />
                Delete
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

export default Users;
