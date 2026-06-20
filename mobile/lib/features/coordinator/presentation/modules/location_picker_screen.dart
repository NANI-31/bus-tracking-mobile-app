import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:collegebus/core/constants/constants.dart';
import 'package:collegebus/core/services/persistence_service.dart';
import 'package:collegebus/shared/widgets/glass_morphic_container.dart';
import 'package:collegebus/shared/widgets/maps/map_overlay_layout.dart';
import 'package:collegebus/widgets/liquid_glass/liquid_glass_lens_shader.dart';
import 'package:collegebus/widgets/liquid_glass/base_shader.dart';

/// Returned when the user confirms a location.
class LocationPickerResult {
  final LatLng latLng;
  final String address;
  const LocationPickerResult({required this.latLng, required this.address});
}

/// Full-screen map picker with:
/// • Center-pin drag-to-pick
/// • Places Autocomplete (session-token batched — cost-safe)
/// • Debounced reverse geocoding (only when map is idle)
///
/// Usage:
/// ```dart
/// final result = await Navigator.of(context).push<LocationPickerResult>(
///   MaterialPageRoute(builder: (_) => LocationPickerScreen(title: 'Pick Start')),
/// );
/// ```
class LocationPickerScreen extends StatefulWidget {
  final String title;
  final LatLng? initialPosition;

  const LocationPickerScreen({
    super.key,
    required this.title,
    this.initialPosition,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final GlobalKey _mapKey = GlobalKey();
  LiquidGlassLensShader? _searchShader;
  LiquidGlassLensShader? _backShader;
  LiquidGlassLensShader? _myLocationShader;

  // ─── Map state ────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(20.5937, 78.9629); // India default
  String _address = 'Move the map to select a location';
  bool _isLoadingAddress = false;
  bool _isConfirming = false;
  bool _mapReady = false;

  // ─── Search (Places Autocomplete) ─────────────────────────────────────────
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<_PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  Timer? _autocompleteDebounce;
  // Session token: groups autocomplete + details into one billable session.
  String _sessionToken = '';

  // ─── Dio ──────────────────────────────────────────────────────────────────
  final _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  // ─── Init ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchShader = LiquidGlassLensShader()..initialize();
    _backShader = LiquidGlassLensShader()..initialize();
    _myLocationShader = LiquidGlassLensShader()..initialize();
    if (widget.initialPosition != null) _center = widget.initialPosition!;

    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) setState(() => _showSuggestions = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPosition == null) _tryMoveToUserLocation();
    });
  }

  @override
  void dispose() {
    _autocompleteDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ─── Session token ────────────────────────────────────────────────────────
  void _refreshSessionToken() {
    _sessionToken = '${DateTime.now().millisecondsSinceEpoch}';
  }

  // ─── User location ────────────────────────────────────────────────────────
  Future<void> _tryMoveToUserLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final ll = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _center = ll);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(ll, 16));
    } catch (_) {}
  }

  // ─── Places Autocomplete ──────────────────────────────────────────────────
  /// Cost note: With session tokens, all keystrokes are FREE.
  /// Only the final Place Details call is billed (~$0.017 per session).
  void _onSearchChanged(String query) {
    if (_sessionToken.isEmpty) _refreshSessionToken();
    _autocompleteDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _autocompleteDebounce = Timer(const Duration(milliseconds: 450), () {
      _fetchSuggestions(query.trim());
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    if (!mounted) return;
    setState(() => _isSearching = true);
    try {
      final token = PersistenceService.getAuthToken();
      final url =
          '/places/autocomplete'
          '?input=${Uri.encodeComponent(input)}'
          '&sessiontoken=$_sessionToken';
      final res = await _dio.get(
        url,
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      if (!mounted) return;
      final data = res.data is String
          ? jsonDecode(res.data as String)
          : res.data as Map;
      final preds = data['predictions'] as List? ?? [];
      setState(() {
        _suggestions = preds
            .map(
              (p) => _PlaceSuggestion(
                placeId: p['place_id'] as String,
                mainText:
                    p['structured_formatting']?['main_text'] as String? ??
                    p['description'] as String? ??
                    '',
                secondaryText:
                    p['structured_formatting']?['secondary_text'] as String? ??
                    '',
              ),
            )
            .toList();
        _showSuggestions = _suggestions.isNotEmpty;
      });
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  String _cleanAddress(String address) {
    if (address.isEmpty) return address;

    // Split the address by commas and trim whitespace
    final parts = address.split(',').map((e) => e.trim()).toList();

    // List of countries to filter out (case-insensitive)
    final countryList = {
      'india', 'usa', 'united states', 'united kingdom', 'uk', 'canada', 'australia'
    };

    // List of states to filter out (case-insensitive)
    final stateList = {
      'telangana', 'andhra pradesh', 'karnataka', 'maharashtra', 'tamil nadu',
      'kerala', 'delhi', 'uttar pradesh', 'bihar', 'gujarat', 'rajasthan',
      'punjab', 'haryana', 'west bengal', 'odisha', 'madhya pradesh', 'goa',
      'california', 'texas', 'new york', 'florida', 'illinois'
    };

    // We will build a new list of parts, excluding unwanted ones
    final List<String> cleanedParts = [];

    for (final part in parts) {
      final lowerPart = part.toLowerCase();

      // 1. Skip if it matches a country in the list
      if (countryList.contains(lowerPart)) continue;

      // 2. Skip if it contains a 5 or 6-digit pincode/zipcode (e.g. 500032, 94043)
      final hasZip = RegExp(r'\b\d{5,6}\b').hasMatch(part);
      if (hasZip) continue;

      // 3. Skip if it is a known state name
      if (stateList.contains(lowerPart)) continue;

      // 4. Skip if the part contains a state name (e.g. "Telangana State")
      bool containsState = false;
      for (final state in stateList) {
        if (lowerPart.contains(state)) {
          containsState = true;
          break;
        }
      }
      if (containsState) continue;

      cleanedParts.add(part);
    }

    if (cleanedParts.isEmpty) {
      return address;
    }

    return cleanedParts.join(', ');
  }

  /// Fetch Place Details — only geometry + formatted_address (Essentials SKU).
  /// The session token ensures this details call is billed once per session.
  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {
      _searchController.text = suggestion.mainText;
      _showSuggestions = false;
      _suggestions = [];
      _isLoadingAddress = true;
    });

    try {
      // Field mask: only request what we need (keeps billing at Essentials tier)
      final token = PersistenceService.getAuthToken();
      final url =
          '/places/details'
          '?placeId=${suggestion.placeId}'
          '&sessiontoken=$_sessionToken';

      final res = await _dio.get(
        url,
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      if (!mounted) return;
      final data = res.data is String
          ? jsonDecode(res.data as String)
          : res.data as Map;
      final result = data['result'] as Map?;
      final location = result?['geometry']?['location'] as Map?;

      if (location != null) {
        final ll = LatLng(
          (location['lat'] as num).toDouble(),
          (location['lng'] as num).toDouble(),
        );
        setState(() {
          _center = ll;
          _address = _cleanAddress(
              result?['formatted_address'] as String? ?? suggestion.mainText);
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(ll, 16));
      }

      // Session is consumed — generate a new token for the next search.
      _refreshSessionToken();
    } catch (_) {
      if (mounted) setState(() => _isLoadingAddress = false);
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  // ─── Map callbacks ────────────────────────────────────────────────────────
  void _onCameraMove(CameraPosition pos) => _center = pos.target;

  void _onCameraMoveStarted() {
    // Dismiss search suggestions while dragging and reset address to placeholder
    setState(() {
      _showSuggestions = false;
      _address = 'Move the map to select a location';
    });
  }

  void _onCameraIdle() {
    // Refresh the UI to display the current coordinates under the address
    setState(() {});
  }

  void _onMapCreated(GoogleMapController ctrl) {
    _mapController = ctrl;
    setState(() => _mapReady = true);
  }

  // ─── Confirm ──────────────────────────────────────────────────────────────
  Future<void> _confirm() async {
    if (_isConfirming) return;
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isConfirming = true;
    });

    String finalAddress = _address;

    try {
      final token = PersistenceService.getAuthToken();
      final url = '/places/reverse-geocode?lat=${_center.latitude}&lng=${_center.longitude}';
      final res = await _dio.get(
        url,
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
      if (mounted) {
        final data = res.data is String
            ? jsonDecode(res.data as String)
            : res.data as Map;
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          finalAddress = _cleanAddress(
              results.first['formatted_address'] as String? ?? 'Unknown location');
        } else {
          finalAddress = 'Unknown location';
        }
      }
    } catch (_) {
      finalAddress = '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}';
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
          _address = finalAddress;
        });
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(LocationPickerResult(latLng: _center, address: finalAddress));
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.primary;

    final mapWidget = RepaintBoundary(
      key: _mapKey,
      child: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: widget.initialPosition != null ? 16.5 : 12,
        ),
        onCameraMove: _onCameraMove,
        onCameraMoveStarted: _onCameraMoveStarted,
        onCameraIdle: _onCameraIdle,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        buildingsEnabled: true,
      ),
    );

    final topBarWidget = Column(
      children: [
        Row(
          children: [
            _GlassIconBtn(
              onTap: () => Navigator.of(context).pop(),
              icon: Icons.arrow_back_ios_new_rounded,
              backgroundKey: _mapKey,
              shader: _backShader,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SearchBar(
                controller: _searchController,
                focusNode: _searchFocus,
                isLoading: _isSearching,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _suggestions = [];
                    _showSuggestions = false;
                  });
                },
                isDark: isDark,
                themeColor: color,
                backgroundKey: _mapKey,
                shader: _searchShader,
              ),
            ),
          ],
        ),

        // Suggestions dropdown
        if (_showSuggestions && _suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          _SuggestionsDropdown(
            suggestions: _suggestions,
            isDark: isDark,
            themeColor: color,
            onSelect: _selectSuggestion,
          ),
        ],
      ],
    );

    final centerCrosshairWidget = Transform.translate(
      offset: const Offset(0, -24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 26,
            ),
          ),
          CustomPaint(
            size: const Size(16, 10),
            painter: _PinTailPainter(color: color),
          ),
          Container(
            width: 12,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );

    final bottomPanelWidget = _BottomPanel(
      address: _address,
      isLoading: _isLoadingAddress,
      isConfirming: _isConfirming,
      latLng: _center,
      themeColor: color,
      isDark: isDark,
      onConfirm: _confirm,
    );

    final myLocationFab = _GlassIconBtn(
      onTap: _tryMoveToUserLocation,
      iconWidget: Icon(
        Icons.my_location_rounded,
        size: 22,
        color: color,
      ),
      backgroundKey: _mapKey,
      shader: _myLocationShader,
    );

    return MapOverlayLayout(
      map: mapWidget,
      topBar: topBarWidget,
      centerCrosshair: _mapReady ? centerCrosshairWidget : null,
      bottomPanel: bottomPanelWidget,
      floatingActions: [myLocationFab],
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  const _PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _GlassIconBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? iconWidget;
  final GlobalKey? backgroundKey;
  final BaseShader? shader;

  const _GlassIconBtn({
    required this.onTap,
    this.icon,
    this.iconWidget,
    this.backgroundKey,
    this.shader,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(21);

    final Widget content = Center(
      child:
          iconWidget ??
          Icon(icon, size: 18, color: isDark ? Colors.white : Colors.black87),
    );

    final Color bgColor = isDark
        ? Colors.black.withValues(alpha: 0.28)
        : const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.24);
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.3);

    return GestureDetector(
      onTap: onTap,
      child: GlassMorphicContainer(
        width: 42,
        height: 42,
        boxShape: BoxShape.circle,
        borderRadius: borderRadius,
        backgroundKey: backgroundKey,
        shader: shader,
        backgroundColor: bgColor,
        borderColor: borderColor,
        blurSigma: 2.0,
        child: content,
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isDark;
  final Color themeColor;
  final GlobalKey? backgroundKey;
  final BaseShader? shader;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onChanged,
    required this.onClear,
    required this.isDark,
    required this.themeColor,
    this.backgroundKey,
    this.shader,
  });

  @override
  Widget build(BuildContext context) {
    final searchContent = Row(
      children: [
        const SizedBox(width: 12),
        Icon(
          Icons.search_rounded,
          color: isDark
              ? const Color.fromARGB(255, 255, 255, 255)
              : const Color.fromARGB(255, 0, 0, 0),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: 'Search for a place...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color.fromARGB(255, 255, 255, 255)
                    : const Color.fromARGB(255, 0, 0, 0),
              ),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: themeColor,
              ),
            ),
          )
        else if (controller.text.isNotEmpty)
          GestureDetector(
            onTap: onClear,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
      ],
    );

    final borderRadius = BorderRadius.circular(14);
    final Color? bgOverride = isDark
        ? null
        : const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.6);
    final double blurOverride = (backgroundKey != null && shader != null)
        ? 2.0
        : 5.0;

    return GlassMorphicContainer(
      height: 46,
      borderRadius: borderRadius,
      backgroundColor: bgOverride,
      blurSigma: blurOverride,
      backgroundKey: backgroundKey,
      shader: shader,
      child: searchContent,
    );
  }
}

class _SuggestionsDropdown extends StatelessWidget {
  final List<_PlaceSuggestion> suggestions;
  final bool isDark;
  final Color themeColor;
  final ValueChanged<_PlaceSuggestion> onSelect;

  const _SuggestionsDropdown({
    required this.suggestions,
    required this.isDark,
    required this.themeColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2732).withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
          indent: 52,
        ),
        itemBuilder: (context, i) {
          final s = suggestions[i];
          return ListTile(
            dense: true,
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.place_outlined, color: themeColor, size: 16),
            ),
            title: Text(
              s.mainText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: s.secondaryText.isNotEmpty
                ? Text(
                    s.secondaryText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () => onSelect(s),
          );
        },
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final String address;
  final bool isLoading;
  final bool isConfirming;
  final LatLng latLng;
  final Color themeColor;
  final bool isDark;
  final VoidCallback? onConfirm;

  const _BottomPanel({
    required this.address,
    required this.isLoading,
    required this.isConfirming,
    required this.latLng,
    required this.themeColor,
    required this.isDark,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).padding.bottom + 18,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2732).withValues(alpha: 0.97)
            : Colors.white.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.place_rounded, color: themeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Location',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    isLoading
                        ? Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: themeColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Locating address...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            address,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    const SizedBox(height: 4),
                    Text(
                      '${latLng.latitude.toStringAsFixed(6)}, '
                      '${latLng.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: isDark ? Colors.white30 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isConfirming ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                elevation: 3,
                shadowColor: themeColor.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isConfirming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Confirm Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}
