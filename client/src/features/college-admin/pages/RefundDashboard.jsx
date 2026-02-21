import React, { useEffect } from "react";
import { useDispatch, useSelector } from "react-redux";
import { BanknotesIcon, ArrowPathIcon } from "@heroicons/react/24/outline";
import { getRefundRequests } from "../slices/collegeAdminSlice";
import RefundTable from "../components/Refunds/RefundTable";

const RefundDashboard = () => {
  const dispatch = useDispatch();
  const { refundRequests, loading } = useSelector(
    (state) => state.collegeAdmin,
  );

  useEffect(() => {
    dispatch(getRefundRequests());
  }, [dispatch]);

  return (
    <div className="space-y-6">
      {/* Header Snippet */}
      <div className="flex justify-between items-center bg-white p-6 rounded-xl shadow-sm border border-slate-200">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 flex items-center">
            <BanknotesIcon className="w-8 h-8 mr-2 text-rose-500" />
            Refund Management
          </h1>
          <p className="text-slate-500 mt-1">
            Review and resolve payment refund requests from students.
          </p>
        </div>
        <div>
          <button
            onClick={() => dispatch(getRefundRequests())}
            className="flex items-center px-4 py-2 bg-white border border-slate-300 rounded-lg text-slate-700 hover:bg-slate-50 transition-all font-medium shadow-sm"
          >
            <ArrowPathIcon
              className={`w-5 h-5 mr-2 ${loading ? "animate-spin" : ""}`}
            />
            Refresh
          </button>
        </div>
      </div>

      <RefundTable requests={refundRequests} loading={loading} />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-blue-50 border border-blue-100 p-6 rounded-xl">
          <h4 className="text-blue-800 font-bold text-lg mb-1">
            Total Requests
          </h4>
          <div className="text-3xl font-black text-blue-900">
            {refundRequests.length}
          </div>
        </div>
        {/* Placeholder for more stats if needed */}
      </div>
    </div>
  );
};

export default RefundDashboard;
