import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collegebus/features/route/domain/route_model.dart';
import 'package:collegebus/features/auth/application/auth_provider.dart';
import 'package:collegebus/features/route/application/route_provider.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/features/coordinator/presentation/modules/location_picker_screen.dart';
import 'package:collegebus/l10n/coordinator/app_localizations.dart'
    as coord_l10n;

class RouteEditScreen extends ConsumerStatefulWidget {
  final RouteModel? route; // null for create, non-null for edit

  const RouteEditScreen({super.key, this.route});

  @override
  ConsumerState<RouteEditScreen> createState() => _RouteEditScreenState();
}

class _RouteEditScreenState extends ConsumerState<RouteEditScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late String _selectedType;
  late List<TextEditingController> _stopControllers;
  bool _isLoading = false;
  bool _isKeyboardVisible = false;

  // Shake animation keys
  final _nameShakeKey = GlobalKey<ShakeWidgetState>();
  final _startShakeKey = GlobalKey<ShakeWidgetState>();
  final _endShakeKey = GlobalKey<ShakeWidgetState>();

  // Coordinate state - updated when coordinator picks from map
  RoutePoint? _startPoint;
  RoutePoint? _endPoint;
  List<RoutePoint?> _stopPoints = [];

  bool get isEditing => widget.route != null;

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _attachListeners(TextEditingController controller) {
    controller.addListener(_onFieldChanged);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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

    // Restore coordinate state from existing route
    _startPoint = widget.route?.startPoint;
    _endPoint = widget.route?.endPoint;
    _stopPoints = (widget.route?.stopPoints ?? [])
        .map<RoutePoint?>((s) => s)
        .toList();

    if (_stopControllers.isEmpty) {
      _stopControllers.add(TextEditingController());
      _stopPoints.add(null);
    }

    _nameController.addListener(_onFieldChanged);
    _startController.addListener(_onFieldChanged);
    _endController.addListener(_onFieldChanged);
    for (var c in _stopControllers) {
      _attachListeners(c);
    }
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final bottomInset = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .viewInsets
        .bottom;
    final isKeyboardOpen = bottomInset > 0.0;
    if (_isKeyboardVisible && !isKeyboardOpen) {
      FocusScope.of(context).unfocus();
    }
    _isKeyboardVisible = isKeyboardOpen;
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _startController.removeListener(_onFieldChanged);
    _endController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    for (var c in _stopControllers) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _addStop() {
    HapticFeedback.lightImpact();
    final controller = TextEditingController();
    _attachListeners(controller);
    setState(() {
      _stopControllers.add(controller);
      _stopPoints.add(null);
    });
  }

  void _removeStop(int index) {
    if (_stopControllers.length > 1) {
      HapticFeedback.mediumImpact();
      setState(() {
        _stopControllers[index].removeListener(_onFieldChanged);
        _stopControllers[index].dispose();
        _stopControllers.removeAt(index);
        if (index < _stopPoints.length) _stopPoints.removeAt(index);
      });
    }
  }

  // Location picker launcher
  Future<void> _openLocationPicker({
    required String title,
    LatLng? initialPosition,
    required void Function(LocationPickerResult) onPicked,
  }) async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      PageRouteBuilder(
        pageBuilder: (ctx, anim, _) => LocationPickerScreen(
          title: title,
          initialPosition: initialPosition,
        ),
        transitionsBuilder: (ctx, anim, _, child) {
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
    if (result != null && mounted) onPicked(result);
  }

  /// Returns null when a point has no valid coordinates (lat==0 && lng==0).
  LatLng? _pointToLatLng(RoutePoint? p) {
    if (p == null || (p.lat == 0 && p.lng == 0)) return null;
    return LatLng(p.lat, p.lng);
  }

  Future<void> _saveRoute() async {
    bool hasValidationError = false;

    if (_startController.text.trim().isEmpty) {
      _startShakeKey.currentState?.shake();
      hasValidationError = true;
    }
    if (_endController.text.trim().isEmpty) {
      _endShakeKey.currentState?.shake();
      hasValidationError = true;
    }

    if (!_formKey.currentState!.validate() || hasValidationError) {
      HapticFeedback.vibrate();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final routeMutator = ref.read(routeMutatorProvider.notifier);
      final user = ref.read(currentUserProvider);
      final collegeId = user?.collegeId;

      if (collegeId == null) {
        throw Exception('College ID not found');
      }

      final stops = _stopControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Route color defaults to AppColors.primary (Turkish Blue) hex representation
      const defaultColorHex = '#00C6E6';

      if (isEditing) {
        await routeMutator.updateRoute(widget.route!.id, {
          'routeName': _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : '${_startController.text.trim()} - ${_endController.text.trim()}',
          'routeType': _selectedType,
          'color': widget.route?.color ?? defaultColorHex,
          'startPoint': {
            'name': _startController.text.trim(),
            'location': {
              'lat': _startPoint?.lat ?? widget.route!.startPoint.lat,
              'lng': _startPoint?.lng ?? widget.route!.startPoint.lng,
            },
          },
          'endPoint': {
            'name': _endController.text.trim(),
            'location': {
              'lat': _endPoint?.lat ?? widget.route!.endPoint.lat,
              'lng': _endPoint?.lng ?? widget.route!.endPoint.lng,
            },
          },
          'stopPoints': stops.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final pickedPoint = idx < _stopPoints.length
                ? _stopPoints[idx]
                : null;
            final existingPoint = idx < (widget.route?.stopPoints.length ?? 0)
                ? widget.route!.stopPoints[idx]
                : null;
            return {
              'name': s,
              'location': {
                'lat': pickedPoint?.lat ?? existingPoint?.lat ?? 0,
                'lng': pickedPoint?.lng ?? existingPoint?.lng ?? 0,
              },
            };
          }).toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        final newRoute = RouteModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          routeName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : '${_startController.text.trim()} - ${_endController.text.trim()}',
          routeType: _selectedType,
          color: defaultColorHex,
          startPoint: RoutePoint(
            name: _startController.text.trim(),
            lat: _startPoint?.lat ?? 0,
            lng: _startPoint?.lng ?? 0,
          ),
          endPoint: RoutePoint(
            name: _endController.text.trim(),
            lat: _endPoint?.lat ?? 0,
            lng: _endPoint?.lng ?? 0,
          ),
          stopPoints: stops.asMap().entries.map((e) {
            final p = e.key < _stopPoints.length ? _stopPoints[e.key] : null;
            return RoutePoint(
              name: e.value,
              lat: p?.lat ?? 0,
              lng: p?.lng ?? 0,
            );
          }).toList(),
          collegeId: collegeId,
          createdBy: user?.id ?? '',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: null,
        );
        await routeMutator.createRoute(newRoute);
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
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = coord_l10n.CoordinatorLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEditing ? l10n.editRoute : l10n.createRoute,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 28,
              ),
              tooltip: l10n.save,
              onPressed: _saveRoute,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingMedium,
            ),
            child: VStack([
              // 1. Live Timeline & Custom Map Preview Card
              _buildCard(
                child: context.isMobileLayout
                    ? Column(
                        children: [
                          _LiveTimelinePreview(
                            routeName: _nameController.text.trim(),
                            startName: _startController.text.trim(),
                            stops: _stopControllers
                                .map((c) => c.text.trim())
                                .toList(),
                            endName: _endController.text.trim(),
                            routeColor: themeColor,
                          ),
                          const SizedBox(height: 16),
                          _VectorMapPreview(
                            startName: _startController.text.trim(),
                            stops: _stopControllers
                                .map((c) => c.text.trim())
                                .toList(),
                            endName: _endController.text.trim(),
                            routeColor: themeColor,
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: _LiveTimelinePreview(
                              routeName: _nameController.text.trim(),
                              startName: _startController.text.trim(),
                              stops: _stopControllers
                                  .map((c) => c.text.trim())
                                  .toList(),
                              endName: _endController.text.trim(),
                              routeColor: themeColor,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 5,
                            child: _VectorMapPreview(
                              startName: _startController.text.trim(),
                              stops: _stopControllers
                                  .map((c) => c.text.trim())
                                  .toList(),
                              endName: _endController.text.trim(),
                              routeColor: themeColor,
                            ),
                          ),
                        ],
                      ),
              ),
              16.heightBox,

              // 2. Route Settings Card
              _buildCard(
                title: 'Route Settings',
                icon: Icons.settings_outlined,
                accentColor: themeColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route Name Input (wrapped in ShakeWidget)
                    ShakeWidget(
                      key: _nameShakeKey,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.routeName,
                          hintText: 'Leave empty to auto-generate',
                          prefixIcon: Icon(Icons.route, color: themeColor),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                        ),
                      ),
                    ),
                    16.heightBox,

                    // Route Type Sliding Selector
                    _SlidingTypeSelector(
                      selectedType: _selectedType,
                      activeColor: themeColor,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedType = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              16.heightBox,

              // 3. Transit Stop Nodes Card
              _buildCard(
                title: 'Transit Nodes',
                icon: Icons.alt_route_outlined,
                accentColor: themeColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Start Point Input
                    ShakeWidget(
                      key: _startShakeKey,
                      child: TextFormField(
                        controller: _startController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.startPoint,
                          hintText: 'Enter start terminal/stop',
                          prefixIcon: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.green,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.map_outlined,
                              color: themeColor,
                              size: 20,
                            ),
                            tooltip: 'Pick from map',
                            onPressed: () => _openLocationPicker(
                              title: 'Pick Start Point',
                              initialPosition: _pointToLatLng(_startPoint),
                              onPicked: (result) {
                                setState(() {
                                  _startController.text = result.address;
                                  _startPoint = RoutePoint(
                                    name: result.address,
                                    lat: result.latLng.latitude,
                                    lng: result.latLng.longitude,
                                  );
                                });
                              },
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                        ),
                        validator: (v) =>
                            v?.trim().isEmpty == true ? 'Required' : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        top: 4,
                        bottom: 4,
                      ),
                      child: _buildCoordBadge(_startPoint, themeColor),
                    ),
                    20.heightBox,

                    // Stops Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Intermediate Stops (${_stopControllers.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Hold & drag to reorder',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white30 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    8.heightBox,

                    // Reorderable stops list
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _stopControllers.length,
                      onReorder: (oldIndex, newIndex) {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final controller = _stopControllers.removeAt(
                            oldIndex,
                          );
                          _stopControllers.insert(newIndex, controller);
                          // Keep coordinate state in sync with controller order
                          if (oldIndex < _stopPoints.length) {
                            final pt = _stopPoints.removeAt(oldIndex);
                            while (_stopPoints.length < newIndex) {
                              _stopPoints.add(null);
                            }
                            _stopPoints.insert(newIndex, pt);
                          }
                        });
                      },
                      itemBuilder: (context, idx) {
                        final controller = _stopControllers[idx];
                        return _buildStopField(idx, controller);
                      },
                    ),

                    // Add stop button
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addStop,
                        icon: Icon(
                          Icons.add_location_alt_rounded,
                          color: themeColor,
                        ),
                        label: Text(
                          l10n.addStop,
                          style: TextStyle(color: themeColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: themeColor.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    20.heightBox,

                    // End Point Input
                    ShakeWidget(
                      key: _endShakeKey,
                      child: TextFormField(
                        controller: _endController,
                        decoration: InputDecoration(
                          labelText: l10n.endPoint,
                          hintText: 'Enter final terminal/stop',
                          prefixIcon: const Icon(
                            Icons.stop_rounded,
                            color: AppColors.danger,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.map_outlined,
                              color: themeColor,
                              size: 20,
                            ),
                            tooltip: 'Pick from map',
                            onPressed: () => _openLocationPicker(
                              title: 'Pick End Point',
                              initialPosition: _pointToLatLng(_endPoint),
                              onPicked: (result) {
                                setState(() {
                                  _endController.text = result.address;
                                  _endPoint = RoutePoint(
                                    name: result.address,
                                    lat: result.latLng.latitude,
                                    lng: result.latLng.longitude,
                                  );
                                });
                              },
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 2),
                          ),
                        ),
                        validator: (v) =>
                            v?.trim().isEmpty == true ? 'Required' : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: _buildCoordBadge(_endPoint, themeColor),
                    ),
                  ],
                ),
              ),
              24.heightBox,

              // 4. Save Button
              GestureDetector(
                onTapDown: (_) => HapticFeedback.lightImpact(),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveRoute,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, color: Colors.white),
                    label: Text(
                      isEditing ? l10n.save : l10n.create,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      disabledBackgroundColor: themeColor.withValues(
                        alpha: 0.6,
                      ),
                      elevation: 4,
                      shadowColor: themeColor.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
    String? title,
    IconData? icon,
    Color? accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: -4,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: accentColor ?? AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStopField(int idx, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parsedColor = AppColors.primary;
    final stopPoint = idx < _stopPoints.length ? _stopPoints[idx] : null;

    return Column(
      key: ValueKey(controller),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Drag handle
                ReorderableDragStartListener(
                  index: idx,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: isDark ? Colors.white30 : Colors.black38,
                      size: 22,
                    ),
                  ),
                ),
                // Stop Input Field
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Stop ${idx + 1}',
                      hintText: 'Enter stop name',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      prefixIcon: CircleAvatar(
                        radius: 12,
                        backgroundColor: parsedColor.withValues(alpha: 0.12),
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: parsedColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Map pick button
                IconButton(
                  icon: Icon(Icons.map_outlined, color: parsedColor, size: 20),
                  tooltip: 'Pick from map',
                  onPressed: () => _openLocationPicker(
                    title: 'Pick Stop ${idx + 1}',
                    initialPosition: _pointToLatLng(stopPoint),
                    onPicked: (result) {
                      setState(() {
                        controller.text = result.address;
                        while (_stopPoints.length <= idx) {
                          _stopPoints.add(null);
                        }
                        _stopPoints[idx] = RoutePoint(
                          name: result.address,
                          lat: result.latLng.latitude,
                          lng: result.latLng.longitude,
                        );
                      });
                    },
                  ),
                ),
                // Delete button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: _stopControllers.length > 1
                        ? AppColors.danger
                        : (isDark ? Colors.white24 : Colors.black26),
                    size: 22,
                  ),
                  onPressed: _stopControllers.length > 1
                      ? () => _removeStop(idx)
                      : null,
                ),
              ],
            ),
          ),
        ),
        // Coordinate badge
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: _buildCoordBadge(stopPoint, parsedColor),
        ),
      ],
    );
  }

  /// Shows a GPS coordinate pill when a point has been pinned on the map,
  /// or a muted hint prompting the coordinator to set coordinates.
  Widget _buildCoordBadge(RoutePoint? point, Color themeColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCoords = point != null && (point.lat != 0 || point.lng != 0);

    if (hasCoords) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: themeColor.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gps_fixed, size: 12, color: themeColor),
            const SizedBox(width: 5),
            Text(
              '${point.lat.toStringAsFixed(5)},  '
              '${point.lng.toStringAsFixed(5)}',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: themeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 12,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        const SizedBox(width: 4),
        Text(
          'Tap map icon to pin coordinates',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}

class _SlidingTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;
  final Color activeColor;

  const _SlidingTypeSelector({
    required this.selectedType,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPickup = selectedType == 'pickup';

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: isPickup ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged('pickup'),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: 18,
                          color: isPickup
                              ? Colors.white
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Pickup',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged('drop'),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: !isPickup
                              ? Colors.white
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Drop',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // We overlay text with different colors based on selection for premium look
          Row(
            children: [
              Expanded(
                child: IgnorePointer(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: 18,
                          color: isPickup
                              ? Colors.white
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pickup',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isPickup
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: IgnorePointer(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: !isPickup
                              ? Colors.white
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Drop',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: !isPickup
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveTimelinePreview extends StatelessWidget {
  final String routeName;
  final String startName;
  final List<String> stops;
  final String endName;
  final Color routeColor;

  const _LiveTimelinePreview({
    required this.routeName,
    required this.startName,
    required this.stops,
    required this.endName,
    required this.routeColor,
  });

  @override
  Widget build(BuildContext context) {
    final validStops = stops.where((s) => s.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.route, color: routeColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                routeName.isNotEmpty ? routeName : "Unnamed Route Preview",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildNodeRow(
          context,
          isStart: true,
          isEnd: false,
          name: startName,
          placeholder: "Start Location",
          color: routeColor,
          isLast: false,
        ),
        ...validStops.map(
          (stop) => _buildNodeRow(
            context,
            isStart: false,
            isEnd: false,
            name: stop,
            placeholder: "Stop name",
            color: routeColor,
            isLast: false,
          ),
        ),
        if (validStops.isEmpty &&
            stops.isNotEmpty &&
            stops.first.trim().isEmpty)
          _buildNodeRow(
            context,
            isStart: false,
            isEnd: false,
            name: "",
            placeholder: "Add intermediate stops...",
            color: routeColor.withValues(alpha: 0.4),
            isLast: false,
          ),
        _buildNodeRow(
          context,
          isStart: false,
          isEnd: true,
          name: endName,
          placeholder: "End Location",
          color: routeColor,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildNodeRow(
    BuildContext context, {
    required bool isStart,
    required bool isEnd,
    required String name,
    required String placeholder,
    required Color color,
    required bool isLast,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEmpty = name.trim().isEmpty;

    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: 11, // Centered inside the 24px zone (24/2 - 1 = 11)
            top: 14, // Starts after the icon container (height 14)
            bottom: 0,
            child: Container(width: 2.5, color: color.withValues(alpha: 0.4)),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 14,
              alignment: Alignment.center,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isStart
                      ? color
                      : (isEnd ? Colors.transparent : Colors.transparent),
                  shape: isEnd ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: isEnd ? BorderRadius.circular(4) : null,
                  border: Border.all(color: color, width: isStart ? 0.0 : 3.0),
                ),
                child: isEnd
                    ? Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isEmpty ? placeholder : name.trim(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isEmpty ? FontWeight.normal : FontWeight.bold,
                      color: isEmpty
                          ? (isDark ? Colors.white30 : Colors.black38)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VectorMapPreview extends StatefulWidget {
  final String startName;
  final List<String> stops;
  final String endName;
  final Color routeColor;

  const _VectorMapPreview({
    required this.startName,
    required this.stops,
    required this.endName,
    required this.routeColor,
  });

  @override
  State<_VectorMapPreview> createState() => _VectorMapPreviewState();
}

class _VectorMapPreviewState extends State<_VectorMapPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validStops = widget.stops.where((s) => s.trim().isNotEmpty).toList();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _rippleController.forward(from: 0.0);
        if (!_rippleController.isAnimating) {
          _rippleController.repeat();
        }
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Grid Background
              Positioned.fill(
                child: CustomPaint(painter: _MapGridPainter(isDark: isDark)),
              ),
              // Map Vector Path
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rippleController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _VectorMapPainter(
                        startName: widget.startName,
                        stops: validStops,
                        endName: widget.endName,
                        routeColor: widget.routeColor,
                        rippleValue: _rippleController.value,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
              // Map overlay badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.routeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.routeColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    'Interactive Map',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: widget.routeColor,
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

class _MapGridPainter extends CustomPainter {
  final bool isDark;

  _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.02)
          : Colors.black.withValues(alpha: 0.02)
      ..strokeWidth = 1.0;

    const double step = 20.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VectorMapPainter extends CustomPainter {
  final String startName;
  final List<String> stops;
  final String endName;
  final Color routeColor;
  final double rippleValue;
  final bool isDark;

  _VectorMapPainter({
    required this.startName,
    required this.stops,
    required this.endName,
    required this.routeColor,
    required this.rippleValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = routeColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Define fixed schematic coordinates for start, stops, and end points
    final List<Offset> points = [];
    final int totalPoints = 2 + stops.length;

    if (totalPoints == 2) {
      points.add(Offset(size.width * 0.25, size.height * 0.65));
      points.add(Offset(size.width * 0.75, size.height * 0.35));
    } else if (totalPoints == 3) {
      points.add(Offset(size.width * 0.2, size.height * 0.7));
      points.add(Offset(size.width * 0.5, size.height * 0.3));
      points.add(Offset(size.width * 0.8, size.height * 0.6));
    } else {
      points.add(Offset(size.width * 0.15, size.height * 0.7));
      for (int i = 0; i < stops.length; i++) {
        final double ratio = (i + 1) / (stops.length + 1);
        final double x = size.width * (0.15 + ratio * 0.7);
        final double y = size.height * (i % 2 == 0 ? 0.3 : 0.6);
        points.add(Offset(x, y));
      }
      points.add(Offset(size.width * 0.85, size.height * 0.45));
    }

    // Draw connecting paths
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final controlPoint1 = Offset(
        prev.dx + (current.dx - prev.dx) / 2,
        prev.dy,
      );
      final controlPoint2 = Offset(
        prev.dx + (current.dx - prev.dx) / 2,
        current.dy,
      );
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        current.dx,
        current.dy,
      );
    }
    canvas.drawPath(path, pathPaint);

    // Draw active pulsing ripples at start & end
    for (int i = 0; i < points.length; i++) {
      final isStart = i == 0;
      final isEnd = i == points.length - 1;

      final Color pointColor;
      if (isStart) {
        pointColor = const Color(0xFF4CAF50); // green
      } else if (isEnd) {
        pointColor = const Color(0xFFF44336); // red
      } else {
        pointColor = const Color(0xFFFF9800); // orange
      }

      if (isStart || isEnd) {
        final ripplePaint = Paint()
          ..color = pointColor.withValues(alpha: 0.25 * (1.0 - rippleValue))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(points[i], 12 + 15 * rippleValue, ripplePaint);
      }

      final dotPaint = Paint()
        ..color = pointColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(points[i], (isStart || isEnd) ? 7.0 : 5.0, dotPaint);
      if (!isStart && !isEnd) {
        canvas.drawCircle(
          points[i],
          2.5,
          Paint()..color = isDark ? const Color(0xFF1E2732) : Colors.white,
        );
      } else {
        canvas.drawCircle(points[i], 3.0, Paint()..color = Colors.white);
      }

      String labelText = "";
      if (isStart) {
        labelText = startName.isNotEmpty ? startName : "Start";
      } else if (isEnd) {
        labelText = endName.isNotEmpty ? endName : "End";
      } else {
        labelText = stops[i - 1].isNotEmpty ? stops[i - 1] : "S$i";
      }

      if (labelText.length > 10) {
        labelText = "${labelText.substring(0, 8)}..";
      }

      final textSpan = TextSpan(
        text: labelText,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, points[i].dy - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VectorMapPainter oldDelegate) {
    return oldDelegate.startName != startName ||
        oldDelegate.stops != stops ||
        oldDelegate.endName != endName ||
        oldDelegate.routeColor != routeColor ||
        oldDelegate.rippleValue != rippleValue ||
        oldDelegate.isDark != isDark;
  }
}

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double shakeOffset;

  const ShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.shakeOffset = 8.0,
  });

  @override
  ShakeWidgetState createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: widget.shakeOffset),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.shakeOffset,
          end: -widget.shakeOffset,
        ),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -widget.shakeOffset,
          end: widget.shakeOffset,
        ),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.shakeOffset, end: 0.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    return AnimatedBuilder(
      animation: offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(offsetAnimation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
