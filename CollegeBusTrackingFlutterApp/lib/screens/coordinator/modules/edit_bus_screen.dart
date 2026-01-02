import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/bus_model.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/widgets/success_modal.dart';
import 'package:collegebus/widgets/api_error_modal.dart';

class EditBusScreen extends StatefulWidget {
  final String busNumber;
  final BusModel? bus;

  const EditBusScreen({super.key, required this.busNumber, this.bus});

  @override
  State<EditBusScreen> createState() => _EditBusScreenState();
}

class _EditBusScreenState extends State<EditBusScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _busNumberController;
  String? _selectedDefaultRouteId;
  List<RouteModel> _routes = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _busNumberController = TextEditingController(text: widget.busNumber);
    _selectedDefaultRouteId = widget.bus?.defaultRouteId;
    _loadRoutes();
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final dataService = context.read<DataService>();
      final collegeId = authService.currentUserModel?.collegeId;
      if (collegeId != null) {
        // We use the stream but convert it to future for simplicity here or use current data
        final routes = await dataService.getRoutesByCollege(collegeId).first;
        setState(() {
          _routes = routes;
        });
      }
    } catch (e) {
      debugPrint('Error loading routes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final dataService = context.read<DataService>();
      final authService = context.read<AuthService>();
      final collegeId = authService.currentUserModel?.collegeId;
      if (collegeId == null) throw 'College context missing';

      final newBusNumber = _busNumberController.text.trim();

      // Use unified updateBusDetails
      await dataService.updateBusDetails(
        collegeId: collegeId,
        oldBusNumber: widget.busNumber,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Bus'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    'Bus Details'.text.bold.xl2.make(),
                    const SizedBox(height: 8),
                    'Modify the bus identifier and its default assigned route.'
                        .text
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
                      value: _selectedDefaultRouteId,
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
                        ..._routes.map((route) {
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
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
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
    );
  }
}
