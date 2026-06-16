import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collegebus/features/super_admin/application/super_admin_provider.dart';
import 'package:collegebus/features/college/domain/college_model.dart';

import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';

enum CollegeStatusFilter { all, pending, verified, suspended }

class CollegesTab extends ConsumerStatefulWidget {
  const CollegesTab({super.key});

  @override
  ConsumerState<CollegesTab> createState() => _CollegesTabState();
}

class _CollegesTabState extends ConsumerState<CollegesTab> {
  String _searchQuery = '';
  CollegeStatusFilter _statusFilter = CollegeStatusFilter.all;

  // Handles college verification
  Future<void> _verifyCollege(BuildContext context, CollegeModel college) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verify College', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to verify ${college.name}?'),
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
        await saNotifier.verifyCollege(college.id);
        if (context.mounted) {
          SuccessModal.show(
            context: context,
            title: 'College Verified',
            message: '${college.name} verified successfully',
            primaryActionText: 'OK',
          );
        }
      } catch (e) {
        if (context.mounted) {
          ApiErrorModal.show(
            context: context,
            error: 'Failed to verify college: $e',
          );
        }
      }
    }
  }

  // Handles college suspension
  Future<void> _suspendCollege(BuildContext context, CollegeModel college) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Suspend ${college.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Suspension Reason',
              hintText: 'e.g. Terms violation, unpaid invoice',
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
        await saNotifier.suspendCollege(college.id, reason);
        if (context.mounted) {
          SuccessModal.show(
            context: context,
            title: 'College Suspended',
            message: '${college.name} has been suspended.',
            primaryActionText: 'OK',
          );
        }
      } catch (e) {
        if (context.mounted) {
          ApiErrorModal.show(
            context: context,
            error: 'Failed to suspend college: $e',
          );
        }
      }
    }
  }

  // Handles college unsuspension
  Future<void> _unsuspendCollege(BuildContext context, CollegeModel college) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unsuspend College', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to unsuspend ${college.name}?'),
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
        await saNotifier.unsuspendCollege(college.id);
        if (context.mounted) {
          SuccessModal.show(
            context: context,
            title: 'College Unsuspended',
            message: '${college.name} is now active.',
            primaryActionText: 'OK',
          );
        }
      } catch (e) {
        if (context.mounted) {
          ApiErrorModal.show(
            context: context,
            error: 'Failed to unsuspend college: $e',
          );
        }
      }
    }
  }

  // Handles toggle manual premium override
  Future<void> _toggleManualPremium(BuildContext context, CollegeModel college, bool allow) async {
    try {
      final saNotifier = ref.read(superAdminServiceProvider.notifier);
      await saNotifier.toggleManualPremium(college.id, allow);
    } catch (e) {
      if (context.mounted) {
        ApiErrorModal.show(
          context: context,
          error: 'Failed to toggle premium override: $e',
        );
      }
    }
  }

  // Handles individual college wipe/delete
  Future<void> _wipeCollegeData(BuildContext context, CollegeModel college) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final typedName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('DANGER: Wipe College Data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will permanently wipe all data (Buses, Users, Trips, SOS) for ${college.name}.\n\nPlease type "${college.name}" to confirm:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Type college name here',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val != college.name) {
                    return 'College name does not match';
                  }
                  return null;
                },
              ),
            ],
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
                Navigator.pop(ctx, nameController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Wipe Data'),
          ),
        ],
      ),
    );

    if (typedName == college.name) {
      if (!context.mounted) return;
      final deleteRecord = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete College Record?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Do you also want to delete the college record itself? (Cancel = Wipe operational data only, keeping the college registration)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Wipe Only', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Wipe & Delete Record'),
            ),
          ],
        ),
      );

      if (deleteRecord != null) {
        try {
          final saNotifier = ref.read(superAdminServiceProvider.notifier);
          await saNotifier.wipeCollegeData(college.id, deleteRecord);
          if (context.mounted) {
            SuccessModal.show(
              context: context,
              title: 'Operational Wipe Complete',
              message: deleteRecord
                  ? 'College and all associated records deleted.'
                  : 'College data wiped. Registration kept.',
              primaryActionText: 'OK',
            );
          }
        } catch (e) {
          if (context.mounted) {
            ApiErrorModal.show(
              context: context,
              error: 'Wipe failed: $e',
            );
          }
        }
      }
    }
  }

  // Handles system wipe all colleges data
  Future<void> _wipeAllColleges(BuildContext context) async {
    final typeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final typedConfirm = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('CRITICAL: WIPE ALL DATA', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WARNING: This will permanently wipe all operational records for ALL colleges in the system. This action is irreversible.\n\nPlease type "ALL COLLEGES" to verify:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: typeController,
                decoration: const InputDecoration(
                  hintText: 'Type ALL COLLEGES',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val != 'ALL COLLEGES') {
                    return 'Confirmation text does not match';
                  }
                  return null;
                },
              ),
            ],
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
                Navigator.pop(ctx, typeController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Wipe All'),
          ),
        ],
      ),
    );

    if (typedConfirm == 'ALL COLLEGES') {
      try {
        final saNotifier = ref.read(superAdminServiceProvider.notifier);
        await saNotifier.wipeCollegeData('all', false);
        if (context.mounted) {
          SuccessModal.show(
            context: context,
            title: 'System Cleaned',
            message: 'All college datasets wiped successfully.',
            primaryActionText: 'OK',
          );
        }
      } catch (e) {
        if (context.mounted) {
          ApiErrorModal.show(
            context: context,
            error: 'Failed to wipe system data: $e',
          );
        }
      }
    }
  }

  // Opens modal to add college
  Future<void> _showAddCollegeDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final domainsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Create New College', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'College Name',
                  hintText: 'e.g. Stanford University',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'College name is required';
                  if (val.trim().length < 3) return 'Must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: domainsController,
                decoration: const InputDecoration(
                  labelText: 'Allowed Domains',
                  hintText: 'e.g. stanford.edu, stanford.ac.in',
                  helperText: 'Comma separated list of domains',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Domains are required';
                  return null;
                },
              ),
            ],
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
                final domains = domainsController.text
                    .split(',')
                    .map((d) => d.trim())
                    .where((d) => d.isNotEmpty)
                    .toList();
                Navigator.pop(ctx, {
                  'name': nameController.text.trim(),
                  'domains': domains,
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (data != null) {
      try {
        final saNotifier = ref.read(superAdminServiceProvider.notifier);
        await saNotifier.createCollege(data['name'], List<String>.from(data['domains']));
        if (context.mounted) {
          SuccessModal.show(
            context: context,
            title: 'College Created',
            message: 'College registration complete.',
            primaryActionText: 'OK',
          );
        }
      } catch (e) {
        if (context.mounted) {
          ApiErrorModal.show(
            context: context,
            error: 'Failed to create college: $e',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(superAdminServiceProvider);
    final allColleges = asyncState.valueOrNull?.colleges ?? [];

    final filteredColleges = allColleges.where((college) {
      // Filter status
      switch (_statusFilter) {
        case CollegeStatusFilter.pending:
          if (college.verified || college.suspended) return false;
          break;
        case CollegeStatusFilter.verified:
          if (!college.verified || college.suspended) return false;
          break;
        case CollegeStatusFilter.suspended:
          if (!college.suspended) return false;
          break;
        case CollegeStatusFilter.all:
          break;
      }

      // Filter search
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = college.name.toLowerCase().contains(query);
        final matchesDomain = college.allowedDomains.any((d) => d.toLowerCase().contains(query));
        return matchesName || matchesDomain;
      }

      return true;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCollegeDialog(context),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter card
          Container(
            margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, const Color(0xFFF8FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search field
                TextField(
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search colleges by name or domain...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 13),
                    prefixIcon: Icon(Icons.search, size: 20, color: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.deepPurple.withValues(alpha: 0.5)),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),
                // Chips & Action button
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', CollegeStatusFilter.all),
                            const SizedBox(width: 8.0),
                            _buildFilterChip('Pending', CollegeStatusFilter.pending),
                            const SizedBox(width: 8.0),
                            _buildFilterChip('Verified', CollegeStatusFilter.verified),
                            const SizedBox(width: 8.0),
                            _buildFilterChip('Suspended', CollegeStatusFilter.suspended),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Wipe All Data button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _wipeAllColleges(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Colleges list
          Expanded(
            child: filteredColleges.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No colleges found',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try adjusting your search filters',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredColleges.length,
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 80),
                    itemBuilder: (context, index) {
                      final college = filteredColleges[index];
                      return _CollegeCard(
                        college: college,
                        onVerify: () => _verifyCollege(context, college),
                        onSuspend: () => _suspendCollege(context, college),
                        onUnsuspend: () => _unsuspendCollege(context, college),
                        onWipe: () => _wipeCollegeData(context, college),
                        onTogglePremium: (allow) => _toggleManualPremium(context, college, allow),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, CollegeStatusFilter filter) {
    final isSelected = _statusFilter == filter;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color activeBgColor = Colors.deepPurple;
    Color activeTextColor = Colors.white;
    Color inactiveBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    Color inactiveTextColor = isDark ? Colors.white70 : Colors.black87;
    Color borderColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05);

    if (isSelected) {
      switch (filter) {
        case CollegeStatusFilter.all:
          activeBgColor = Colors.deepPurple;
          break;
        case CollegeStatusFilter.pending:
          activeBgColor = Colors.orange.shade700;
          break;
        case CollegeStatusFilter.verified:
          activeBgColor = Colors.green.shade700;
          break;
        case CollegeStatusFilter.suspended:
          activeBgColor = Colors.red.shade700;
          break;
      }
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _statusFilter = filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : inactiveBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : borderColor,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBgColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeTextColor : inactiveTextColor,
          ),
        ),
      ),
    );
  }
}

class _CollegeCard extends StatefulWidget {
  final CollegeModel college;
  final VoidCallback onVerify;
  final VoidCallback onSuspend;
  final VoidCallback onUnsuspend;
  final VoidCallback onWipe;
  final Function(bool) onTogglePremium;

  const _CollegeCard({
    required this.college,
    required this.onVerify,
    required this.onSuspend,
    required this.onUnsuspend,
    required this.onWipe,
    required this.onTogglePremium,
  });

  @override
  State<_CollegeCard> createState() => _CollegeCardState();
}

class _CollegeCardState extends State<_CollegeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _scale = 1.0;
  bool _showTimeline = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.02,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1.0 - _controller.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final college = widget.college;

    // Status derivation
    Color statusColor;
    String statusText;
    if (college.suspended) {
      statusColor = Colors.red;
      statusText = 'Suspended';
    } else if (college.verified) {
      statusColor = Colors.green;
      statusText = 'Verified';
    } else {
      statusColor = Colors.orange;
      statusText = 'Pending';
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/super-admin/colleges/${college.id}', extra: college);
      },
      child: Transform.scale(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Left Accent Stripe
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 5.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Avatar, Name & Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'college-icon-${college.id}',
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.school_rounded, color: Colors.blue, size: 26),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Hero(
                                tag: 'college-name-${college.id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    college.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: -0.2,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                college.allowedDomains.join(', '),
                                style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Pill
                        Hero(
                          tag: 'college-status-${college.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    college.suspended
                                        ? Icons.warning_amber_rounded
                                        : college.verified
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.hourglass_empty_rounded,
                                    color: statusColor,
                                    size: 11,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100),
                    const SizedBox(height: 14),

                    // Detail Rows: Address & Admin
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            college.address ?? 'Not Configured',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: college.address != null ? FontWeight.w500 : FontWeight.w400,
                              fontStyle: college.address != null ? FontStyle.normal : FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 16,
                          color: isDark ? Colors.orange.shade300 : Colors.orange.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            college.adminName ?? 'Pending Setup',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: college.adminName != null ? FontWeight.w500 : FontWeight.w400,
                              fontStyle: college.adminName != null ? FontStyle.normal : FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Switch Row: Manual Premium
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: college.allowManualPremium
                            ? (isDark ? Colors.amber.withValues(alpha: 0.06) : Colors.amber.withValues(alpha: 0.04))
                            : (isDark ? Colors.grey.shade900.withValues(alpha: 0.4) : Colors.grey.shade50),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: college.allowManualPremium
                              ? Colors.amber.withValues(alpha: 0.3)
                              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: college.allowManualPremium ? Colors.amber : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Manual Premium Override',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: college.allowManualPremium
                                      ? (isDark ? Colors.amber.shade200 : Colors.amber.shade800)
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 30,
                            child: Switch.adaptive(
                              value: college.allowManualPremium,
                              activeThumbColor: Colors.amber.shade600,
                              activeTrackColor: Colors.amber.withValues(alpha: 0.4),
                              onChanged: (val) {
                                HapticFeedback.selectionClick();
                                widget.onTogglePremium(val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showTimeline = !_showTimeline);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.history_toggle_off_rounded, color: isDark ? Colors.blue.shade300 : Colors.blue.shade600, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _showTimeline ? 'Hide Audit Timeline' : 'View Audit Timeline',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showTimeline) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTimelineItem(
                              title: 'Registered',
                              time: college.createdAt,
                              color: Colors.blue,
                              icon: Icons.app_registration_rounded,
                            ),
                            if (college.verified) ...[
                              const SizedBox(height: 12),
                              _buildTimelineItem(
                                title: 'Verified',
                                time: college.verifiedAt,
                                subtitle: college.verifiedAt == null ? 'Autoverified / Pre-configured' : null,
                                color: Colors.green,
                                icon: Icons.verified_user_rounded,
                              ),
                            ],
                            if (college.suspended) ...[
                              const SizedBox(height: 12),
                              _buildTimelineItem(
                                title: 'Suspended',
                                time: college.suspendedAt,
                                subtitle: college.suspensionReason != null ? 'Reason: "${college.suspensionReason}"' : null,
                                color: Colors.red,
                                icon: Icons.gavel_rounded,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Bottom Actions Row: Verify / Suspend, and Wipe
                    Row(
                      children: [
                        if (!college.verified && !college.suspended) ...[
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  widget.onVerify();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                label: const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (!college.suspended) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                widget.onSuspend();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade600,
                                side: BorderSide(color: Colors.red.shade500.withValues(alpha: 0.35), width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.block_flipped, size: 16),
                              label: const Text('Suspend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  widget.onUnsuspend();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                label: const Text('Unsuspend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        // Wipe icon button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onWipe();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    DateTime? time,
    String? subtitle,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = time != null
        ? '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : 'N/A';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(
                icon,
                color: color,
                size: 12,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                timeStr,
                style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
