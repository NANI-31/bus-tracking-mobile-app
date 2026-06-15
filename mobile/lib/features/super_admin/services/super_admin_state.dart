import 'package:collegebus/features/audit/domain/audit_log_model.dart';
import 'package:collegebus/features/system/domain/system_config_model.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/features/payment/domain/transaction_model.dart';

class SuperAdminState {
  final List<AuditLogModel> auditLogs;
  final SystemConfigModel? systemConfig;
  final List<SystemConfigModel> allConfigs;
  final List<CollegeModel> colleges;
  final List<UserModel> globalUsers;
  final List<SosModel> sosLogs;
  final List<SosModel> globalActiveSos;
  final List<TransactionModel> transactions;
  final bool transactionsHasMore;
  final bool globalUsersHasMore;
  final bool auditLogsHasMore;
  final int transactionsPage;
  final int globalUsersPage;
  final int auditLogsPage;
  final int auditLogsTotal;

  const SuperAdminState({
    this.auditLogs = const [],
    this.systemConfig,
    this.allConfigs = const [],
    this.colleges = const [],
    this.globalUsers = const [],
    this.sosLogs = const [],
    this.globalActiveSos = const [],
    this.transactions = const [],
    this.transactionsHasMore = true,
    this.globalUsersHasMore = true,
    this.auditLogsHasMore = true,
    this.transactionsPage = 1,
    this.globalUsersPage = 1,
    this.auditLogsPage = 0,
    this.auditLogsTotal = 0,
  });

  SuperAdminState copyWith({
    List<AuditLogModel>? auditLogs,
    SystemConfigModel? systemConfig,
    List<SystemConfigModel>? allConfigs,
    List<CollegeModel>? colleges,
    List<UserModel>? globalUsers,
    List<SosModel>? sosLogs,
    List<SosModel>? globalActiveSos,
    List<TransactionModel>? transactions,
    bool? transactionsHasMore,
    bool? globalUsersHasMore,
    bool? auditLogsHasMore,
    int? transactionsPage,
    int? globalUsersPage,
    int? auditLogsPage,
    int? auditLogsTotal,
  }) {
    return SuperAdminState(
      auditLogs: auditLogs ?? this.auditLogs,
      systemConfig: systemConfig ?? this.systemConfig,
      allConfigs: allConfigs ?? this.allConfigs,
      colleges: colleges ?? this.colleges,
      globalUsers: globalUsers ?? this.globalUsers,
      sosLogs: sosLogs ?? this.sosLogs,
      globalActiveSos: globalActiveSos ?? this.globalActiveSos,
      transactions: transactions ?? this.transactions,
      transactionsHasMore: transactionsHasMore ?? this.transactionsHasMore,
      globalUsersHasMore: globalUsersHasMore ?? this.globalUsersHasMore,
      auditLogsHasMore: auditLogsHasMore ?? this.auditLogsHasMore,
      transactionsPage: transactionsPage ?? this.transactionsPage,
      globalUsersPage: globalUsersPage ?? this.globalUsersPage,
      auditLogsPage: auditLogsPage ?? this.auditLogsPage,
      auditLogsTotal: auditLogsTotal ?? this.auditLogsTotal,
    );
  }
}
