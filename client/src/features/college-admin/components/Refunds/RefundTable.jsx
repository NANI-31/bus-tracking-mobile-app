import React from "react";
import { useDispatch } from "react-redux";
import {
  CheckIcon,
  XMarkIcon,
  UserIcon,
  CalendarDaysIcon,
  CurrencyRupeeIcon,
} from "@heroicons/react/24/outline";
import { resolveRefund } from "../../slices/collegeAdminSlice";

const RefundTable = ({ requests, loading }) => {
  const dispatch = useDispatch();

  const handleResolve = (transactionId, status) => {
    const adminComment = window.prompt(`Admin Comment for ${status}:`) || "";
    dispatch(resolveRefund({ transactionId, status, adminComment }));
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!requests || requests.length === 0) {
    return (
      <div className="bg-white p-12 text-center rounded-xl border border-dashed border-slate-300">
        <div className="mx-auto w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mb-4">
          <CalendarDaysIcon className="w-8 h-8 text-slate-400" />
        </div>
        <h3 className="text-lg font-medium text-slate-800">
          No Pending Refunds
        </h3>
        <p className="text-slate-500 mt-1">
          All refund requests have been resolved.
        </p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left">
          <thead className="bg-slate-50 border-b border-slate-200">
            <tr>
              <th className="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                User
              </th>
              <th className="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Plan / Amount
              </th>
              <th className="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Transaction ID
              </th>
              <th className="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Request Date
              </th>
              <th className="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200">
            {requests.map((tx) => (
              <tr key={tx._id} className="hover:bg-slate-50 transition-colors">
                <td className="px-6 py-4">
                  <div className="flex items-center">
                    <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center mr-3">
                      <UserIcon className="w-4 h-4 text-blue-600" />
                    </div>
                    <div>
                      <div className="text-sm font-medium text-slate-800">
                        {tx.userId?.name || "Unknown"}
                      </div>
                      <div className="text-xs text-slate-500">
                        {tx.userId?.email || "No Email"}
                      </div>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center text-sm font-medium text-slate-800">
                    <CurrencyRupeeIcon className="w-4 h-4 mr-1 text-slate-400" />
                    {tx.amount}
                  </div>
                  <div className="text-xs text-slate-500 capitalize">
                    {tx.plan} Plan
                  </div>
                </td>
                <td className="px-6 py-4">
                  <code className="text-xs bg-slate-100 px-2 py-1 rounded text-slate-600">
                    {tx.paymentId}
                  </code>
                </td>
                <td className="px-6 py-4 text-sm text-slate-500">
                  {new Date(tx.createdAt).toLocaleDateString("en-IN", {
                    day: "2-digit",
                    month: "short",
                    year: "numeric",
                  })}
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => handleResolve(tx._id, "refunded")}
                      className="p-2 bg-green-50 text-green-600 rounded-lg hover:bg-green-100 transition-all tooltip"
                      title="Approve Refund"
                    >
                      <CheckIcon className="w-5 h-5" />
                    </button>
                    <button
                      onClick={() => handleResolve(tx._id, "refund_denied")}
                      className="p-2 bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-all"
                      title="Deny Refund"
                    >
                      <XMarkIcon className="w-5 h-5" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default RefundTable;
