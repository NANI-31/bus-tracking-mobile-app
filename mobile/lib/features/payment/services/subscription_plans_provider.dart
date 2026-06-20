import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/utils/app_logger.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'dart:async';

final subscriptionPlansProvider = AsyncNotifierProvider<SubscriptionPlansNotifier, List<dynamic>>(
  () => SubscriptionPlansNotifier(),
);

final activeSubscriptionPlansProvider = Provider<AsyncValue<List<dynamic>>>((ref) {
  final allPlansAsync = ref.watch(subscriptionPlansProvider);
  return allPlansAsync.whenData(
    (list) => list.where((p) => p['isActive'] as bool? ?? false).toList(),
  );
});

class SubscriptionPlansNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  FutureOr<List<dynamic>> build() async {
    return _fetchPlans();
  }

  Future<List<dynamic>> _fetchPlans() async {
    final repo = ref.read(paymentRepositoryProvider);
    final user = ref.read(currentUserProvider);
    if (user != null && user.role == UserRole.superAdmin) {
      return await repo.getAllPlans();
    } else {
      return await repo.getPlans();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPlans());
  }

  Future<void> togglePlanActiveStatus(Map<String, dynamic> plan, bool isActive) async {
    final repo = ref.read(paymentRepositoryProvider);
    final currentPlans = state.valueOrNull ?? [];
    final originalPlans = [...currentPlans];
    
    final updated = currentPlans.map((p) {
      if (p['_id'] == plan['_id']) {
        return {...p, 'isActive': isActive};
      }
      return p;
    }).toList();
    state = AsyncValue.data(updated);

    try {
      await repo.updatePlan(plan['_id'], {'isActive': isActive});
    } catch (e) {
      AppLogger.e("Error updating active status in provider: $e");
      state = AsyncValue.data(originalPlans);
      rethrow;
    }
  }

  Future<void> createPlan(Map<String, dynamic> data) async {
    final repo = ref.read(paymentRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      await repo.createPlan(data);
      final list = await _fetchPlans();
      state = AsyncValue.data(list);
    } catch (e) {
      AppLogger.e("Error creating plan in provider: $e");
      state = await AsyncValue.guard(() => _fetchPlans());
      rethrow;
    }
  }

  Future<void> updatePlan(String planId, Map<String, dynamic> data) async {
    final repo = ref.read(paymentRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      await repo.updatePlan(planId, data);
      final list = await _fetchPlans();
      state = AsyncValue.data(list);
    } catch (e) {
      AppLogger.e("Error updating plan in provider: $e");
      state = await AsyncValue.guard(() => _fetchPlans());
      rethrow;
    }
  }

  Future<void> deletePlan(String planId) async {
    final repo = ref.read(paymentRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      await repo.deletePlan(planId);
      final list = await _fetchPlans();
      state = AsyncValue.data(list);
    } catch (e) {
      AppLogger.e("Error deleting plan in provider: $e");
      state = await AsyncValue.guard(() => _fetchPlans());
      rethrow;
    }
  }
}
