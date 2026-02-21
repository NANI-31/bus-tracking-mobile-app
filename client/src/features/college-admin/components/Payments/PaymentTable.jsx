import React from "react";

const PaymentTable = ({ transactions, loading }) => {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-slate-200">
          <thead className="bg-slate-50">
            <tr>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase">
                Student
              </th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase">
                Transaction
              </th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase">
                Plan & Amount
              </th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase">
                Date
              </th>
              <th className="px-6 py-4 text-right text-xs font-semibold text-slate-500 uppercase">
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
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center">
                    <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center text-[#1E90FF] font-bold">
                      {tx.userId?.fullName?.charAt(0) || "?"}
                    </div>
                    <div className="ml-4">
                      <div className="text-sm font-semibold text-slate-900">
                        {tx.userId?.fullName || "N/A"}
                      </div>
                      <div className="text-xs text-slate-500">
                        {tx.userId?.email || "No email"}
                      </div>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-xs font-mono text-slate-500">
                    ID: {tx.paymentId}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
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
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-slate-600">
                    {new Date(tx.createdAt).toLocaleDateString()}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right">
                  <span className="px-3 py-1 bg-green-100 text-green-700 rounded-full text-xs font-bold">
                    Successful
                  </span>
                </td>
              </tr>
            ))}

            {transactions.length === 0 && !loading && (
              <tr>
                <td
                  colSpan="5"
                  className="px-6 py-12 text-center text-slate-400"
                >
                  No transactions found for the selected criteria.
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
