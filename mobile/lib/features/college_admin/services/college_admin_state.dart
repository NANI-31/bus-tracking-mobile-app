import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/features/payment/domain/transaction_model.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';

class CollegeAdminState {
  final List<UserModel> pendingUsers;
  final List<UserModel> collegeUsers;
  final List<BusModel> collegeBuses;
  final Map<String, BusLocationModel> fleetLocations;
  final List<SosModel> activeSos;
  final List<SosModel> sosLogs;
  final List<TransactionModel> transactions;
  final bool transactionsHasMore;
  final int transactionsPage;
  final CollegeModel? college;

  const CollegeAdminState({
    this.pendingUsers = const [],
    this.collegeUsers = const [],
    this.collegeBuses = const [],
    this.fleetLocations = const {},
    this.activeSos = const [],
    this.sosLogs = const [],
    this.transactions = const [],
    this.transactionsHasMore = true,
    this.transactionsPage = 1,
    this.college,
  });

  CollegeAdminState copyWith({
    List<UserModel>? pendingUsers,
    List<UserModel>? collegeUsers,
    List<BusModel>? collegeBuses,
    Map<String, BusLocationModel>? fleetLocations,
    List<SosModel>? activeSos,
    List<SosModel>? sosLogs,
    List<TransactionModel>? transactions,
    bool? transactionsHasMore,
    int? transactionsPage,
    CollegeModel? college,
  }) {
    return CollegeAdminState(
      pendingUsers: pendingUsers ?? this.pendingUsers,
      collegeUsers: collegeUsers ?? this.collegeUsers,
      collegeBuses: collegeBuses ?? this.collegeBuses,
      fleetLocations: fleetLocations ?? this.fleetLocations,
      activeSos: activeSos ?? this.activeSos,
      sosLogs: sosLogs ?? this.sosLogs,
      transactions: transactions ?? this.transactions,
      transactionsHasMore: transactionsHasMore ?? this.transactionsHasMore,
      transactionsPage: transactionsPage ?? this.transactionsPage,
      college: college ?? this.college,
    );
  }
}
