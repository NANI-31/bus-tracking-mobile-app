import React from "react";
import EmptyState from "@/components/common/EmptyState";
import { CreditCardIcon } from "@heroicons/react/24/outline";

const PaymentTable = ({ transactions, loading, density = "default" }) => {
  const paddingTh = {
    compact: "px-4 py-2",
    default: "px-6 py-4",
    relaxed: "px-8 py-6",
  }[density] || "px-6 py-4";

  const paddingTd = {
    compact: "px-4 py-2",
    default: "px-6 py-4",
    relaxed: "px-8 py-6",
  }[density] || "px-6 py-4";

  return (
    <div className="bg-background-paper rounded-xl shadow-sm border border-border-theme overflow-hidden">
      <div className="overflow-x-auto max-h-[600px] overflow-y-auto">
        <table className="min-w-full divide-y divide-slate-200">
          <thead className="bg-slate-50/95 dark:bg-slate-800/95 backdrop-blur-xs sticky top-0 z-10">
            <tr>
              <th className={`${paddingTh} text-left text-scale-table-header text-slate-500`}>
                Student
              </th>
              <th className={`${paddingTh} text-left text-scale-table-header text-slate-500`}>
                Transaction
              </th>
              <th className={`${paddingTh} text-left text-scale-table-header text-slate-500`}>
                Plan & Amount
              </th>
              <th className={`${paddingTh} text-left text-scale-table-header text-slate-500`}>
                Date
              </th>
              <th className={`${paddingTh} text-right text-scale-table-header text-slate-500`}>
                Status
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-slate-200">
            {transactions.map((tx) => (
              <tr
                key={tx._id}
                className="hover:bg-slate-50/50 transition-colors"
              >
                <td className={`${paddingTd} whitespace-nowrap`}>
                  <div className="flex items-center">
                    <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center text-[#1E90FF] font-bold shrink-0">
                      {tx.userId?.fullName?.charAt(0) || "?"}
                    </div>
                    <div className="ml-4">
                      <div className="text-scale-table-body text-slate-900">
                        {tx.userId?.fullName || "N/A"}
                      </div>
                      <div className="text-xs text-slate-500">
                        {tx.userId?.email || "No email"}
                      </div>
                    </div>
                  </div>
                </td>
                <td className={`${paddingTd} whitespace-nowrap`}>
                  <div className="text-xs font-mono text-slate-500">
                    ID: {tx.paymentId}
                  </div>
                </td>
                <td className={`${paddingTd} whitespace-nowrap`}>
                  <div className="flex flex-col">
                    <span
                      className={`text-xs font-bold uppercase ${
                        tx.planType === "semester"
                          ? "text-purple-600"
                          : "text-[#1E90FF]"
                      }`}
                    >
                      {tx.planType}
                    </span>
                    <span className="text-sm font-bold text-slate-800">
                      ₹{tx.amount.toFixed(2)}
                    </span>
                  </div>
                </td>
                <td className={`${paddingTd} whitespace-nowrap`}>
                  <div className="text-sm text-slate-600">
                    {new Date(tx.createdAt).toLocaleDateString()}
                  </div>
                </td>
                <td className={`${paddingTd} whitespace-nowrap text-right`}>
                  <span className="px-3 py-1 bg-green-100 text-green-700 rounded-full text-xs font-bold">
                    Successful
                  </span>
                </td>
              </tr>
            ))}

            {transactions.length === 0 && !loading && (
              <tr>
                <td colSpan="5" className="px-6 py-12">
                  <EmptyState 
                    message="No transaction records found"
                    description="Ensure your date filters are correct or look up a different user email."
                    icon={CreditCardIcon}
                  />
                </td>
              </tr>
            )}
            {loading && (
              <tr>
                <td colSpan="5" className="px-6 py-12 text-center">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#1E90FF] mx-auto"></div>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default PaymentTable;
