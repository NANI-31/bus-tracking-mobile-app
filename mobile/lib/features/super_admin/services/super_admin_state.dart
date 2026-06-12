import 'package:collegebus/features/audit/domain/audit_log_model.dart';
import 'package:collegebus/features/system/domain/system_config_model.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/features/payment/domain/transaction_model.dart';

class SuperAdminState {
  final List<AuditLogModel> auditLogs;
  final SystemConfigModel? systemConfig;
  final List<CollegeModel> colleges;
  final List<UserModel> globalUsers;
  final List<SosModel> sosLogs;
  final List<SosModel> globalActiveSos;
  final List<TransactionModel> transactions;
  final bool transactionsHasMore;
  final bool globalUsersHasMore;
  final int transactionsPage;
  final int globalUsersPage;

  const SuperAdminState({
    this.auditLogs = const [],
    this.systemConfig,
    this.colleges = const [],
    this.globalUsers = const [],
    this.sosLogs = const [],
    this.globalActiveSos = const [],
    this.transactions = const [],
    this.transactionsHasMore = true,
    this.globalUsersHasMore = true,
    this.transactionsPage = 1,
    this.globalUsersPage = 1,
  });

  SuperAdminState copyWith({
    List<AuditLogModel>? auditLogs,
    SystemConfigModel? systemConfig,
    List<CollegeModel>? colleges,
    List<UserModel>? globalUsers,
    List<SosModel>? sosLogs,
    List<SosModel>? globalActiveSos,
    List<TransactionModel>? transactions,
    bool? transactionsHasMore,
    bool? globalUsersHasMore,
    int? transactionsPage,
    int? globalUsersPage,
  }) {
    return SuperAdminState(
      auditLogs: auditLogs ?? this.auditLogs,
      systemConfig: systemConfig ?? this.systemConfig,
      colleges: colleges ?? this.colleges,
      globalUsers: globalUsers ?? this.globalUsers,
      sosLogs: sosLogs ?? this.sosLogs,
      globalActiveSos: globalActiveSos ?? this.globalActiveSos,
      transactions: transactions ?? this.transactions,
      transactionsHasMore: transactionsHasMore ?? this.transactionsHasMore,
      globalUsersHasMore: globalUsersHasMore ?? this.globalUsersHasMore,
      transactionsPage: transactionsPage ?? this.transactionsPage,
      globalUsersPage: globalUsersPage ?? this.globalUsersPage,
    );
  }
}
