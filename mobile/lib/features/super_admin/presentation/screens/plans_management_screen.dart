import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collegebus/features/payment/services/subscription_plans_provider.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';


class PlansManagementScreen extends ConsumerStatefulWidget {
  const PlansManagementScreen({super.key});

  @override
  ConsumerState<PlansManagementScreen> createState() => _PlansManagementScreenState();
}

class _PlansManagementScreenState extends ConsumerState<PlansManagementScreen> {
  
  Future<void> _togglePlanActiveStatus(Map<String, dynamic> plan, bool isActive) async {
    try {
      await ref.read(subscriptionPlansProvider.notifier).togglePlanActiveStatus(plan, isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan "${plan['name']}" is now ${isActive ? 'active' : 'inactive'}.'),
            backgroundColor: isActive ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(
          context: context,
          error: 'Failed to update plan status: $e',
        );
      }
    }
  }

  Future<void> _deletePlan(Map<String, dynamic> plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Subscription Plan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Are you sure you want to permanently delete plan "${plan['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(subscriptionPlansProvider.notifier).deletePlan(plan['_id']);
        if (mounted) {
          SuccessModal.show(
            context: context,
            title: 'Plan Deleted',
            message: 'Subscription plan "${plan['name']}" was deleted successfully.',
            primaryActionText: 'OK',
          );
        }
      } catch (e) {
        if (mounted) {
          ApiErrorModal.show(
            context: context,
            error: 'Failed to delete plan: $e',
          );
        }
      }
    }
  }

  void _showAddEditPlanDialog([Map<String, dynamic>? plan]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddEditPlanDialog(
        plan: plan,
        onSave: () {
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Subscription Plans', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(subscriptionPlansProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(subscriptionPlansProvider.notifier).refresh(),
        child: _buildBody(isDark, plansAsync),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditPlanDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Plan'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody(bool isDark, AsyncValue<List<dynamic>> plansAsync) {
    return plansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text('Failed to Load Plans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(subscriptionPlansProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              )
            ],
          ),
        ),
      ),
      data: (plans) {
        if (plans.isEmpty) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_membership_outlined, color: isDark ? Colors.white24 : Colors.grey.shade300, size: 80),
                  const SizedBox(height: 16),
                  const Text('No Subscription Plans Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Create subscription plans to offer services to students.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditPlanDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Plan'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index] as Map<String, dynamic>;
            final isActive = plan['isActive'] as bool? ?? false;
            final isBestValue = plan['isBestValue'] as bool? ?? false;
            final originalPrice = plan['originalPrice'];
            final features = plan['features'] as List<dynamic>? ?? [];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                ),
              ),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Gradient Strip
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isBestValue
                            ? [Colors.amber.shade700, Colors.orange.shade500]
                            : [Colors.deepPurple.shade700, Colors.purple.shade400],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan['name'] ?? 'Unnamed Plan',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'alias: ${plan['alias'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                if (isBestValue) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                    ),
                                    child: const Text(
                                      'BEST VALUE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Switch.adaptive(
                                  value: isActive,
                                  activeColor: Colors.green,
                                  onChanged: (val) => _togglePlanActiveStatus(plan, val),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Colors.white10),

                        // Price & Duration
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PRICE',
                                  style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '₹${plan['price'] ?? 0}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    if (originalPrice != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '₹$originalPrice',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'DURATION',
                                  style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${plan['durationDays'] ?? 0} Days',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Colors.white10),

                        // Features List
                        const Text(
                          'FEATURES',
                          style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (features.isEmpty)
                          const Text('No features listed', style: TextStyle(color: Colors.grey, fontSize: 12))
                        else
                          ...features.map((feat) => Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        feat.toString(),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        const SizedBox(height: 16),

                        // Action Buttons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _deletePlan(plan),
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditPlanDialog(plan),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit Plan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AddEditPlanDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? plan;
  final VoidCallback onSave;

  const _AddEditPlanDialog({
    this.plan,
    required this.onSave,
  });

  @override
  ConsumerState<_AddEditPlanDialog> createState() => _AddEditPlanDialogState();
}

class _AddEditPlanDialogState extends ConsumerState<_AddEditPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _aliasController;
  late TextEditingController _priceController;
  late TextEditingController _originalPriceController;
  late TextEditingController _durationController;
  late TextEditingController _featureController;

  List<String> _features = [];
  bool _isActive = true;
  bool _isBestValue = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _nameController = TextEditingController(text: p?['name']?.toString() ?? '');
    _aliasController = TextEditingController(text: p?['alias']?.toString() ?? '');
    _priceController = TextEditingController(text: p?['price']?.toString() ?? '');
    _originalPriceController = TextEditingController(text: p?['originalPrice']?.toString() ?? '');
    _durationController = TextEditingController(text: p?['durationDays']?.toString() ?? '');
    _featureController = TextEditingController();

    if (p != null) {
      _features = List<String>.from((p['features'] as List<dynamic>? ?? []).map((f) => f.toString()));
      _isActive = p['isActive'] as bool? ?? true;
      _isBestValue = p['isBestValue'] as bool? ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aliasController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _durationController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  void _addFeature() {
    final text = _featureController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _features.add(text);
        _featureController.clear();
      });
    }
  }

  void _removeFeature(int index) {
    setState(() {
      _features.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'name': _nameController.text.trim(),
      'alias': _aliasController.text.trim().toLowerCase(),
      'price': num.parse(_priceController.text.trim()),
      'durationDays': int.parse(_durationController.text.trim()),
      'features': _features,
      'isActive': _isActive,
      'isBestValue': _isBestValue,
      'originalPrice': _originalPriceController.text.trim().isNotEmpty
          ? num.parse(_originalPriceController.text.trim())
          : null,
    };

    try {
      if (widget.plan != null) {
        await ref.read(subscriptionPlansProvider.notifier).updatePlan(widget.plan!['_id'], data);
      } else {
        await ref.read(subscriptionPlansProvider.notifier).createPlan(data);
      }
      widget.onSave();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ApiErrorModal.show(
          context: context,
          error: 'Failed to save plan: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.plan != null;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Plan' : 'Create New Plan',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Plan Name',
                          hintText: 'e.g., Premium Monthly',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Plan name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Alias (Unique)
                      TextFormField(
                        controller: _aliasController,
                        decoration: InputDecoration(
                          labelText: 'Plan Alias (Unique ID)',
                          hintText: 'e.g., premium_30',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Plan alias is required';
                          if (RegExp(r'[^a-zA-Z0-9_-]').hasMatch(val)) {
                            return 'Only letters, numbers, hyphens and underscores allowed';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Price and Original Price Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Price (₹)',
                                hintText: 'e.g., 200',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                if (num.tryParse(val.trim()) == null) return 'Must be a number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _originalPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Original Price (₹) [Opt]',
                                hintText: 'e.g., 250',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty) {
                                  if (num.tryParse(val.trim()) == null) return 'Must be a number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Duration in Days
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Duration in Days',
                          hintText: 'e.g., 30 or 365',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          if (int.tryParse(val.trim()) == null) return 'Must be an integer';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Toggles
                      SwitchListTile.adaptive(
                        value: _isActive,
                        title: const Text('Is Plan Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Inactive plans are hidden from students', style: TextStyle(fontSize: 11)),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                      SwitchListTile.adaptive(
                        value: _isBestValue,
                        title: const Text('Highlight as Best Value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Adds a visible badge to attract students', style: TextStyle(fontSize: 11)),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _isBestValue = val),
                      ),
                      const SizedBox(height: 24),

                      // Features Header
                      const Text(
                        'Edit Features List',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      // Features List View
                      if (_features.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Text('No features added yet.', style: TextStyle(color: Colors.grey, fontSize: 12))),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _features.length,
                          itemBuilder: (context, idx) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, size: 6, color: Colors.deepPurple),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_features[idx])),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                                    onPressed: () => _removeFeature(idx),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 8),

                      // Add Feature Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _featureController,
                              decoration: InputDecoration(
                                labelText: 'Add Feature',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.deepPurple, size: 32),
                            onPressed: _addFeature,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            const Divider(height: 1, color: Colors.white10),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEdit ? 'Save Changes' : 'Create Plan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
