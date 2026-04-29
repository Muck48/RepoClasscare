import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:classcare_user/services/ai_service.dart';
import 'package:classcare_user/theme/app_design_tokens.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/app_constants.dart';
import 'widgets/app_surfaces.dart';
import 'widgets/classcare_bottom_nav.dart';
import 'home_page.dart';
import 'track_page.dart';
import 'success_page.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({
    super.key,
    this.showBottomNav = true,
    this.onTabSelected,
  });

  final bool showBottomNav;
  final ValueChanged<ClasscareTab>? onTabSelected;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _LocationSearchResult {
  const _LocationSearchResult({required this.label, required this.point});

  final String label;
  final LatLng point;
}

class _ResolvedLocation {
  const _ResolvedLocation({required this.label, required this.point});

  final String label;
  final LatLng point;
}

class _ImageUploadException implements Exception {
  const _ImageUploadException(this.userMessage);

  final String userMessage;
}

class _ReportPageState extends State<ReportPage> with TickerProviderStateMixin {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _imagePicker = ImagePicker();

  late final AnimationController _pageAnimController;
  late final AnimationController _loadingAnimController;
  late final Animation<double> _fadeAnim;

  String? _selectedCategory;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  int _currentStep = 0;
  int _stepTransitionDirection = 1;
  int _charCount = 0;
  String _draftHint = 'Draft will be saved automatically';
  bool _draftLoaded = false;
  Timer? _draftDebounce;
  final List<Uint8List> _selectedImageBytes = [];
  final List<String> _selectedImageNames = [];
  List<String> _recentLocations = [];
  LatLng? _selectedLocationPoint;
  bool _isProgrammaticLocationUpdate = false;

  static const int _minChars = 20;
  static const int _maxChars = 500;
  static const int _minLocationChars = 3;
  static const int _maxImageBytes = 10 * 1024 * 1024;
  static const String _draftDescriptionKey = 'report_draft_description';
  static const String _draftLocationKey = 'report_draft_location';
  static const String _draftCategoryKey = 'report_draft_category';
  static const String _draftStepKey = 'report_draft_step';
  static const String _draftSavedAtKey = 'report_draft_saved_at';
  static const String _recentLocationsKey = 'recent_report_locations';
  static const Duration _locationTimeout = Duration(seconds: 10);
  static const Duration _nominatimTimeout = Duration(seconds: 6);
  static const String _nominatimUserAgent = 'classcare_user/1.0';

  final List<Map<String, dynamic>> _categories = [
    {
      "name": "Academic",
      "icon": Icons.menu_book_outlined,
      "desc": "Grades, cheating, attendance",
      "detail":
          "Use when the issue is tied to learning, exams, grading, attendance, or repeated classroom misconduct that affects study progress.",
    },
    {
      "name": "Harassment",
      "icon": Icons.warning_amber_outlined,
      "desc": "Bullying, threats, humiliation",
      "detail":
          "Use when someone is being targeted, insulted, threatened, intimidated, or repeatedly mistreated in person or online.",
    },
    {
      "name": "Health",
      "icon": Icons.local_hospital_outlined,
      "desc": "Medical, mental, urgent support",
      "detail":
          "Use for injury, illness, panic attacks, medication issues, or mental-health concerns that need immediate attention or care.",
    },
    {
      "name": "Safety",
      "icon": Icons.shield_outlined,
      "desc": "Physical danger, unsafe behavior",
      "detail":
          "Use for fights, weapons, self-harm risk, abuse, or any situation that could cause immediate harm to people nearby.",
    },
    {
      "name": "Facility",
      "icon": Icons.apartment_outlined,
      "desc": "Broken rooms, access, utilities",
      "detail":
          "Use for damaged equipment, blocked exits, power or water problems, accessibility barriers, or other building issues.",
    },
    {
      "name": "Other",
      "icon": Icons.chat_bubble_outline,
      "desc": "Anything else, not sure yet",
      "detail":
          "Use when the issue crosses categories, does not fit the options above, or you want the team to triage it first.",
    },
  ];

    Color get _bg => AppColors.bgByTheme(Theme.of(context).brightness);

    Color get _surface => AppColors.surfaceByTheme(Theme.of(context).brightness);

    Color get _primary => AppColors.primary;

    Color get _border => AppColors.borderByTheme(Theme.of(context).brightness);

    Color get _inputBg => AppColors.inputBgByTheme(Theme.of(context).brightness);

    Color get _inputBorder =>
      AppColors.inputBorderByTheme(Theme.of(context).brightness);

    Color get _divider =>
      Theme.of(context).brightness == Brightness.light
        ? AppColors.dividerLight
        : AppColors.dividerDark;

  @override
  void initState() {
    super.initState();
    _pageAnimController = AnimationController(
      vsync: this,
      duration: MotionTokens.slow,
    );
    _loadingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _fadeAnim = CurvedAnimation(
      parent: _pageAnimController,
      curve: MotionTokens.entranceCurve,
    );
    _pageAnimController.forward();

    _descriptionController.addListener(() {
      setState(() => _charCount = _descriptionController.text.length);
      _scheduleDraftSave();
    });
    _locationController.addListener(_scheduleDraftSave);
    _restoreDraft();
    _loadRecentLocations();

    _locationFocus.addListener(() {
      if (!_locationFocus.hasFocus) {
        _saveRecentLocation(_locationController.text.trim());
      }
      setState(() {});
    });
    _descriptionFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _pageAnimController.dispose();
    _loadingAnimController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _locationFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_isSubmitting &&
      !_isUploadingImage &&
      _charCount >= _minChars &&
      _isCategoryStepComplete &&
      _isLocationStepComplete;

  bool get _isCategoryStepComplete => _selectedCategory != null;

  bool get _isLocationStepComplete =>
      _locationController.text.trim().length >= _minLocationChars;

  bool get _hasDraftLikeContent =>
      _descriptionController.text.trim().isNotEmpty ||
      _locationController.text.trim().isNotEmpty ||
      _selectedCategory != null ||
      _currentStep > 0;

  bool get _isStepTwoComplete => _charCount >= _minChars;

  bool get _canAdvanceCurrentStep {
    switch (_currentStep) {
      case 0:
        return _isCategoryStepComplete;
      case 1:
        return _isLocationStepComplete;
      case 2:
        return _isStepTwoComplete;
      default:
        return false;
    }
  }

  bool get _hasImages => _selectedImageBytes.isNotEmpty;

  bool get _isNativeCameraSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool _isSupportedImageName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  Future<int> _safeFileLength(XFile file) async {
    try {
      return await file.length();
    } catch (_) {
      return -1;
    }
  }

  String _formatImageSizeLimit() {
    final mb = (_maxImageBytes / (1024 * 1024)).toStringAsFixed(0);
    return '$mb MB';
  }

  void _showFileSizeError(List<String> names) {
    final shown = names.take(2).join(', ');
    final remaining = names.length - 2;
    final extra = remaining > 0 ? ' +$remaining more' : '';
    _showAnimatedSnackBar(
      'Some images were skipped. Max size is ${_formatImageSizeLimit()} per file: $shown$extra.',
      color: Colors.red.shade400,
    );
  }

  List<String> _placemarkParts(Placemark placemark) {
    return <String?>[
          placemark.name,
          placemark.thoroughfare,
          placemark.subLocality,
          placemark.locality,
          placemark.administrativeArea,
        ]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  String _formatDraftTimestamp(DateTime dateTime) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatCompactDate(dateTime);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    return '$date $time';
  }

  String _savedDraftHint(DateTime savedAt) {
    return 'Draft saved at ${_formatDraftTimestamp(savedAt)}';
  }

  void _showDraftRestoredNotice(DateTime? savedAt) {
    final suffix = savedAt == null
        ? ''
        : ' (last saved ${_formatDraftTimestamp(savedAt)})';
    _showAnimatedSnackBar('Draft restored from previous session$suffix');
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final description = prefs.getString(_draftDescriptionKey) ?? '';
    final location = prefs.getString(_draftLocationKey) ?? '';
    final category = prefs.getString(_draftCategoryKey);
    final step = prefs.getInt(_draftStepKey) ?? 0;
    final savedAtMillis = prefs.getInt(_draftSavedAtKey);
    final savedAt = savedAtMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(savedAtMillis).toLocal();

    if (!mounted) return;
    if (description.isEmpty && location.isEmpty && category == null) {
      setState(() {
        _draftHint = 'Draft will be saved automatically';
        _draftLoaded = true;
      });
      return;
    }

    setState(() {
      _descriptionController.text = description;
      _locationController.text = location;
      _selectedCategory = category;
      _charCount = description.length;
      _currentStep = step.clamp(0, 3);
      _draftHint = savedAt == null
          ? 'Draft restored from previous session'
          : _savedDraftHint(savedAt);
      _draftLoaded = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showDraftRestoredNotice(savedAt);
    });
  }

  void _scheduleDraftSave() {
    if (!_draftLoaded) return;
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 450), _persistDraft);
  }

  Future<void> _persistDraft() async {
    final now = DateTime.now().toLocal();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _draftDescriptionKey,
      _descriptionController.text.trim(),
    );
    await prefs.setString(_draftLocationKey, _locationController.text.trim());
    if (_selectedCategory == null) {
      await prefs.remove(_draftCategoryKey);
    } else {
      await prefs.setString(_draftCategoryKey, _selectedCategory!);
    }
    await prefs.setInt(_draftStepKey, _currentStep);
    await prefs.setInt(_draftSavedAtKey, now.millisecondsSinceEpoch);
    if (!mounted) return;
    setState(() => _draftHint = _savedDraftHint(now));
  }

  Future<void> _clearDraft() async {
    _draftDebounce?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftDescriptionKey);
    await prefs.remove(_draftLocationKey);
    await prefs.remove(_draftCategoryKey);
    await prefs.remove(_draftStepKey);
    await prefs.remove(_draftSavedAtKey);
  }

  Future<bool> _confirmClearDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear draft?'),
          content: const Text(
            'This will permanently remove all current report details. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Draft'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _saveRecentTrackingId(String trackingId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(AppPrefsKeys.recentTrackingIds) ?? <String>[];
    final updated = [
      trackingId,
      ...existing.where((id) => id != trackingId),
    ].take(8).toList();
    await prefs.setStringList(AppPrefsKeys.recentTrackingIds, updated);
  }

  Future<void> _loadRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locations = prefs.getStringList(_recentLocationsKey) ?? <String>[];
    if (!mounted) return;
    setState(() => _recentLocations = locations);
  }

  Future<void> _saveRecentLocation(String location) async {
    final trimmed = location.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_recentLocationsKey) ?? <String>[];
    final updated = [
      trimmed,
      ...existing.where((item) => item != trimmed),
    ].take(6).toList();
    await prefs.setStringList(_recentLocationsKey, updated);
    if (!mounted) return;
    setState(() => _recentLocations = updated);
  }

  void _setLocationValue(String location, {LatLng? point}) {
    final trimmed = location.trim();
    if (trimmed.isEmpty) return;

    _isProgrammaticLocationUpdate = true;
    setState(() {
      _locationController.text = trimmed;
      _locationController.selection = TextSelection.collapsed(
        offset: trimmed.length,
      );
      _selectedLocationPoint = point;
      _draftHint = 'Location updated';
    });
    _isProgrammaticLocationUpdate = false;
    _saveRecentLocation(trimmed);
    _scheduleDraftSave();
  }

  String _formatCoordinates(double latitude, double longitude) {
    return 'Lat ${latitude.toStringAsFixed(5)}, Lng ${longitude.toStringAsFixed(5)}';
  }

  String _buildLocationPayloadForSubmit(String locationLabel) {
    final trimmed = locationLabel.trim();
    final point = _selectedLocationPoint;
    if (trimmed.isEmpty || point == null) {
      return trimmed;
    }
    return '$trimmed (${_formatCoordinates(point.latitude, point.longitude)})';
  }

  Future<String?> _resolveLocationWithNominatim(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toStringAsFixed(7),
      'lon': longitude.toStringAsFixed(7),
      'zoom': '18',
      'addressdetails': '1',
    });

    try {
      final response = await http
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': _nominatimUserAgent,
            },
          )
          .timeout(_nominatimTimeout);

      if (response.statusCode != 200) {
        debugPrint(
          'Nominatim reverse lookup failed: HTTP ${response.statusCode}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final displayName = decoded['display_name'] as String?;
      if (displayName == null || displayName.trim().isEmpty) {
        return null;
      }

      return displayName.trim();
    } on TimeoutException {
      debugPrint('Nominatim reverse lookup timed out');
      return null;
    } catch (e) {
      debugPrint('Nominatim reverse lookup failed: $e');
      return null;
    }
  }

  Future<String> _resolveReadableLocationLabel(
    double latitude,
    double longitude, {
    String? fallbackLabel,
  }) async {
    if (!kIsWeb) {
      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final parts = _placemarkParts(placemarks.first);
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      } catch (e) {
        debugPrint('Reverse geocode failed: $e');
      }
    }

    final nominatimLabel = await _resolveLocationWithNominatim(
      latitude,
      longitude,
    );
    if (nominatimLabel != null && nominatimLabel.isNotEmpty) {
      return nominatimLabel;
    }

    if (fallbackLabel != null && fallbackLabel.trim().isNotEmpty) {
      return fallbackLabel.trim();
    }

    return 'Pinned area near selected point';
  }

  Future<_ResolvedLocation?> _resolveCurrentLocation() async {
    final point = await _resolveCurrentLatLng();
    if (point == null) return null;

    final label = await _resolveReadableLocationLabel(
      point.latitude,
      point.longitude,
      fallbackLabel: 'Current location',
    );

    return _ResolvedLocation(label: label, point: point);
  }

  Future<String> _resolveReadableLocationFromCoordinates(
    double latitude,
    double longitude, {
    String? fallbackLabel,
  }) async {
    return _resolveReadableLocationLabel(
      latitude,
      longitude,
      fallbackLabel: fallbackLabel,
    );
  }

  Future<List<String>> _searchLocationSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return <String>[];

    try {
      final results = await locationFromAddress(trimmed);
      final labels = <String>[];
      for (final item in results.take(5)) {
        final label = await _resolveReadableLocationFromCoordinates(
          item.latitude,
          item.longitude,
          fallbackLabel: trimmed,
        );
        if (!labels.contains(label)) {
          labels.add(label);
        }
      }
      return labels;
    } catch (e) {
      debugPrint('Location search failed: $e');
      return <String>[];
    }
  }

  Future<List<_LocationSearchResult>> _searchLocationResults(
    String query,
  ) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return <_LocationSearchResult>[];

    try {
      final results = await locationFromAddress(trimmed);
      final items = <_LocationSearchResult>[];
      for (final item in results.take(5)) {
        final label = await _resolveReadableLocationFromCoordinates(
          item.latitude,
          item.longitude,
          fallbackLabel: trimmed,
        );
        final point = LatLng(item.latitude, item.longitude);
        if (items.every(
          (entry) =>
              entry.point.latitude != point.latitude ||
              entry.point.longitude != point.longitude,
        )) {
          items.add(_LocationSearchResult(label: label, point: point));
        }
      }
      return items;
    } catch (e) {
      debugPrint('Location search failed: $e');
      return <_LocationSearchResult>[];
    }
  }

  Future<LatLng?> _resolvePointFromLocationText(String locationText) async {
    final trimmed = locationText.trim();
    if (trimmed.isEmpty) return null;

    final results = await _searchLocationResults(trimmed);
    if (results.isEmpty) return null;
    return results.first.point;
  }

  Future<LatLng?> _resolveCurrentLatLng() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _showAnimatedSnackBar(
        'Location services are off. Please enable GPS and try again.',
        color: Colors.orange.shade700,
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showAnimatedSnackBar(
        'Location permission is required to use current location.',
        color: Colors.orange.shade700,
      );
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _locationTimeout,
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      _showAnimatedSnackBar(
        'Could not get GPS in time. Please try again.',
        color: Colors.orange.shade700,
      );
      return null;
    } catch (e) {
      debugPrint('Current location lookup failed: $e');
      return null;
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      setState(() => _draftHint = 'Getting current location...');
      final resolved = await _resolveCurrentLocation();
      if (resolved == null) {
        if (mounted) {
          setState(() => _draftHint = 'Draft will be saved automatically');
        }
        return;
      }

      _setLocationValue(resolved.label, point: resolved.point);
      if (mounted) {
        _showAnimatedSnackBar('Current location added.');
      }
    } catch (e) {
      debugPrint('Current location error: $e');
      if (mounted) {
        setState(() => _draftHint = 'Draft will be saved automatically');
        _showAnimatedSnackBar(
          'Unable to get current location.',
          color: Colors.red.shade400,
        );
      }
    }
  }

  Future<void> _showLocationPicker() async {
    final searchController = TextEditingController();
    final location = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        List<String> searchResults = <String>[];
        bool isSearching = false;
        String? searchError;

        Future<void> runSearch(StateSetter setModalState) async {
          final query = searchController.text.trim();
          if (query.isEmpty) {
            setModalState(() {
              searchResults = <String>[];
              searchError = 'Type a place or address to search.';
            });
            return;
          }

          setModalState(() {
            isSearching = true;
            searchError = null;
          });

          final results = await _searchLocationSuggestions(query);
          if (!mounted) return;
          setModalState(() {
            isSearching = false;
            searchResults = results;
            searchError = results.isEmpty
                ? 'No matches found. Try a more specific place name.'
                : null;
          });
        }

        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: AppBorderRadius.radiusTopXxl,
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _divider,
                            borderRadius: AppBorderRadius.radiusFull,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Choose a location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Search a place, use your current location, or pick one of your recent entries.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => runSearch(setModalState),
                        decoration: InputDecoration(
                          hintText: 'Search building, street, or landmark',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              searchController.clear();
                              setModalState(() {
                                searchResults = <String>[];
                                searchError = null;
                              });
                            },
                            icon: const Icon(Icons.clear_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isSearching
                                  ? null
                                  : () async {
                                      Navigator.pop(context);
                                      await _useCurrentLocation();
                                    },
                              icon: const Icon(Icons.my_location_outlined),
                              label: const Text('Current location'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isSearching
                                  ? null
                                  : () => runSearch(setModalState),
                              icon: const Icon(Icons.travel_explore_outlined),
                              label: const Text('Search'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Recent locations',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_recentLocations.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _inputBg,
                            borderRadius: AppBorderRadius.radiusMd,
                            border: Border.all(color: _inputBorder),
                          ),
                          child: const Text(
                            'No recent locations yet. Enter a location once and it will appear here.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryLight,
                              height: 1.4,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _recentLocations
                              .map(
                                (item) => ActionChip(
                                  label: Text(
                                    item,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context, item),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 16),
                      if (isSearching)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      else if (searchError != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: AppBorderRadius.radiusMd,
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            searchError!,
                            style: const TextStyle(
                              fontSize: 13,
                                color: AppColors.error,
                              height: 1.4,
                            ),
                          ),
                        )
                      else if (searchResults.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Search results',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4A4A4A),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...searchResults.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  tileColor: const Color(0xFFF7F9FB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppBorderRadius.radiusMd,
                                    side: BorderSide(color: _border),
                                  ),
                                  leading: Icon(
                                    Icons.place_outlined,
                                    color: _primary,
                                  ),
                                  title: Text(
                                    item,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(context, item),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    searchController.dispose();

    if (location != null && location.trim().isNotEmpty) {
      final resolvedPoint = await _resolvePointFromLocationText(location);
      if (!mounted) return;
      _setLocationValue(location, point: resolvedPoint);
    }
  }

  Future<void> _showMapPicker() async {
    final searchController = TextEditingController();
    final startPoint =
        await _resolveCurrentLatLng() ?? const LatLng(13.7563, 100.5018);

    if (!mounted) {
      searchController.dispose();
      return;
    }

    final selection = await showModalBottomSheet<_LocationSearchResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final mapController = MapController();
        LatLng selectedPoint = startPoint;
        String previewLabel = 'Tap the map to choose a point.';
        bool isSearching = false;
        bool isResolving = true;
        bool hasTileLoadError = false;
        bool showSlowTileHint = false;
        bool isMapGestureActive = false;
        bool didInitResolve = false;
        Timer? slowTileHintTimer;
        List<_LocationSearchResult> searchResults = <_LocationSearchResult>[];

        Future<void> updateSelection(
          LatLng point,
          StateSetter setModalState,
        ) async {
          setModalState(() {
            selectedPoint = point;
            isResolving = true;
          });

          final label = await _resolveReadableLocationFromCoordinates(
            point.latitude,
            point.longitude,
          );

          if (!mounted) return;
          setModalState(() {
            selectedPoint = point;
            previewLabel = label;
            isResolving = false;
            showSlowTileHint = false;
          });
        }

        Future<void> runSearch(StateSetter setModalState) async {
          final query = searchController.text.trim();
          if (query.isEmpty) {
            setModalState(() {
              searchResults = <_LocationSearchResult>[];
              previewLabel = 'Type a place or address first.';
            });
            return;
          }

          setModalState(() {
            isSearching = true;
            previewLabel = 'Searching location...';
          });

          final results = await _searchLocationResults(query);
          if (!mounted) return;

          setModalState(() {
            isSearching = false;
            searchResults = results;
            if (results.isEmpty) {
              previewLabel = 'No matches found. Try a more specific place.';
              return;
            }
            selectedPoint = results.first.point;
            previewLabel = results.first.label;
            isResolving = false;
          });

          if (results.isNotEmpty) {
            mapController.move(results.first.point, 16);
          }
        }

        Future<void> useCurrentPoint(StateSetter setModalState) async {
          setModalState(() {
            previewLabel = 'Getting current location...';
            isResolving = true;
          });

          final point = await _resolveCurrentLatLng();
          if (point == null) {
            if (!mounted) return;
            setModalState(() {
              previewLabel =
                  'Unable to access GPS. Check permission or GPS settings.';
              isResolving = false;
            });
            return;
          }

          mapController.move(point, 16);
          await updateSelection(point, setModalState);
        }

        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              if (!didInitResolve) {
                didInitResolve = true;
                unawaited(updateSelection(startPoint, setModalState));
                slowTileHintTimer = Timer(const Duration(seconds: 4), () {
                  if (!mounted) return;
                  setModalState(() {
                    if (isResolving) {
                      showSlowTileHint = true;
                    }
                  });
                });
              }

              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.92,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  physics: isMapGestureActive
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7D7D7),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Pick on map',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF242424),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap a point on the map, search a place, or use your current location.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6F6F6F),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => runSearch(setModalState),
                        decoration: InputDecoration(
                          hintText: 'Search place or address',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              searchController.clear();
                              setModalState(() {
                                searchResults = <_LocationSearchResult>[];
                                previewLabel = 'Tap the map to choose a point.';
                              });
                            },
                            icon: const Icon(Icons.clear_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isSearching
                                  ? null
                                  : () => useCurrentPoint(setModalState),
                              icon: const Icon(Icons.my_location_outlined),
                              label: const Text('Current location'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isSearching
                                  ? null
                                  : () => runSearch(setModalState),
                              icon: const Icon(Icons.travel_explore_outlined),
                              label: const Text('Search'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 320,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Listener(
                                  onPointerDown: (_) {
                                    if (isMapGestureActive) return;
                                    setModalState(
                                      () => isMapGestureActive = true,
                                    );
                                  },
                                  onPointerUp: (_) {
                                    if (!isMapGestureActive) return;
                                    setModalState(
                                      () => isMapGestureActive = false,
                                    );
                                  },
                                  onPointerCancel: (_) {
                                    if (!isMapGestureActive) return;
                                    setModalState(
                                      () => isMapGestureActive = false,
                                    );
                                  },
                                  child: FlutterMap(
                                    mapController: mapController,
                                    options: MapOptions(
                                      initialCenter: selectedPoint,
                                      initialZoom: 16,
                                      onTap: (tapPosition, point) {
                                        updateSelection(point, setModalState);
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'classcare_user',
                                        errorTileCallback: (
                                          tile,
                                          error,
                                          stackTrace,
                                        ) {
                                          if (hasTileLoadError) return;
                                          setModalState(
                                            () => hasTileLoadError = true,
                                          );
                                        },
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: selectedPoint,
                                            width: 56,
                                            height: 56,
                                            child: Icon(
                                              Icons.location_pin,
                                              size: 52,
                                              color: _primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (hasTileLoadError || showSlowTileHint)
                                Positioned(
                                  left: 10,
                                  right: 10,
                                  top: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.68),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.map_outlined,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Map is loading slowly. You can still use Search or Current location.',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              height: 1.35,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE3E8EF)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.place_outlined, color: _primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isResolving
                                        ? '$previewLabel\nResolving address...'
                                        : previewLabel,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.45,
                                      color: Color(0xFF2F2F2F),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildStaticMapThumbnail(
                                    selectedPoint,
                                    height: 84,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isResolving)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Please wait for address resolution before confirming.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _primary.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (searchResults.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Search results',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...searchResults.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              tileColor: const Color(0xFFF7F9FB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              leading: Icon(
                                Icons.location_on_outlined,
                                color: _primary,
                              ),
                              title: Text(
                                item.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () {
                                setModalState(() {
                                  selectedPoint = item.point;
                                  previewLabel = item.label;
                                  isResolving = false;
                                  showSlowTileHint = false;
                                });
                                mapController.move(item.point, 16);
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                slowTileHintTimer?.cancel();
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: isResolving
                                  ? null
                                  : () {
                                      slowTileHintTimer?.cancel();
                                      Navigator.pop(
                                        context,
                                        _LocationSearchResult(
                                          label: previewLabel,
                                          point: selectedPoint,
                                        ),
                                      );
                                    },
                              child: const Text('Use this location'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    searchController.dispose();

    if (selection != null && selection.label.trim().isNotEmpty) {
      _setLocationValue(selection.label, point: selection.point);
    }
  }

  void _goNextStep() {
    if (_currentStep == 0 && !_isCategoryStepComplete) {
      _showAnimatedSnackBar('Please select a category first.');
      return;
    }
    if (_currentStep == 1 && !_isLocationStepComplete) {
      _showAnimatedSnackBar(
        'Please enter a location with at least $_minLocationChars characters.',
      );
      return;
    }
    if (_currentStep == 2 && !_isStepTwoComplete) {
      _showAnimatedSnackBar('Please provide at least $_minChars characters.');
      return;
    }
    if (_currentStep < 3) {
      setState(() {
        _stepTransitionDirection = 1;
        _currentStep++;
      });
      _scheduleDraftSave();
    }
  }

  void _goBackStep() {
    if (_currentStep > 0) {
      setState(() {
        _stepTransitionDirection = -1;
        _currentStep--;
      });
      _scheduleDraftSave();
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final images = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return;

      final validImages = <XFile>[];
      for (final image in images) {
        if (_isSupportedImageName(image.name)) {
          validImages.add(image);
        }
      }

      if (validImages.isEmpty) {
        if (mounted) {
          _showAnimatedSnackBar(
            'Only .jpg, .jpeg, and .png files are supported.',
            color: Colors.red.shade400,
          );
        }
        return;
      }

      final lengths = await Future.wait(
        validImages.map(_safeFileLength),
      );

      final acceptedImages = <XFile>[];
      final oversizedNames = <String>[];
      for (var i = 0; i < validImages.length; i++) {
        final length = lengths[i];
        final file = validImages[i];
        if (length > _maxImageBytes) {
          oversizedNames.add(file.name);
          continue;
        }
        acceptedImages.add(file);
      }

      if (acceptedImages.isEmpty) {
        if (mounted) {
          _showAnimatedSnackBar(
            'No valid images selected. Max size is ${_formatImageSizeLimit()} per file.',
            color: Colors.red.shade400,
          );
        }
        return;
      }

      final bytesList = await Future.wait(
        acceptedImages.map((image) => image.readAsBytes()),
      );

      if (!mounted) return;
      setState(() {
        _selectedImageBytes.addAll(bytesList);
        _selectedImageNames.addAll(acceptedImages.map((image) => image.name));
      });
      if (oversizedNames.isNotEmpty && mounted) {
        _showFileSizeError(oversizedNames);
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        _showAnimatedSnackBar(
          'Unable to select images.',
          color: Colors.red.shade400,
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    if (!_isNativeCameraSupported) {
      if (mounted) {
        _showAnimatedSnackBar(
          'Camera is supported on Android/iOS only. This platform will use file selection instead.',
          color: Colors.orange.shade700,
        );
      }
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image == null) return;

      if (!_isSupportedImageName(image.name)) {
        if (mounted) {
          _showAnimatedSnackBar(
            'Only .jpg, .jpeg, and .png files are supported.',
            color: Colors.red.shade400,
          );
        }
        return;
      }

      final length = await _safeFileLength(image);
      if (length > _maxImageBytes) {
        if (mounted) {
          _showAnimatedSnackBar(
            'Selected image is too large. Max size is ${_formatImageSizeLimit()}.',
            color: Colors.red.shade400,
          );
        }
        return;
      }

      final bytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImageBytes.add(bytes);
        _selectedImageNames.add(image.name);
      });
    } catch (e) {
      debugPrint('Camera capture error: $e');
      if (mounted) {
        _showAnimatedSnackBar(
          'Unable to open the camera.',
          color: Colors.red.shade400,
        );
      }
    }
  }

  void _removeImageAt(int index) {
    setState(() {
      _selectedImageBytes.removeAt(index);
      _selectedImageNames.removeAt(index);
    });
  }

  Future<List<String>> _uploadImagesIfNeeded() async {
    if (_selectedImageBytes.isEmpty) return const [];

    final supabase = Supabase.instance.client;
    final auth = supabase.auth;
    final currentUser = auth.currentUser;
    final userRole = auth.currentSession?.user.role ?? 'unknown';
    final uploadedUrls = <String>[];

    // Log upload context
    debugPrint('[ReportPage.upload] ===== IMAGE UPLOAD START =====');
    debugPrint('[ReportPage.upload] imageCount=${_selectedImageBytes.length}');
    debugPrint('[ReportPage.upload] currentUser=$currentUser');
    debugPrint('[ReportPage.upload] userRole=$userRole');
    debugPrint('[ReportPage.upload] bucket=${AppStorageBuckets.reportImages}');
    debugPrint('[ReportPage.upload] ===============================');

    setState(() => _isUploadingImage = true);
    try {
      final batchTs = DateTime.now().microsecondsSinceEpoch;
      final uploadTasks = _selectedImageBytes.asMap().entries.map((entry) async {
        final i = entry.key;
        final bytes = entry.value;
        final safeName = (_selectedImageNames[i]).replaceAll(
          RegExp(r'[^A-Za-z0-9._-]'),
          '_',
        );
        final storagePath = 'reports/${batchTs}_${i}_$safeName';

        debugPrint(
          '[ReportPage.upload] Uploading image $i: $storagePath (${bytes.length} bytes)',
        );
        try {
          await supabase.storage
              .from(AppStorageBuckets.reportImages)
              .uploadBinary(
                storagePath,
                bytes,
                fileOptions: const FileOptions(upsert: true),
              );
          debugPrint('[ReportPage.upload] Image $i upload succeeded');
        } catch (uploadError) {
          debugPrint('[ReportPage.upload] Image $i upload FAILED: $uploadError');
          rethrow;
        }

        return supabase.storage.from(AppStorageBuckets.reportImages).getPublicUrl(storagePath);
      });

      uploadedUrls.addAll(await Future.wait(uploadTasks));
      return uploadedUrls;
    } catch (e) {
      debugPrint('[ReportPage.upload] CATCH - Upload error type: ${e.runtimeType}');
      debugPrint('[ReportPage.upload] CATCH - Full error: $e');
      if (e.toString().contains('403')) {
        debugPrint('[ReportPage.upload] ERROR CODE: 403 Unauthorized detected');
      }
      throw _ImageUploadException(_toImageUploadUserMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  String _toImageUploadUserMessage(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('403') || raw.contains('unauthorized') || raw.contains('permission')) {
      return 'Image upload failed (403 permission denied). Please sign in again or contact an administrator.';
    }
    if (raw.contains('timeout') || raw.contains('socket') || raw.contains('network')) {
      return 'Image upload failed due to network instability. Please try again.';
    }
    return 'Image upload failed. Please try again.';
  }

  Future<bool> _confirmSubmitWithoutImages(String reason) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Image Upload Failed'),
          content: Text('$reason\n\nDo you want to submit this report without attachments?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Retry'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Submit Without Attachments'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _submitReportWithImageUrls({
    required String message,
    required String location,
    required List<String> imageUrls,
  }) async {
    final aiResult = await AIService.submitReport(
      description: message,
      location: location,
      category: _selectedCategory!,
      imageUrls: imageUrls,
    );

    if (!aiResult.isAccepted ||
        aiResult.trackingId == null ||
        aiResult.trackingId!.isEmpty) {
      debugPrint(
        '[ReportPage] Submit rejected. '
        'isAccepted=${aiResult.isAccepted}, '
        'trackingId=${aiResult.trackingId ?? '-'}, '
        'isQueued=${aiResult.isQueued}, '
        'message=${aiResult.message ?? '-'}',
      );
      if (!mounted) return;
      _showAnimatedSnackBar(
        aiResult.message ?? 'Your report could not be submitted.',
      );
      return;
    }

    final tId = aiResult.trackingId!;
    debugPrint(
      '[ReportPage] Submit success. trackingId=$tId, isQueued=${aiResult.isQueued}',
    );

    if (!mounted) return;
    await _saveRecentTrackingId(tId);
    await _clearDraft();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      _buildFadeSlideRoute(
        SuccessPage(
          trackingId: tId,
          isQueued: aiResult.isQueued,
          message: aiResult.message,
        ),
      ),
    );
  }

  Future<void> _handleOnSubmit() async {
    if (_isSubmitting || _isUploadingImage) return;

    final message = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    final locationPayload = _buildLocationPayloadForSubmit(location);
    if (!_canSubmit) return;

    // Log session/auth context for diagnostics
    final supabase = Supabase.instance.client;
    final auth = supabase.auth;
    final currentUser = auth.currentUser;
    final currentSession = auth.currentSession;
    final userRole = currentSession?.user.role ?? 'unknown';
    final isSignedIn = currentUser != null;
    final userId = currentUser?.id ?? 'N/A';
    final userEmail = currentUser?.email ?? 'N/A';

    debugPrint('[ReportPage.submit] ===== SUBMIT START =====');
    debugPrint('[ReportPage.submit] isSignedIn=$isSignedIn');
    debugPrint('[ReportPage.submit] userRole=$userRole');
    debugPrint('[ReportPage.submit] userId=$userId');
    debugPrint('[ReportPage.submit] userEmail=$userEmail');
    debugPrint('[ReportPage.submit] currentUser=$currentUser');
    debugPrint('[ReportPage.submit] sessionExpiry=${currentSession?.expiresAt}');
    debugPrint('[ReportPage.submit] =====================');

    setState(() => _isSubmitting = true);

    try {
      final imageUrls = await _uploadImagesIfNeeded();
      await _submitReportWithImageUrls(
        message: message,
        location: locationPayload,
        imageUrls: imageUrls,
      );
    } on _ImageUploadException catch (e) {
      debugPrint('[ReportPage.submit] ImageUploadException caught: ${e.userMessage}');
      if (!mounted) return;
      final shouldContinue = await _confirmSubmitWithoutImages(e.userMessage);
      debugPrint('[ReportPage.submit] User chose to continue without images: $shouldContinue');
      if (!shouldContinue) return;

      await _submitReportWithImageUrls(
        message: message,
        location: locationPayload,
        imageUrls: const [],
      );
    } catch (e) {
      debugPrint("Submit Error: $e");
      if (mounted) {
        _showAnimatedSnackBar(
          'Something went wrong. Please try again.',
          color: Colors.red.shade400,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  PageRouteBuilder<void> _buildFadeSlideRoute(Widget page) {
    return PageRouteBuilder<void>(
      transitionDuration: MotionTokens.medium,
      reverseTransitionDuration: MotionTokens.medium,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: MotionTokens.entranceCurve,
        );
        final slide =
            Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: MotionTokens.entranceCurve,
              ),
            );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  void _showAnimatedSnackBar(String message, {Color? color}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 0,
        duration: const Duration(milliseconds: 2200),
        backgroundColor: color ?? _primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 280),
          tween: Tween(begin: 12, end: 0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: Opacity(
                opacity: (1 - (value / 12)).clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Text(message, style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: widget.showBottomNav
          ? ClasscareBottomNav(
              current: ClasscareTab.report,
              onHomeTap: () {
                if (widget.onTabSelected != null) {
                  widget.onTabSelected!(ClasscareTab.home);
                  return;
                }
                Navigator.push(
                  context,
                  _buildFadeSlideRoute(const HomePage()),
                );
              },
              onTrackTap: () {
                if (widget.onTabSelected != null) {
                  widget.onTabSelected!(ClasscareTab.track);
                  return;
                }
                Navigator.push(
                  context,
                  _buildFadeSlideRoute(const TrackPage()),
                );
              },
            )
          : null,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildAnonymousBadge(),
                    const SizedBox(height: 24),
                    _buildStepHeader(),
                    const SizedBox(height: 20),
                    _buildStepContent(),
                    const SizedBox(height: 26),
                    _buildStepControls(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      leading: IconButton(
        tooltip: 'Back',
        icon: Semantics(
          button: true,
          label: 'Back',
          hint: 'Go to previous page',
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        onPressed: _handleTopBack,
      ),
      actions: [
        IconButton(
          tooltip: 'Clear Draft',
          onPressed: () async {
            if (!_hasDraftLikeContent) {
              _showAnimatedSnackBar('No draft data to clear.');
              return;
            }
            final confirmed = await _confirmClearDraft();
            if (!confirmed) return;
            _descriptionController.clear();
            _locationController.clear();
            setState(() {
              _selectedCategory = null;
              _currentStep = 0;
              _charCount = 0;
              _draftHint = 'Draft cleared. Start a new report anytime.';
            });
            await _clearDraft();
            if (!mounted) return;
            _showAnimatedSnackBar('Draft cleared.');
          },
          icon: Semantics(
            button: true,
            label: 'Clear draft',
            hint: 'Remove all current report draft fields',
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restart_alt, size: 16, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          "New Report",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB23A3A), Color(0xFF992F2F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.edit_note_rounded,
                size: 90,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTopBack() async {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(ClasscareTab.home);
      return;
    }

    final popped = await Navigator.maybePop(context);
    if (!popped && mounted) {
      Navigator.pushReplacement(
        context,
        _buildFadeSlideRoute(const HomePage()),
      );
    }
  }

  Widget _buildStepHeader() {
    final steps = [
      ('Category', Icons.sell_outlined),
      ('Location', Icons.pin_drop_outlined),
      ('Details', Icons.description_outlined),
      ('Review', Icons.verified_outlined),
    ];
    final progress = (_currentStep + 1) / steps.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.drafts_outlined, color: _primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _draftHint,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Step ${_currentStep + 1} of ${steps.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: _primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B6B6B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildAnimatedStepProgressBar(steps.length),
          const SizedBox(height: 14),
          _buildStepTimeline(steps),
        ],
      ),
    );
  }

  Widget _buildStepTimeline(List<(String, IconData)> steps) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 390;

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: List.generate(steps.length, (index) {
                  final item = steps[index];
                  final bool active = index == _currentStep;
                  final bool complete = index < _currentStep;
                  final color = complete || active
                      ? _primary
                      : const Color(0xFFB5B5B5);

                  return Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: (complete || active)
                                        ? _primary.withValues(alpha: active ? 0.16 : 0.1)
                                        : const Color(0xFFF2F2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: complete || active
                                          ? _primary
                                          : const Color(0xFFD6D6D6),
                                    ),
                                  ),
                                  child: Icon(
                                    complete ? Icons.check : item.$2,
                                    size: 16,
                                    color: color,
                                  ),
                                ),
                              ),
                            ),
                            if (index < steps.length - 1)
                              Container(
                                width: 14,
                                height: 2,
                                margin: const EdgeInsets.only(right: 2),
                                color: index < _currentStep
                                    ? _primary.withValues(alpha: 0.55)
                                    : const Color(0xFFD9D9D9),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          );
        }

        return Row(
          children: List.generate(steps.length, (index) {
            final item = steps[index];
            final bool active = index == _currentStep;
            final bool complete = index < _currentStep;
            final color = complete || active ? _primary : const Color(0xFFB5B5B5);

            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: (complete || active)
                          ? _primary.withValues(alpha: active ? 0.16 : 0.1)
                          : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: complete || active ? _primary : const Color(0xFFD6D6D6),
                      ),
                    ),
                    child: Icon(
                      complete ? Icons.check : item.$2,
                      size: 18,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Container(
                      width: 16,
                      height: 2,
                      margin: const EdgeInsets.only(right: 6),
                      color: index < _currentStep
                          ? _primary.withValues(alpha: 0.55)
                          : const Color(0xFFD9D9D9),
                    ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildAnimatedStepProgressBar(int totalSteps) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final bool complete = index < _currentStep;
            final bool current = index == _currentStep;

            return Expanded(
              child: AnimatedContainer(
                duration: MotionTokens.fast,
                curve: Curves.easeOut,
                height: current ? 8 : 6,
                margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: (complete || current)
                      ? LinearGradient(
                          colors: [
                            _primary.withValues(alpha: complete ? 0.95 : 0.82),
                            _primary.withValues(alpha: complete ? 0.75 : 0.55),
                          ],
                        )
                      : null,
                  color: (complete || current)
                      ? null
                      : (isLight
                          ? AppColors.borderSubtleLight
                          : AppColors.borderSubtleDark),
                  boxShadow: current
                      ? [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            final bool reached = index <= _currentStep;
            return AnimatedContainer(
              duration: MotionTokens.fast,
              width: reached ? 8 : 6,
              height: reached ? 8 : 6,
              decoration: BoxDecoration(
                color: reached
                    ? _primary.withValues(alpha: 0.8)
                  : (isLight
                        ? AppColors.borderSubtleLight
                        : AppColors.borderSubtleDark),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    late final Widget stepContent;
    if (_currentStep == 0) {
      stepContent = Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Category', required: true),
          const SizedBox(height: 16),
          _buildCategoryGrid(),
        ],
      );
    } else if (_currentStep == 1) {
      stepContent = Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Location', required: true),
          const SizedBox(height: 8),
          Text(
            'Minimum $_minLocationChars characters. Add building, floor, or area.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF7A7A7A),
            ),
          ),
          const SizedBox(height: 10),
          _buildLocationField(),
        ],
      );
    } else if (_currentStep == 2) {
      stepContent = Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Image attachment', required: false),
          const SizedBox(height: 8),
          _buildImageAttachmentSection(),
          const SizedBox(height: 24),
          _buildSectionLabel('Description', required: true),
          const SizedBox(height: 8),
          const Text(
            'Minimum 20 characters. Please describe what happened clearly.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF7A7A7A),
            ),
          ),
          const SizedBox(height: 10),
          _buildDescriptionField(),
        ],
      );
    } else {
      stepContent = KeyedSubtree(
        key: const ValueKey(3),
        child: _buildReviewCard(),
      );
    }

    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final duration = disableAnimations ? Duration.zero : MotionTokens.medium;

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: MotionTokens.entranceCurve,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        final beginOffset = _stepTransitionDirection >= 0
            ? const Offset(0.08, 0)
            : const Offset(-0.08, 0);
        final positionAnimation = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: MotionTokens.entranceCurve),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: positionAnimation, child: child),
        );
      },
      child: stepContent,
    );
  }

  Widget _buildReviewCard() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFFFFCFB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: const Color(0xFFE9DDDB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  color: _primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick checklist',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF262626),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Please verify each item before you submit.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF6F6F6F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildChecklistItem(
            'Category',
            _selectedCategory ?? '-',
            icon: Icons.sell_outlined,
            isComplete: _isCategoryStepComplete,
          ),
          _buildChecklistItem(
            'Category detail',
            _selectedCategoryDetail,
            icon: Icons.notes_outlined,
            isComplete: _isCategoryStepComplete,
          ),
          _buildChecklistItem(
            'Location',
            _formattedLocationForReview,
            icon: Icons.place_outlined,
            isComplete: _isLocationStepComplete,
          ),
          if (_selectedLocationPoint != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBFD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4EBF3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location preview',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5F6B7A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStaticMapThumbnail(
                    _selectedLocationPoint!,
                    height: 110,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFD9AF)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF8A6116),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No map preview is available because this location was entered manually.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xFF7A5513),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          _buildChecklistItem(
            'Attachments',
            _attachmentSummary,
            icon: Icons.attach_file_outlined,
            isComplete: _hasImages,
            isLast: true,
          ),
          const SizedBox(height: 14),
          AppInfoBanner(
            icon: Icons.timelapse_rounded,
            title: 'Review note',
            message:
                'Most reports receive a first status update within 24 hours.',
            backgroundColor: const Color(0xFFFFF8E8),
            borderColor: const Color(0xFFEFD9AF),
            iconColor: const Color(0xFF8A6116),
            textColor: const Color(0xFF7A5513),
          ),
          const SizedBox(height: 10),
          AppPillBadge(
            label: _selectedCategory == null
                ? 'NO CATEGORY SELECTED'
                : _selectedCategory!.toUpperCase(),
            icon: Icons.fact_check_outlined,
            backgroundColor: const Color(0xFFF7F2F2),
            foregroundColor: _primary,
          ),
          const SizedBox(height: 10),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
    String label,
    String value, {
    required IconData icon,
    bool? isComplete,
    bool isLast = false,
  }) {
    final normalized = value.trim().toLowerCase();
    final resolvedIsComplete =
        isComplete ??
        (normalized.isNotEmpty && normalized != '-' && normalized != 'no attachments');

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0E6E4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: _primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A7170),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Color(0xFF242424),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              resolvedIsComplete
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: resolvedIsComplete
                  ? Colors.green.shade600
                  : const Color(0xFFB6ADA9),
            ),
          ],
        ),
      ),
    );
  }

  String get _selectedCategoryDetail {
    if (_selectedCategory == null) return '-';

    final match = _categories.firstWhere(
      (category) => category['name'] == _selectedCategory,
      orElse: () => <String, dynamic>{},
    );
    final detail = match['desc'] as String?;
    if (detail == null || detail.trim().isEmpty) {
      return _selectedCategory!;
    }

    return detail;
  }

  String get _formattedLocationForReview {
    final location = _locationController.text.trim();
    if (location.isEmpty) return '-';

    final normalized = location.toLowerCase();
    if (normalized.startsWith('lat ') && normalized.contains(', lng ')) {
      return 'Coordinates: $location';
    }

    return location;
  }

  String get _attachmentSummary {
    if (_selectedImageNames.isEmpty) {
      return 'No attachments';
    }

    final names = _selectedImageNames.take(2).toList();
    final remainingCount = _selectedImageNames.length - names.length;
    final shownNames = names.join(', ');

    if (remainingCount <= 0) {
      return shownNames;
    }

    return '$shownNames +$remainingCount more';
  }

  Widget _buildStepControls() {
    if (_currentStep == 3) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _goBackStep,
              icon: const Icon(Icons.arrow_back_ios_new, size: 14),
              label: const Text('Back to Edit'),
            ),
          ),
        ],
      );
    }

    final canContinue = _canAdvanceCurrentStep;

    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _goBackStep,
              icon: const Icon(Icons.arrow_back_ios_new, size: 14),
              label: const Text('Back'),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canContinue ? _goNextStep : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(_currentStep == 2 ? 'Review Report' : 'Continue'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              disabledBackgroundColor: const Color(0xFFF2DADA),
              disabledForegroundColor: const Color(0xFFA67979),
            ),
          ),
        ),
      ],
    );
  }

  // ── Anonymous Badge ───────────────────────────────────────

  Widget _buildAnonymousBadge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1EAEA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lock_outline, color: _primary, size: 18),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "100% Anonymous",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF232323),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "No personal data is collected or stored.",
                  style: TextStyle(fontSize: 14, color: Color(0xFF6E6E6E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────

  Widget _buildSectionLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF242424),
          ),
        ),
        if (required) ...[
          const SizedBox(width: 8),
          Text(
            "*",
            style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  // ── Category Selection ────────────────────────────────────

  Widget _buildCategoryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;

        return Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFF0F0F0)),
          ),
          padding: const EdgeInsets.all(16),
          child: isCompact
              ? Column(
                  children: [
                    for (var index = 0; index < _categories.length; index++) ...[
                      _buildCategoryCard(
                        _categories[index],
                        isCompact: true,
                      ),
                      if (index != _categories.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.12,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryCard(
                      _categories[index],
                      isCompact: false,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> cat, {
    required bool isCompact,
  }) {
    final name = cat['name'] as String;
    final desc = cat['desc'] as String;
    final detail = cat['detail'] as String;
    final isSelected = _selectedCategory == name;

    return _PressableScale(
      semanticLabel: 'Select category $name',
      semanticHint: isSelected
          ? 'Category is already selected'
          : 'Sets report category to $name',
      tooltip: 'Select $name',
      onTap: () {
        setState(() => _selectedCategory = name);
        _scheduleDraftSave();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primary : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: isCompact
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primary
                          : const Color(0xFF8A95A8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      size: 20,
                      color: isSelected ? Colors.white : const Color(0xFF6D6D6D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: isSelected
                                      ? _primary
                                      : const Color(0xFF242424),
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: detail,
                              onPressed: () => _showCategoryDetailSheet(
                                name: name,
                                desc: desc,
                                detail: detail,
                              ),
                              icon: Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: isSelected
                                    ? _primary
                                    : const Color(0xFF8A8A8A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? _primary.withValues(alpha: 0.78)
                                : const Color(0xFF666666),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          detail,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: isSelected
                                ? _primary.withValues(alpha: 0.7)
                                : const Color(0xFF7A7A7A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              )
            : Stack(
                children: [
                  if (isSelected)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primary
                                  : const Color(0xFF8A95A8)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              size: 20,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF6D6D6D),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          color: isSelected
                                              ? _primary
                                              : const Color(0xFF242424),
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
                                      tooltip: detail,
                                      onPressed: () => _showCategoryDetailSheet(
                                        name: name,
                                        desc: desc,
                                        detail: detail,
                                      ),
                                      icon: Icon(
                                        Icons.info_outline_rounded,
                                        size: 18,
                                        color: isSelected
                                            ? _primary
                                            : const Color(0xFF8A8A8A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  desc,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? _primary.withValues(alpha: 0.72)
                                        : const Color(0xFF8A8A8A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  detail,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.35,
                                    color: isSelected
                                        ? _primary.withValues(alpha: 0.64)
                                        : const Color(0xFF7E7E7E),
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isSelected ? 'Selected' : 'Tap to select',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? _primary
                              : const Color(0xFF8B8B8B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showCategoryDetailSheet({
    required String name,
    required String desc,
    required String detail,
  }) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _divider,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF242424),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6F6F6F),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE3E8EF)),
                    ),
                    child: Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF2F2F2F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticMapThumbnail(LatLng point, {double height = 84}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'classcare_user',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 34,
                          height: 34,
                          child: Icon(
                            Icons.location_pin,
                            size: 30,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE3E8EF)),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _formatCoordinates(point.latitude, point.longitude),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Location Field ────────────────────────────────────────

  Widget _buildLocationField() {
    final isFocused = _locationFocus.hasFocus;
    return AnimatedContainer(
      duration: MotionTokens.fastMedium,
      curve: MotionTokens.entranceCurve,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? _primary : const Color(0xFFE8E8E8),
          width: isFocused ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isFocused
                ? _primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isFocused ? 14 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _locationController,
            focusNode: _locationFocus,
            onChanged: (_) {
              if (_isProgrammaticLocationUpdate) return;
              setState(() {
                _selectedLocationPoint = null;
              });
            },
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Building, floor, or area...',
              hintStyle: const TextStyle(
                color: Color(0xFFA0A0A0),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: _primary,
                size: 20,
              ),
              suffixIcon: IconButton(
                tooltip: 'Choose location',
                onPressed: _showLocationPicker,
                icon: Icon(Icons.tune_rounded, color: _primary, size: 20),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location_outlined, size: 18),
                  label: const Text('Current location'),
                ),
                OutlinedButton.icon(
                  onPressed: _showMapPicker,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Pick on map'),
                ),
              ],
            ),
          ),
          if (_selectedLocationPoint != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildStaticMapThumbnail(
                _selectedLocationPoint!,
                height: 90,
              ),
            ),
          ],
          if (_recentLocations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentLocations.take(3).map((item) {
                  return ActionChip(
                    label: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () async {
                      final resolvedPoint = await _resolvePointFromLocationText(item);
                      if (!mounted) return;
                      _setLocationValue(item, point: resolvedPoint);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Image Attachment ─────────────────────────────────────

  Widget _buildImageAttachmentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageActionRow(),
          if (_hasImages) ...[
            const SizedBox(height: 12),
            _buildImagePreviewGrid(),
          ],
          const SizedBox(height: 12),
          Text(
            'Optional: attach one or more photos. Allowed types: JPG, JPEG, PNG.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageActionRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose from gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _isNativeCameraSupported ? _takePhoto : null,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(
              _isNativeCameraSupported
                  ? 'Open camera'
                  : 'Open camera (mobile only)',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: BorderSide(color: _primary.withValues(alpha: 0.35)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreviewGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedImageBytes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.98,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Image.memory(
                    _selectedImageBytes[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedImageNames[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2A2A2A),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Remove image',
                      hint: 'Removes this attached image from the report',
                      child: IconButton(
                        tooltip: 'Remove image',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => _removeImageAt(index),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Description Field ─────────────────────────────────────

  Widget _buildDescriptionField() {
    final bool isUnder = _charCount < _minChars;
    final Color charColor = _charCount == 0
        ? const Color(0xFF8D8D8D)
        : isUnder
        ? const Color(0xFFB97A19)
        : _charCount > _maxChars
        ? const Color(0xFFC62828)
        : const Color(0xFF2E7D32);
    final isFocused = _descriptionFocus.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: MotionTokens.fastMedium,
          curve: MotionTokens.entranceCurve,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused ? _primary : const Color(0xFFE8E8E8),
              width: isFocused ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isFocused
                    ? _primary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isFocused ? 14 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            maxLines: 6,
            maxLength: _maxChars,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => const SizedBox.shrink(),
            decoration: InputDecoration(
              hintText:
                  "Describe the incident in detail...\n\nWhat happened? When did it occur?",
              hintStyle: const TextStyle(
                color: Color(0xFFA0A0A0),
                fontSize: 14,
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_charCount > 0 && _charCount < _minChars)
              Text(
                "${_minChars - _charCount} more characters needed",
                style: const TextStyle(fontSize: 14, color: Color(0xFFB97A19)),
              )
            else
              const SizedBox(),
            Text(
              "$_charCount / $_maxChars",
              style: TextStyle(
                fontSize: 14,
                color: charColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Submit Button ─────────────────────────────────────────

  Widget _buildSubmitButton() {
    return IgnorePointer(
      ignoring: _isSubmitting || _isUploadingImage,
      child: AnimatedOpacity(
        opacity: _canSubmit ? 1.0 : 0.55,
        duration: const Duration(milliseconds: 250),
        child: _PressableScale(
          enabled: _canSubmit,
          semanticLabel: 'Submit report',
          semanticHint: 'Send this report to moderation',
          tooltip: 'Submit report',
          onTap: _canSubmit ? _handleOnSubmit : null,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _canSubmit ? _handleOnSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _canSubmit ? 4 : 0,
                shadowColor: _primary.withValues(alpha: 0.28),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _isUploadingImage
                    ? const Row(
                        key: ValueKey('uploading-image'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Uploading photo...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : _isSubmitting
                    ? _buildLoadingLabel()
                    : const Row(
                        key: ValueKey('submit'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Submit Report",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingLabel() {
    return AnimatedBuilder(
      key: const ValueKey('loading'),
      animation: _loadingAnimController,
      builder: (context, child) {
        final t = _loadingAnimController.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Submitting",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(3, (index) {
              final phase = (t + index * 0.2) % 1;
              final opacity =
                  0.3 + (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.7;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Opacity(
                  opacity: opacity,
                  child: const Icon(Icons.circle, size: 6, color: Colors.white),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final String? semanticLabel;
  final String? semanticHint;
  final String? tooltip;

  const _PressableScale({
    required this.child,
    this.onTap,
    this.enabled = true,
    this.semanticLabel,
    this.semanticHint,
    this.tooltip,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1;

  void _setPressed(bool pressed) {
    if (!widget.enabled) return;
    setState(() => _scale = pressed ? 0.97 : 1);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );

    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }

    if (widget.semanticLabel != null) {
      child = Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.semanticLabel!,
        hint: widget.semanticHint,
        child: child,
      );
    }

    return child;
  }
}
