import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/models/incident_model.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/widgets/api_error_modal.dart';
import 'package:collegebus/widgets/success_modal.dart';

class IncidentReportModal extends StatefulWidget {
  final String? busId;
  final String? driverId;

  const IncidentReportModal({super.key, this.busId, this.driverId});

  static Future<void> show(
    BuildContext context, {
    String? busId,
    String? driverId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          IncidentReportModal(busId: busId, driverId: driverId),
    );
  }

  @override
  State<IncidentReportModal> createState() => _IncidentReportModalState();
}

class _IncidentReportModalState extends State<IncidentReportModal> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'other';
  String _selectedSeverity = 'medium';
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  final Map<String, String> _typeLabels = {
    'accident': 'Accident',
    'breakdown': 'Breakdown',
    'delay': 'Delay',
    'behavior': 'Driver Behavior',
    'other': 'Other',
  };

  final Map<String, String> _severityLabels = {
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
    'critical': 'Critical',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final dataService = Provider.of<DataService>(context, listen: false);
    final user = authService.currentUserModel;

    if (user == null) {
      if (mounted) {
        Navigator.pop(context);
        ApiErrorModal.show(context: context, error: "User not logged in");
      }
      return;
    }

    try {
      final incident = IncidentModel(
        collegeId: user.collegeId,
        reporterId: user.id,
        busId: widget.busId,
        driverId: widget.driverId,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        severity: _selectedSeverity,
      );

      await dataService.createIncident(incident);

      if (mounted) {
        Navigator.pop(context); // Close modal
        SuccessModal.show(
          context: context,
          title: 'Report Submitted',
          message: 'The incident has been reported successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ApiErrorModal.show(context: context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                'Report Incident'.text.xl2.bold.make(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            16.heightBox,

            // Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Incident Type',
                border: OutlineInputBorder(),
              ),
              items: _typeLabels.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            16.heightBox,

            // Severity Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSeverity,
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              items: _severityLabels.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (val) => setState(() => _selectedSeverity = val!),
            ),
            16.heightBox,

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (val) => val == null || val.isEmpty
                  ? 'Please enter a description'
                  : null,
            ),
            24.heightBox,

            // Submit Button
            if (_isLoading)
              const CircularProgressIndicator().centered()
            else
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: 'Submit Report'.text.white.bold.lg.make(),
              ),
            24.heightBox,
          ],
        ),
      ),
    );
  }
}
