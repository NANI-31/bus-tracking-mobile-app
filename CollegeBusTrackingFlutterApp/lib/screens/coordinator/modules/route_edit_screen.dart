import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/models/route_model.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;

class RouteEditScreen extends StatefulWidget {
  final RouteModel? route; // null for create, non-null for edit

  const RouteEditScreen({super.key, this.route});

  @override
  State<RouteEditScreen> createState() => _RouteEditScreenState();
}

class _RouteEditScreenState extends State<RouteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late String _selectedType;
  late List<TextEditingController> _stopControllers;
  bool _isLoading = false;

  bool get isEditing => widget.route != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.route?.routeName ?? '',
    );
    _startController = TextEditingController(
      text: widget.route?.startPoint.name ?? '',
    );
    _endController = TextEditingController(
      text: widget.route?.endPoint.name ?? '',
    );
    _selectedType = widget.route?.routeType ?? 'pickup';
    _stopControllers = (widget.route?.stopPoints ?? [])
        .map((s) => TextEditingController(text: s.name))
        .toList();
    if (_stopControllers.isEmpty) {
      _stopControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    for (var c in _stopControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    setState(() {
      _stopControllers.add(TextEditingController());
    });
  }

  void _removeStop(int index) {
    if (_stopControllers.length > 1) {
      setState(() {
        _stopControllers[index].dispose();
        _stopControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startController.text.trim().isEmpty ||
        _endController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start and End points are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<DataService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final collegeId = authService.currentUserModel?.collegeId;

      if (collegeId == null) {
        throw Exception('College ID not found');
      }

      final stops = _stopControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (isEditing) {
        // Update existing route
        await firestoreService.updateRoute(widget.route!.id, {
          'routeName': _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : '${_startController.text.trim()} - ${_endController.text.trim()}',
          'routeType': _selectedType,
          'startPoint': {
            'name': _startController.text.trim(),
            'location': {
              'lat': widget.route!.startPoint.lat,
              'lng': widget.route!.startPoint.lng,
            },
          },
          'endPoint': {
            'name': _endController.text.trim(),
            'location': {
              'lat': widget.route!.endPoint.lat,
              'lng': widget.route!.endPoint.lng,
            },
          },
          'stopPoints': stops.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            // Preserve existing lat/lng if available
            final existingPoint = idx < (widget.route?.stopPoints.length ?? 0)
                ? widget.route!.stopPoints[idx]
                : null;
            return {
              'name': s,
              'location': {
                'lat': existingPoint?.lat ?? 0,
                'lng': existingPoint?.lng ?? 0,
              },
            };
          }).toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Create new route
        final newRoute = RouteModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          routeName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : '${_startController.text.trim()} - ${_endController.text.trim()}',
          routeType: _selectedType,
          startPoint: RoutePoint(
            name: _startController.text.trim(),
            lat: 0,
            lng: 0,
          ),
          endPoint: RoutePoint(
            name: _endController.text.trim(),
            lat: 0,
            lng: 0,
          ),
          stopPoints: stops
              .map((s) => RoutePoint(name: s, lat: 0, lng: 0))
              .toList(),
          collegeId: collegeId,
          createdBy: authService.currentUserModel?.id ?? '',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: null,
        );
        await firestoreService.createRoute(newRoute);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Route updated successfully'
                : 'Route created successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editRoute : l10n.createRoute),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: l10n.save,
              onPressed: _saveRoute,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: VStack([
            // Route Name
            _buildSectionTitle('Route Information'),
            8.heightBox,
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.routeName,
                hintText: 'Leave empty to auto-generate',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.route),
              ),
            ),
            16.heightBox,

            // Route Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: l10n.routeType,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: [
                DropdownMenuItem(value: 'pickup', child: Text(l10n.pickup)),
                DropdownMenuItem(value: 'drop', child: Text(l10n.drop)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            24.heightBox,

            // Start Point
            _buildSectionTitle(l10n.startPoint),
            8.heightBox,
            TextFormField(
              controller: _startController,
              decoration: InputDecoration(
                labelText: l10n.startPoint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.play_arrow, color: Colors.green),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            24.heightBox,

            // Stop Points
            _buildSectionTitle('${l10n.stopPoint}s'),
            8.heightBox,
            ..._stopControllers.asMap().entries.map((entry) {
              final idx = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: '${l10n.stopPoint} ${idx + 1}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle,
                        color: _stopControllers.length > 1
                            ? Colors.red
                            : Colors.grey,
                      ),
                      onPressed: _stopControllers.length > 1
                          ? () => _removeStop(idx)
                          : null,
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              icon: const Icon(Icons.add_circle),
              label: Text(l10n.addStop),
              onPressed: _addStop,
            ),
            24.heightBox,

            // End Point
            _buildSectionTitle(l10n.endPoint),
            8.heightBox,
            TextFormField(
              controller: _endController,
              decoration: InputDecoration(
                labelText: l10n.endPoint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.stop, color: Colors.red),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            32.heightBox,

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveRoute,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(isEditing ? l10n.save : l10n.create),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        8.widthBox,
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
