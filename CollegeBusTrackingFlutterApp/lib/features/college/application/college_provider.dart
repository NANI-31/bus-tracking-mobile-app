import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/core/providers/repository_providers.dart';

/// College notifier
class CollegeNotifier extends AsyncNotifier<List<CollegeModel>> {
  @override
  Future<List<CollegeModel>> build() async {
    final repo = ref.watch(collegeRepositoryProvider);
    return await repo.getAllColleges();
  }

  Future<CollegeModel?> getCollege(String collegeId) async {
    final colleges = state.value ?? await build();
    try {
      return colleges.firstWhere((c) => c.id == collegeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

/// CollegeService provider
final collegeServiceProvider =
    AsyncNotifierProvider<CollegeNotifier, List<CollegeModel>>(
      CollegeNotifier.new,
    );
