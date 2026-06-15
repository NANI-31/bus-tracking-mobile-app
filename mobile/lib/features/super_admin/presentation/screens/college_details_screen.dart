import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/college/domain/college_model.dart';
import 'package:collegebus/features/super_admin/application/super_admin_provider.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';

class CollegeDetailsScreen extends ConsumerStatefulWidget {
  final String collegeId;
  final CollegeModel? college;

  const CollegeDetailsScreen({
    super.key,
    required this.collegeId,
    this.college,
  });

  @override
  ConsumerState<CollegeDetailsScreen> createState() => _CollegeDetailsScreenState();
}

class _CollegeDetailsScreenState extends ConsumerState<CollegeDetailsScreen> {
  late CollegeModel _college;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.college != null) {
      _college = widget.college!;
      _isInitialized = true;
    }
  }

  // Action: Verify college
  Future<void> _verifyCollege() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verify College', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to verify ${_college.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final saNotifier = ref.read(superAdminServiceProvider.notifier);
        await saNotifier.verifyCollege(_college.id);
        setState(() {
          _college = _college.copyWith(verified: true);
        });
        if (mounted) {
          SuccessModal.show(
            context: context,
            title: 'College Verified',
            message: '${_college.name} verified successfully',
            primaryActionText: 'OK',
          );
        }
      } catch (e) {
        if (mounted) {
          ApiErrorModal.show(
            context: context,
            error: 'Failed to verify college: $e',
          );
        }
      }
    }
  }

  // Action: Suspend college
  Future<void> _suspendCollege() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Suspend ${_college.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Suspension Reason',
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter a reason';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(ctx, reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        final saNotifier = ref.read(superAdminServiceProvider.notifier);
        await saNotifier.suspendCollege(_college.id, reason);
        setState(() {
          _college = _college.copyWith(
            suspended: true,
            suspensionReason: reason,
            suspendedAt: DateTime.now(),
          );
        });
        if (mounted) {
          SuccessModal.show(
            context: context,
            title: 'College Suspended',
            message: '${_college.name} suspended successfully',
            primaryActionText: 'OK',
          );
        }
      } catch (e) {
        if (mounted) {
          ApiErrorModal.show(
            context: context,
            error: 'Failed to suspend college: $e',
          );
        }
      }
    }
  }

  // Action: Unsuspend college
  Future<void> _unsuspendCollege() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unsuspend College', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to unsuspend ${_college.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Unsuspend'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final saNotifier = ref.read(superAdminServiceProvider.notifier);
        await saNotifier.unsuspendCollege(_college.id);
        setState(() {
          _college = _college.copyWith(
            suspended: false,
            suspensionReason: '',
            suspendedAt: null,
          );
        });
        if (mounted) {
          SuccessModal.show(
            context: context,
            title: 'College Unsuspended',
            message: '${_college.name} is now active.',
            primaryActionText: 'OK',
          );
        }
      } catch (e) {
        if (mounted) {
          ApiErrorModal.show(
            context: context,
            error: 'Failed to unsuspend college: $e',
          );
        }
      }
    }
  }

  // Action: Wipe college data
  Future<void> _wipeCollegeData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Wipe College Data', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('This will wipe all operational data for ${_college.name}. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Wipe Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final saNotifier = ref.read(superAdminServiceProvider.notifier);
        await saNotifier.wipeCollegeData(_college.id, false);
        if (mounted) {
          SuccessModal.show(
            context: context,
            title: 'Data Wiped',
            message: 'College operational data wiped.',
            primaryActionText: 'OK',
          );
        }
      } catch (e) {
        if (mounted) {
          ApiErrorModal.show(
            context: context,
            error: 'Failed to wipe data: $e',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isInitialized) {
      final asyncState = ref.watch(superAdminServiceProvider);
      final list = asyncState.valueOrNull?.colleges ?? [];
      final match = list.where((c) => c.id == widget.collegeId);
      if (match.isNotEmpty) {
        _college = match.first;
        _isInitialized = true;
      }
    }

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('College Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    Color statusColor = Colors.orange;
    String statusText = 'Pending';
    if (_college.suspended) {
      statusColor = Colors.red;
      statusText = 'Suspended';
    } else if (_college.verified) {
      statusColor = Colors.green;
      statusText = 'Verified';
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('College Administration', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Hero Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'college-icon-${_college.id}',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.school, color: Colors.blue, size: 36),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'college-name-${_college.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              _college.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                letterSpacing: -0.4,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Hero(
                          tag: 'college-status-${_college.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withOpacity(0.2)),
                              ),
                              child: Text(
                                statusText.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // General Information Card
            _buildSectionHeader('General Information', isDark),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Address', _college.address ?? 'Not Configured', isDark),
                  const Divider(height: 20, color: Colors.white10),
                  _buildDetailRow('Allowed Domains', _college.allowedDomains.join(', '), isDark),
                  const Divider(height: 20, color: Colors.white10),
                  _buildDetailRow('Primary Administrator', _college.adminName ?? 'Pending Setup', isDark),
                  const Divider(height: 20, color: Colors.white10),
                  _buildDetailRow('Shifts Count', '${_college.shiftCount} Shifts', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Operational Shifts
            _buildSectionHeader('Operational Shifts', isDark),
            if (_college.shifts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'No shifts defined for this college.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ..._college.shifts.map((shift) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shift.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('ID: ${shift.shiftId}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Pickup: ${shift.pickupTime ?? 'N/A'}', style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Drop: ${shift.dropTime ?? 'N/A'}', style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 16),

            // Audit Timeline
            _buildSectionHeader('Audit Logs Timeline', isDark),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineItem(
                    title: 'Registered',
                    time: _college.createdAt,
                    color: Colors.blue,
                  ),
                  if (_college.verified) ...[
                    const SizedBox(height: 16),
                    _buildTimelineItem(
                      title: 'Verified',
                      time: _college.verifiedAt,
                      subtitle: _college.verifiedAt == null ? 'Autoverified / Pre-configured' : null,
                      color: Colors.green,
                    ),
                  ],
                  if (_college.suspended) ...[
                    const SizedBox(height: 16),
                    _buildTimelineItem(
                      title: 'Suspended',
                      time: _college.suspendedAt,
                      subtitle: _college.suspensionReason != null ? 'Reason: "${_college.suspensionReason}"' : null,
                      color: Colors.red,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Danger Zone
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.red.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Danger Zone',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Operations in this section are highly destructive and permanently wipe database entries. Action confirmation is mandatory.',
                    style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!_college.verified && !_college.suspended) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _verifyCollege,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Verify'),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (!_college.suspended) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _suspendCollege,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Suspend'),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _unsuspendCollege,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Unsuspend'),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _wipeCollegeData,
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: isDark ? Colors.white60 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey.shade400,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    DateTime? time,
    String? subtitle,
    required Color color,
  }) {
    final timeStr = time != null
        ? '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : 'N/A';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: const TextStyle(color: Colors.grey, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
