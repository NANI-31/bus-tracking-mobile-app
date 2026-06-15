import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/system/data/system_repository.dart';

class SystemAnalysisState {
  final Map<String, dynamic>? storageStats;
  final List<dynamic> collegeStorageHistory;
  final bool isLoadingStats;
  final bool isLoadingHistory;
  final String? statsError;
  final String? historyError;

  const SystemAnalysisState({
    this.storageStats,
    this.collegeStorageHistory = const [],
    this.isLoadingStats = false,
    this.isLoadingHistory = false,
    this.statsError,
    this.historyError,
  });

  SystemAnalysisState copyWith({
    Map<String, dynamic>? storageStats,
    List<dynamic>? collegeStorageHistory,
    bool? isLoadingStats,
    bool? isLoadingHistory,
    String? statsError,
    String? historyError,
  }) {
    return SystemAnalysisState(
      storageStats: storageStats ?? this.storageStats,
      collegeStorageHistory: collegeStorageHistory ?? this.collegeStorageHistory,
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      statsError: statsError ?? this.statsError,
      historyError: historyError ?? this.historyError,
    );
  }
}

class SystemAnalysisNotifier extends StateNotifier<SystemAnalysisState> {
  final SystemRepository _systemRepo = SystemRepository();

  SystemAnalysisNotifier() : super(const SystemAnalysisState());

  Future<void> fetchStorageStats() async {
    state = state.copyWith(isLoadingStats: true, statsError: null);
    try {
      final stats = await _systemRepo.getStorageStats();
      state = state.copyWith(
        storageStats: stats,
        isLoadingStats: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingStats: false,
        statsError: e.toString(),
      );
    }
  }

  Future<void> fetchCollegeStorageHistory(
    String collegeId, {
    String? startDate,
    String? endDate,
  }) async {
    state = state.copyWith(isLoadingHistory: true, historyError: null);
    try {
      final history = await _systemRepo.getCollegeStorageHistory(
        collegeId,
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(
        collegeStorageHistory: history,
        isLoadingHistory: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        historyError: e.toString(),
      );
    }
  }

  void clearHistory() {
    state = state.copyWith(
      collegeStorageHistory: const [],
      historyError: null,
    );
  }
}

final systemAnalysisProvider =
    StateNotifierProvider<SystemAnalysisNotifier, SystemAnalysisState>((ref) {
  return SystemAnalysisNotifier();
});
