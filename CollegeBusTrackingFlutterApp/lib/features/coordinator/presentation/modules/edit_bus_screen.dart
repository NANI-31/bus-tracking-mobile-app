import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/core/providers/api_provider.dart';
import 'package:collegebus/shared/widgets/success_modal.dart';
import 'package:collegebus/shared/widgets/api_error_modal.dart';

class EditBusScreen extends ConsumerStatefulWidget {
  final String busNumber;
  final BusModel? bus;

  const EditBusScreen({super.key, required this.busNumber, this.bus});

  @override
  ConsumerState<EditBusScreen> createState() => _EditBusScreenState();
}

class _EditBusScreenState extends ConsumerState<EditBusScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _busNumberController;
  String? _selectedDefaultRouteId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _busNumberController = TextEditingController(text: widget.busNumber);
    _selectedDefaultRouteId = widget.bus?.defaultRouteId;
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final authState = ref.read(authProvider).value;
      final collegeId = authState?.currentUser?.collegeId;
      if (collegeId == null) throw 'College context missing';

      final newBusNumber = _busNumberController.text.trim();

      // Use unified updateBusDetails
      await api.updateBusDetails(
        collegeId,
        widget.busNumber,
        newBusNumber: newBusNumber != widget.busNumber ? newBusNumber : null,
        defaultRouteId: _selectedDefaultRouteId != widget.bus?.defaultRouteId
            ? _selectedDefaultRouteId
            : null,
      );

      if (mounted) {
        SuccessModal.show(
          context: context,
          title: 'Bus Updated',
          message: 'Bus details have been updated successfully.',
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).value;
    final collegeId = authState?.currentUser?.collegeId;

    // Watch routes reactive version
    final routesAsync = collegeId != null
        ? ref.watch(collegeRoutesProvider(collegeId))
        : const AsyncValue<List<RouteModel>>.data([]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Bus'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: 'Error: $err'.text.make()),
        data: (routes) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                'Bus Details'.text.bold.xl2.make(),
                const SizedBox(height: 8),
                'Modify the bus identifier and its default assigned route.'.text
                    .color(AppColors.textSecondary)
                    .make(),
                const SizedBox(height: 32),

                // Bus Number Field
                TextFormField(
                  controller: _busNumberController,
                  decoration: InputDecoration(
                    labelText: 'Bus Number / Name',
                    hintText: 'e.g. BUS-01',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.directions_bus_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a bus number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Default Route Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedDefaultRouteId,
                  decoration: InputDecoration(
                    labelText: 'Default Route',
                    hintText: 'Select a default route',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.route_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No Default Route'),
                    ),
                    ...routes.map((route) {
                      return DropdownMenuItem<String>(
                        value: route.id,
                        child: Text(route.displayName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDefaultRouteId = value;
                    });
                  },
                ),
                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
