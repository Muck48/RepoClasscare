import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:classcare_user/theme/app_design_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/app_constants.dart';
import 'widgets/classcare_bottom_nav.dart';
import 'widgets/pressable_scale.dart';
import 'home_page.dart';
import 'report_page.dart';
import 'track_result_page.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({
    super.key,
    this.showBottomNav = true,
    this.onTabSelected,
    this.initialTrackingId,
  });

  final bool showBottomNav;
  final ValueChanged<ClasscareTab>? onTabSelected;
  final String? initialTrackingId;

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final supabase = Supabase.instance.client;

  late final AnimationController _loadingDotsController;
  bool _isLoading = false;
  List<String> _recentTrackingIds = [];

  Brightness get _brightness => Theme.of(context).brightness;
  bool get _isLight => _brightness == Brightness.light;
  Color get _bg => AppColors.bgByTheme(_brightness);
  Color get _surface => AppColors.surfaceByTheme(_brightness);
  Color get _primary => AppColors.primary;
  Color get _textPrimary => AppColors.textPrimaryByTheme(_brightness);
  Color get _textSecondary => AppColors.textSecondaryByTheme(_brightness);
  Color get _border => AppColors.borderByTheme(_brightness);
  Color get _headerStart => AppColors.primary;
  Color get _headerEnd => _isLight ? AppColors.primaryDark : AppColors.primaryLight;

  Color get _cardShadow => Colors.black.withValues(alpha: _isLight ? 0.06 : 0.3);
  Color get _hintText => _isLight ? AppColors.textTertiaryLight : AppColors.textTertiaryDark;

  Color get _prefilledInfoBg =>
      _isLight ? AppColors.infoLight.withValues(alpha: 0.26) : AppColors.infoDark.withValues(alpha: 0.26);
  Color get _prefilledInfoBorder =>
      _isLight ? AppColors.infoLight.withValues(alpha: 0.8) : AppColors.info.withValues(alpha: 0.45);
  Color get _prefilledInfoText => _isLight ? AppColors.infoDark : AppColors.infoLight;

  Color get _defaultInfoBg =>
      _isLight ? AppColors.warningLight.withValues(alpha: 0.35) : AppColors.warningDark.withValues(alpha: 0.32);
  Color get _defaultInfoBorder =>
      _isLight ? AppColors.warningLight.withValues(alpha: 0.85) : AppColors.warning.withValues(alpha: 0.45);
  Color get _defaultInfoText => _isLight ? AppColors.warningDark : AppColors.warningLight;

  String _friendlyErrorMessage(Object error) {
    if (error is PostgrestException) {
      return 'Unable to retrieve tracking status right now. Please try again shortly.';
    }
    if (error is AuthException) {
      return 'Authentication issue detected. Please sign in again and retry.';
    }
    if (error is TimeoutException) {
      return 'Connection timed out. Please check your internet and try again.';
    }
    return 'Unable to check status right now. Please try again.';
  }

  void _logTrack(String message) {
    debugPrint('[TrackPage] $message');
  }

  @override
  void initState() {
    super.initState();
    _loadingDotsController = AnimationController(
      vsync: this,
      duration: MotionTokens.standard,
    )..repeat();
    _focusNode.addListener(() => setState(() {}));
    final initialTrackingId = widget.initialTrackingId?.trim().toUpperCase();
    if (initialTrackingId != null && initialTrackingId.isNotEmpty) {
      _controller.text = initialTrackingId;
    }
    _loadRecentTrackingIds();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _loadingDotsController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final trackingId = _controller.text.trim().toUpperCase();
    if (trackingId.isEmpty) {
      _logTrack('Validation failed: empty tracking ID input.');
      return;
    }

    final trackingPattern = RegExp(r'^ANG-\d{4}-[A-Z0-9]{6}$');
    if (!trackingPattern.hasMatch(trackingId)) {
      _logTrack('Validation failed: invalid format for "$trackingId".');
      _showAnimatedSnackBar(
        'Invalid format. Example: ANG-2026-AB12CD',
        color: AppColors.warningDark,
      );
      return;
    }

    _controller.text = trackingId;
    _logTrack('Lookup started for tracking_id="$trackingId".');

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? data = await supabase
          .from('reports')
          .select()
          .eq('tracking_id', trackingId)
          .maybeSingle();

      if (data == null) {
        _logTrack(
          'Exact match not found for "$trackingId". Trying case-insensitive fallback query.',
        );
        data = await supabase
            .from('reports')
            .select()
            .ilike('tracking_id', trackingId)
            .maybeSingle();
      }

      setState(() => _isLoading = false);

      if (data != null) {
        final matchedId = data['tracking_id']?.toString() ?? '(missing tracking_id field)';
        _logTrack('Lookup success: found record with tracking_id="$matchedId".');
        await _saveRecentTrackingId(trackingId);
        if (!mounted) return;
        Navigator.push(context, _route(TrackResultPage(reportData: data)));
      } else {
        _logTrack(
          'Lookup failed: no report row found for "$trackingId" after exact and fallback query.',
        );
        if (!mounted) return;
        _showAnimatedSnackBar('Tracking ID not found. Please try again.');
      }
    } catch (e) {
      _logTrack('Lookup error for "$trackingId": $e');
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showAnimatedSnackBar(_friendlyErrorMessage(e), color: AppColors.error);
    }
  }

  Future<void> _loadRecentTrackingIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(AppPrefsKeys.recentTrackingIds) ?? <String>[];
    if (!mounted) return;
    setState(() => _recentTrackingIds = ids);
  }

  Future<void> _saveRecentTrackingId(String trackingId) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = [
      trackingId,
      ..._recentTrackingIds.where((id) => id != trackingId),
    ].take(5).toList();
    await prefs.setStringList(AppPrefsKeys.recentTrackingIds, updated);
    if (!mounted) return;
    setState(() => _recentTrackingIds = updated);
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
          curve: MotionTokens.entranceCurve,
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
              current: ClasscareTab.track,
              onHomeTap: () {
                if (widget.onTabSelected != null) {
                  widget.onTabSelected!(ClasscareTab.home);
                  return;
                }
                Navigator.push(
                  context,
                  _route(const HomePage()),
                );
              },
              onReportTap: () {
                if (widget.onTabSelected != null) {
                  widget.onTabSelected!(ClasscareTab.report);
                  return;
                }
                Navigator.push(
                  context,
                  _route(const ReportPage()),
                );
              },
            )
          : null,
      body: Stack(
        children: [
          _buildAmbientBackground(),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                _buildMainContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientBackground() {
    return Stack(
      children: [
        Positioned(
          top: 160,
          left: -70,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(220),
              color: _primary.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          top: 420,
          right: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(180),
              color: _primary.withValues(alpha: 0.04),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_headerStart, _headerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PressableScale(
            semanticLabel: 'Back to home',
            semanticHint: 'Return to home page',
            tooltip: 'Back to home',
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              _route(const HomePage()),
              (route) => false,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Back to Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Check Report Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your tracking ID to view your report progress.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _cardShadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(),
            const SizedBox(height: 24),
            Text(
              'Tracking ID',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildTrackingInput(),
            if (_recentTrackingIds.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Recent IDs',
                style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentTrackingIds
                    .map(
                      (id) => ActionChip(
                        label: Text(
                          id,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        side: BorderSide(color: _primary.withValues(alpha: 0.24)),
                        avatar: const Icon(Icons.history, size: 14),
                        onPressed: () {
                          setState(() => _controller.text = id);
                          _checkStatus();
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            _buildCheckButton(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    final hasPrefilledId = widget.initialTrackingId?.trim().isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasPrefilledId ? _prefilledInfoBg : _defaultInfoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasPrefilledId ? _prefilledInfoBorder : _defaultInfoBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: hasPrefilledId ? _prefilledInfoText : _defaultInfoText,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPrefilledId ? 'Tracking ID Prefilled' : 'Track Your Report',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color:
                        hasPrefilledId ? _prefilledInfoText : _defaultInfoText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasPrefilledId
                      ? 'This ID came from your latest submission. Tap "Check Status" to verify sync progress.'
                      : 'Use the ID you received after submission. Example: ANG-2026-XXXXXX',
                  style: TextStyle(
                    color:
                      hasPrefilledId
                        ? _prefilledInfoText.withValues(alpha: 0.9)
                        : _defaultInfoText.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingInput() {
    final isFocused = _focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? _primary : _border,
          width: isFocused ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isFocused
                ? _primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: _isLight ? 0.03 : 0.22),
            blurRadius: isFocused ? 14 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'ANG-2026-XXXXXX',
          hintStyle: TextStyle(
            color: _hintText,
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.sell_outlined, color: _primary),
        ),
      ),
    );
  }

  Widget _buildCheckButton() {
    return PressableScale(
      enabled: !_isLoading,
      semanticLabel: 'Check report status',
      semanticHint: 'Validate tracking ID and fetch report status',
      tooltip: 'Check status',
      onTap: _isLoading ? null : _checkStatus,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _checkStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            disabledBackgroundColor: _isLight
                ? AppColors.buttonDisabledLight
                : AppColors.buttonDisabledDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            shadowColor: _primary.withValues(alpha: 0.28),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _isLoading
                ? _buildLoadingLabel()
                : const Row(
                    key: ValueKey('idle'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_outlined, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Check Status',
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
      ),
    );
  }

  Widget _buildLoadingLabel() {
    return AnimatedBuilder(
      key: const ValueKey('loading'),
      animation: _loadingDotsController,
      builder: (context, child) {
        final t = _loadingDotsController.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Checking',
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

  PageRouteBuilder<void> _route(Widget page) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}

