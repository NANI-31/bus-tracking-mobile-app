import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';

class EditDriverScreen extends ConsumerStatefulWidget {
  final String driverId;
  final UserModel? driver;

  const EditDriverScreen({super.key, required this.driverId, this.driver});

  @override
  ConsumerState<EditDriverScreen> createState() => _EditDriverScreenState();
}

class _EditDriverScreenState extends ConsumerState<EditDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.driver?.fullName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateUser(widget.driverId, {
        'fullName': _nameController.text.trim(),
      });

      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'Driver Updated',
          message: 'Driver name has been updated successfully.',
          primaryActionText: 'OK',
          onPrimaryAction: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(context: context, error: e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text(
          'Are you sure you want to permanently delete ${widget.driver?.fullName ?? 'this driver'} from the database?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteUser(widget.driverId);

      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'Driver Deleted',
          message: 'The driver has been removed from the database.',
          primaryActionText: 'OK',
          onPrimaryAction: () {
            Navigator.pop(context); // Close success modal
            Navigator.pop(context); // Return to dashboard
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ApiErrorModal.show(context: context, error: e);
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Driver'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                icon: Icons.person_outline,
                title: 'Driver Identity',
                subtitle: 'Update the driver\'s basic information.',
              ),
              const SizedBox(height: 24),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    val!.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),

              // Email (Read-only)
              TextFormField(
                initialValue: driver?.email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Phone (Read-only)
              TextFormField(
                initialValue: driver?.phoneNumber,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving || _isDeleting ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Delete Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _isSaving || _isDeleting ? null : _handleDelete,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: _isDeleting
                      ? const CircularProgressIndicator()
                      : const Text('Delete Driver from Database'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title.text.bold.xl.make(),
              const SizedBox(height: 2),
              subtitle.text
                  .color(
                    Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  )
                  .sm
                  .make(),
            ],
          ),
        ),
      ],
    );
  }
}
