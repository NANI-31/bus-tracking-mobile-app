import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:collegebus/features/bus/domain/bus_model.dart';
import 'package:collegebus/features/user/domain/user_model.dart';
import 'package:collegebus/core/utils/app_logger.dart';

class ExportService {
  Future<void> exportBuses(List<BusModel> buses) async {
    final List<List<dynamic>> rows = [];
    // Header
    rows.add(['Bus Number', 'Driver ID', 'Route ID', 'Status', 'Created At']);

    // Data
    for (var bus in buses) {
      rows.add([
        bus.busNumber,
        bus.driverId.isEmpty ? 'Unassigned' : bus.driverId,
        bus.routeId ?? 'N/A',
        bus.assignmentStatus,
        bus.createdAt.toIso8601String(),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    await _saveAndShare(csvData, 'bus_report.csv');
  }

  Future<void> exportDrivers(List<UserModel> drivers) async {
    final List<List<dynamic>> rows = [];
    rows.add(['Name', 'Email', 'Phone', 'Approved', 'College ID']);

    for (var driver in drivers) {
      rows.add([
        driver.fullName,
        driver.email,
        driver.phoneNumber ?? 'N/A',
        driver.approved ? 'Yes' : 'No',
        driver.collegeId,
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    await _saveAndShare(csvData, 'driver_report.csv');
  }

  Future<void> _saveAndShare(String content, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Exported Report: $fileName',
        ),
      );
    } catch (e) {
      AppLogger.e('Error exporting file: $e');
      rethrow;
    }
  }
}





