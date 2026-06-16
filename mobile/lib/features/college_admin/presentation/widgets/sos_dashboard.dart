import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/features/sos/domain/sos_model.dart';
import 'package:collegebus/features/college_admin/application/college_admin_provider.dart';
import 'package:collegebus/core/utils/map_marker_helper.dart';
import 'package:intl/intl.dart';
import 'package:collegebus/core/providers/service_providers.dart';

class SosDashboard extends ConsumerStatefulWidget {
  const SosDashboard({super.key});

  @override
  ConsumerState<SosDashboard> createState() => _SosDashboardState();
}

class _SosDashboardState extends ConsumerState<SosDashboard> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  SosModel? _selectedSos;
  final _notesController = TextEditingController();
  BitmapDescriptor? _busIcon;

  @override
  void initState() {
    super.initState();
    _loadMarker();
  }

  Future<void> _loadMarker() async {
    final icon = await MapMarkerHelper.createBusMarker();
    if (mounted) {
      setState(() {
        _busIcon = icon;
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.emergency), text: 'Active Alerts'),
              Tab(icon: Icon(Icons.history), text: 'Incident Logs'),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildActiveTab(context, ref),
                _buildLogsTab(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTab(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(collegeAdminServiceProvider);
    final activeSos = asyncState.valueOrNull?.activeSos ?? [];
    final mapStyle = ref.watch(mapStyleProvider).value;
    _updateMarkers(activeSos);

    return Column(
      children: [
        // Map Section
        SizedBox(
          height: 250,
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(17.3850, 78.4867),
              zoom: 12,
            ),
            markers: _markers,
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            mapToolbarEnabled: true,
            style: mapStyle,
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8.0),
              Text(
                'Active Alerts (${activeSos.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  final notifier = ref.read(collegeAdminServiceProvider.notifier);
                  final collegeId = ref.read(collegeAdminServiceProvider).valueOrNull?.college?.id ?? '';
                  if (collegeId.isNotEmpty) {
                    notifier.fetchActiveSos(collegeId);
                  }
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),

        // List Section
        Expanded(
          child: activeSos.isEmpty
              ? _buildEmptyState(
                  'System Secure',
                  'No active emergency alerts',
                  Icons.check_circle_outline,
                  Colors.green,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: activeSos.length,
                  itemBuilder: (context, index) {
                    final sos = activeSos[index];
                    return _buildSosCard(context, ref, sos);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLogsTab(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(collegeAdminServiceProvider);
    final logs = asyncState.valueOrNull?.sosLogs ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.assignment, color: Colors.blue),
              const SizedBox(width: 8.0),
              Text(
                'Incident Archives (${logs.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  final notifier = ref.read(collegeAdminServiceProvider.notifier);
                  final collegeId = ref.read(collegeAdminServiceProvider).valueOrNull?.college?.id ?? '';
                  if (collegeId.isNotEmpty) {
                    notifier.fetchSosLogs(collegeId);
                  }
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? _buildEmptyState(
                  'No Logs',
                  'Resolved incidents will appear here',
                  Icons.history,
                  Colors.blue,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final sos = logs[index];
                    return _buildLogCard(sos);
                  },
                ),
        ),
      ],
    );
  }

  void _updateMarkers(List<SosModel> activeSos) {
    final Map<String, Marker> newMarkers = {};
    for (var sos in activeSos) {
      newMarkers[sos.sosId] = Marker(
        markerId: MarkerId(sos.sosId),
        position: LatLng(sos.latitude, sos.longitude),
        icon:
            _busIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Bus ${sos.busNumber}',
          snippet: 'Type: ${sos.userRole}',
        ),
        onTap: () => setState(() => _selectedSos = sos),
      );
    }

    // Using a microtask to avoid building during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _markers = newMarkers.values.toSet();
        });
      }
    });
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSosCard(BuildContext context, WidgetRef ref, SosModel sos) {
    final bool isSelected = _selectedSos?.sosId == sos.sosId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Colors.red.shade300, width: 2.0)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() => _selectedSos = sos);
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(sos.latitude, sos.longitude),
                  15,
                ),
              );
            },
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.emergency, color: Colors.white),
            ),
            title: Text(
              'Bus ${sos.busNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${sos.userRole.toUpperCase()} • ${DateFormat('HH:mm:ss').format(sos.timestamp.toLocal())}',
            ),
            trailing: isSelected ? null : const Icon(Icons.chevron_right),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Location:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${sos.latitude.toStringAsFixed(4)}, ${sos.longitude.toStringAsFixed(4)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showResolveDialog(context, ref, sos),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Resolve Emergency'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogCard(SosModel sos) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.history, color: Colors.white),
        ),
        title: Text('Bus ${sos.busNumber} Incident'),
        subtitle: Text(
          'Resolved at ${DateFormat('MMM dd, HH:mm').format((sos.resolvedAt ?? sos.timestamp).toLocal())}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogDetail(
                  'Reported By',
                  '${sos.userRole} (${DateFormat('HH:mm:ss').format(sos.timestamp.toLocal())})',
                ),
                _buildLogDetail('Resolved By', sos.resolvedBy ?? 'System'),
                _buildLogDetail('Incident ID', sos.sosId),
                const Divider(),
                const Text(
                  'Documentation / Resolution Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  sos.resolutionNotes ?? 'No notes provided.',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context, WidgetRef ref, SosModel sos) {
    _notesController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolve Emergency?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Document the resolution for audit purposes.'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter resolution notes/documentation...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final notes = _notesController.text.trim();
              Navigator.pop(dialogContext);
              try {
                final notifier = ref.read(collegeAdminServiceProvider.notifier);
                await notifier.resolveSos(
                  sos.sosId,
                  notes: notes.isEmpty ? null : notes,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incident Logged and Resolved'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }
}
