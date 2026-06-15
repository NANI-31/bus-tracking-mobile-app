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

  useEffect(() => {
    dispatch(getUsers());
    if (userInfo?.collegeId) {
      dispatch(getCollege(userInfo.collegeId));
    }
  }, [dispatch, userInfo?.collegeId]);

  const filteredUsers = (Array.isArray(users) ? users : []).filter((user) => {
    const matchesFilter = filter === "all" || user.role === filter;
    const matchesSearch =
      user.fullName.toLowerCase().includes(search.toLowerCase()) ||
      user.email.toLowerCase().includes(search.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const handleApprove = (userId) => {
    dispatch(editUser({ userId, data: { approved: true } }));
  };

  const handleReject = (userId) => {
    dispatch(editUser({ userId, data: { approved: false } }));
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

  return (
    <div className="space-y-6">
      <div className="flex flex-col lg:flex-row gap-4 justify-between lg:items-center">
        <h1 className="text-scale-h1 text-slate-800">User Management</h1>
        <div className="flex flex-col sm:flex-row gap-3 sm:items-center w-full lg:w-auto">
          <DensitySelector currentDensity={density} onChange={setDensity} />
          {currentCollege?.allowManualPremium && (
            <button
              onClick={() => setBulkModal(true)}
              className="flex items-center justify-center space-x-2 bg-[#1E90FF] text-white px-4 py-2 rounded-lg hover:bg-indigo-700 transition-colors"
            >
              <CloudArrowUpIcon className="w-5 h-5" />
              <span>Bulk Premium</span>
            </button>
          )}
          <div className="relative flex-1 sm:w-64">
            <MagnifyingGlassIcon className="w-5 h-5 absolute left-3 top-2.5 text-gray-400" />
            <input
              type="text"
              placeholder="Search users..."
              className="pl-10 pr-4 py-2 w-full border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <select
            className="border rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white cursor-pointer w-full sm:w-auto font-bold text-xs"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
          >
            <option value="all">All Roles</option>
            <option value="student">Student</option>
            <option value="driver">Driver</option>
            <option value="coordinator">Coordinator</option>
          </select>
        </div>
      </div>

      <UserTable users={filteredUsers} onOpenActions={handleOpenActions} density={density} />

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
    </div>
  );
};

export default Users;
