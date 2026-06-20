import 'dart:ui' as ui;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color borderColor = isSelected
        ? (isDark ? const Color(0xFFF43F5E).withValues(alpha: 0.75) : const Color(0xFFF43F5E).withValues(alpha: 0.35))
        : (isDark ? const Color(0xFFF43F5E).withValues(alpha: 0.35) : const Color(0xFFF43F5E).withValues(alpha: 0.12));

    final double borderWidth = isSelected ? 2.0 : 1.5;

    final List<BoxShadow> shadows = isSelected
        ? [
            BoxShadow(
              color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF450A0A).withValues(alpha: 0.65),
                        const Color(0xFF7F1D1D).withValues(alpha: 0.65),
                      ]
                    : [
                        const Color(0xFFFFF1F2).withValues(alpha: 0.32),
                        const Color(0xFFFFE4E6).withValues(alpha: 0.24),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
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
                  leading: CircleAvatar(
                    backgroundColor: isDark ? Colors.red.shade900.withValues(alpha: 0.5) : Colors.red.shade100,
                    child: Icon(Icons.emergency_rounded, color: isDark ? Colors.red.shade200 : Colors.red.shade800),
                  ),
                  title: Text(
                    'Bus ${sos.busNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.red.shade900,
                    ),
                  ),
                  subtitle: Text(
                    '${sos.userRole.toUpperCase()} • ${DateFormat('HH:mm:ss').format(sos.timestamp.toLocal())}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.red.shade800.withValues(alpha: 0.8),
                    ),
                  ),
                  trailing: isSelected ? null : Icon(Icons.chevron_right_rounded, color: isDark ? Colors.red.shade300 : Colors.red.shade900),
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Location:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.red.shade900,
                              ),
                            ),
                            Text(
                              '${sos.latitude.toStringAsFixed(4)}, ${sos.longitude.toStringAsFixed(4)}',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showResolveDialog(context, ref, sos),
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text('Resolve Emergency'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(SosModel sos) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF450A0A).withValues(alpha: 0.45),
                        const Color(0xFF7F1D1D).withValues(alpha: 0.45),
                      ]
                    : [
                        const Color(0xFFFFF1F2).withValues(alpha: 0.24),
                        const Color(0xFFFFE4E6).withValues(alpha: 0.16),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFFF43F5E).withValues(alpha: 0.25)
                    : const Color(0xFFF43F5E).withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: ExpansionTile(
                key: PageStorageKey<String>('sos_incident_log_tile_${sos.sosId}'),
                leading: CircleAvatar(
                  backgroundColor: isDark ? Colors.red.shade900.withValues(alpha: 0.4) : Colors.red.shade100,
                  child: Icon(Icons.history_rounded, color: isDark ? Colors.red.shade200 : Colors.red.shade900),
                ),
                title: Text(
                  'Bus ${sos.busNumber} Incident',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.red.shade900,
                  ),
                ),
                subtitle: Text(
                  'Resolved at ${DateFormat('MMM dd, HH:mm').format((sos.resolvedAt ?? sos.timestamp).toLocal())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.red.shade900.withValues(alpha: 0.8),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogDetail('Reported By', '${sos.userRole} (${DateFormat('HH:mm:ss').format(sos.timestamp.toLocal())})', isDark),
                        _buildLogDetail('Resolved By', sos.resolvedBy ?? 'System', isDark),
                        _buildLogDetail('Incident ID', sos.sosId, isDark),
                        Divider(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                        ),
                        Text(
                          'Documentation / Resolution Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: isDark ? Colors.white70 : Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sos.resolutionNotes ?? 'No notes provided.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogDetail(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 12,
            ),
          ),
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
