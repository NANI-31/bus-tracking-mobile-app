import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/bus/application/bus_provider.dart';
import 'package:collegebus/core/providers/repository_providers.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/shared/widgets/shimmer_skeletons.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';

class TeacherOverrideRequestsScreen extends ConsumerStatefulWidget {
  const TeacherOverrideRequestsScreen({super.key});

  @override
  ConsumerState<TeacherOverrideRequestsScreen> createState() =>
      _TeacherOverrideRequestsScreenState();
}

class _TeacherOverrideRequestsScreenState
    extends ConsumerState<TeacherOverrideRequestsScreen> {
  bool _isProcessing = false;

  Future<void> _handleRequest(String requestId, String status) async {
    setState(() => _isProcessing = true);
    try {
      final repo = ref.read(busRepositoryProvider);
      await repo.handleTeacherOverrideRequest(requestId, status);
      ref.invalidate(teacherOverrideRequestsProvider);
      if (mounted) {
        SuccessModal.show(
          context: context,
          title: status == 'approved' ? 'Request Approved' : 'Request Rejected',
          message: status == 'approved'
              ? 'Teacher is now authorized to broadcast locations.'
              : 'Teacher override request has been rejected.',
          primaryActionText: 'OK',
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(
          context: context,
          error: 'Action failed: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(teacherOverrideRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: 'Teacher Override Requests'.text.bold.make(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: requestsAsync.when(
        loading: () => const BusListSkeleton(),
        error: (err, stack) =>
            err.toString().text.color(AppColors.error).make().centered(),
        data: (requests) {
          if (requests.isEmpty) {
            return VStack([
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.grey,
              ).pOnly(bottom: 16),
              'No pending teacher tracking requests'.text.gray500.make(),
            ]).centered();
          }

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            itemBuilder: (context, index) {
              final reqMap = requests[index];
              final requestId = reqMap['_id'] as String;
              final teacher = reqMap['teacherId'] as Map<String, dynamic>? ?? {};
              final bus = reqMap['busId'] as Map<String, dynamic>? ?? {};
              final teacherName = teacher['fullName'] as String? ?? 'Teacher';
              final teacherEmail = teacher['email'] as String? ?? '';
              final busNumber = bus['busNumber'] as String? ?? 'N/A';

              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: VStack([
                  HStack([
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: 'Bus $busNumber'.text.bold.color(AppColors.primary).make(),
                    ),
                    const Spacer(),
                    'Pending'.text.amber500.bold.make(),
                  ]).pOnly(bottom: 12),

                  HStack([
                    const Icon(Icons.person, color: Colors.blueGrey, size: 20).pOnly(right: 8),
                    VStack([
                      teacherName.text.bold.lg.make(),
                      if (teacherEmail.isNotEmpty)
                        teacherEmail.text.size(12).gray500.make(),
                    ]).expand(),
                  ]),

                  const Divider().pSymmetric(v: 12),

                  if (_isProcessing)
                    const CircularProgressIndicator().centered().pOnly(bottom: 8)
                  else
                    HStack([
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade300),
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _handleRequest(requestId, 'rejected'),
                          child: 'Reject'.text.bold.make(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _handleRequest(requestId, 'approved'),
                          child: 'Approve'.text.bold.make(),
                        ),
                      ),
                    ]),
                ]).p(16),
              );
            },
          );
        },
      ),
    );
  }
}
