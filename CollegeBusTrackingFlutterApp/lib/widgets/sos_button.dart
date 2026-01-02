import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/services/data_service.dart';
import 'package:collegebus/utils/constants.dart';

class SOSButton extends StatelessWidget {
  final LatLng? currentLocation;
  final String? busId;
  final String? routeId;

  const SOSButton({
    Key? key,
    required this.currentLocation,
    this.busId,
    this.routeId,
  }) : super(key: key);

  Future<void> _handleSOS(BuildContext context) async {
    if (currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send SOS: Location unknown')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('EMERGENCY SOS'),
        content: const Text(
          'Are you sure you want to send an SOS alert to all coordinators? This will share your current location immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SEND SOS'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;

      try {
        final dataService = Provider.of<DataService>(context, listen: false);
        await dataService.sendSOS(
          busId: busId,
          routeId: routeId,
          lat: currentLocation!.latitude,
          lng: currentLocation!.longitude,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('SOS Alert Sent! Coordinators notified.'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send SOS: $e'),
              backgroundColor: Colors.black,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.large(
      onPressed: () => _handleSOS(context),
      backgroundColor: AppColors.error,
      foregroundColor: Colors.white,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sos_rounded, size: 32),
          Text(
            'SOS',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
