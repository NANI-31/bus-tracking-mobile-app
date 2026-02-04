import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/core/providers/api_provider.dart';

/// College notifier
class CollegeNotifier extends AsyncNotifier<List<CollegeModel>> {
  @override
  Future<List<CollegeModel>> build() async {
    final api = ref.watch(apiServiceProvider);
    return await api.getAllColleges();
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





