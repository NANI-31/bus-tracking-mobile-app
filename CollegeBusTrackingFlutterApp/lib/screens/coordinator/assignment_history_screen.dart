import 'package:flutter/material.dart';
import 'package:collegebus/models/assignment_log_model.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:intl/intl.dart';

class AssignmentHistoryScreen extends StatefulWidget {
  final String busId;
  final String busNumber;

  const AssignmentHistoryScreen({
    super.key,
    required this.busId,
    required this.busNumber,
  });

  @override
  State<AssignmentHistoryScreen> createState() =>
      _AssignmentHistoryScreenState();
}

class _AssignmentHistoryScreenState extends State<AssignmentHistoryScreen> {
  List<AssignmentLogModel>? _logs;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final dataService = Provider.of<DataService>(context, listen: false);
      final logs = await dataService.getAssignmentLogsByBus(widget.busId);
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: 'Assignment History - ${widget.busNumber}'.text.make(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const CircularProgressIndicator().centered();
    if (_error != null)
      return _error!.text.color(AppColors.error).make().centered();
    if (_logs == null || _logs!.isEmpty) {
      return 'No assignment history found for this bus'.text.gray500
          .make()
          .centered();
    }

    return ListView.builder(
      itemCount: _logs!.length,
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemBuilder: (context, index) {
        final log = _logs![index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: VStack([
            HStack([
              _getStatusBadge(log.status),
              const Spacer(),
              DateFormat(
                'MMM dd, yyyy',
              ).format(log.assignedAt).text.size(12).gray500.make(),
            ]).pOnly(bottom: 8),

            HStack([
              const Icon(
                Icons.person,
                size: 16,
                color: Colors.blueGrey,
              ).pOnly(right: 8),
              'Driver: '.text.bold.make(),
              (log.driverName ?? 'Unknown Driver').text.make(),
            ]),

            if (log.routeName != null)
              HStack([
                const Icon(
                  Icons.route,
                  size: 16,
                  color: Colors.blueGrey,
                ).pOnly(right: 8),
                'Route: '.text.bold.make(),
                log.routeName!.text.make(),
              ]).pOnly(top: 4),

            const Divider().pSymmetric(v: 8),

            VStack([
              _buildTimeRow('Assigned', log.assignedAt),
              if (log.acceptedAt != null)
                _buildTimeRow('Accepted', log.acceptedAt!),
              if (log.completedAt != null)
                _buildTimeRow(
                  log.status == 'rejected' ? 'Rejected' : 'Completed',
                  log.completedAt!,
                ),
            ]),
          ]).p(16),
        );
      },
    );
  }

  Widget _buildTimeRow(String label, DateTime time) {
    return HStack([
      label.text.size(12).gray600.make(),
      const Spacer(),
      DateFormat('hh:mm a').format(time).text.size(12).bold.make(),
    ]);
  }

  Widget _getStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'accepted':
        color = AppColors.success;
        break;
      case 'pending':
        color = AppColors.warning;
        break;
      case 'rejected':
        color = AppColors.error;
        break;
      default:
        color = AppColors.primary;
    }

    return status
        .toUpperCase()
        .text
        .white
        .size(10)
        .bold
        .make()
        .pSymmetric(h: 8, v: 4)
        .box
        .color(color)
        .roundedSM
        .make();
  }
}
