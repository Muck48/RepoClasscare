import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:classcare_user/theme/app_design_tokens.dart';
import 'widgets/app_surfaces.dart';
import 'widgets/classcare_bottom_nav.dart';
import 'widgets/pressable_scale.dart';
import 'about_page.dart';
import 'report_page.dart';
import 'track_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.showBottomNav = true,
    this.onTabSelected,
  });

  final bool showBottomNav;
  final ValueChanged<ClasscareTab>? onTabSelected;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _skeletonController;
  final _supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activitySectionKey = GlobalKey();
  Timer? _activityAutoRefreshTimer;

  bool _activityLoading = true;
  bool _hasLoadedActivityOnce = false;
  String? _activityError;
  DateTime? _lastUpdatedAt;
  int _submittedCount = 0;
  int _reviewedCount = 0;
  int _resolvedCount = 0;

    Color get _pageBg => AppColors.bgByTheme(Theme.of(context).brightness);

    Color get _pageSurface =>
      AppColors.surfaceByTheme(Theme.of(context).brightness);

    Color get _pageTextPrimary =>
      AppColors.textPrimaryByTheme(Theme.of(context).brightness);

    Color get _pageTextSecondary =>
      AppColors.textSecondaryByTheme(Theme.of(context).brightness);

    Color get _pageBorder => AppColors.borderByTheme(Theme.of(context).brightness);

      Color get _primary => AppColors.primary;

    Color get _pageButtonBg =>
      Theme.of(context).brightness == Brightness.light
        ? AppColors.buttonBgLight
        : AppColors.buttonBgDark;

    Color get _pageTintAnonymous =>
      Theme.of(context).brightness == Brightness.light
        ? AppColors.tintAnonymousLight
        : AppColors.tintAnonymousDark;

    Color get _pageTintTrackable =>
      Theme.of(context).brightness == Brightness.light
        ? AppColors.tintTrackableLight
        : AppColors.tintTrackableDark;

    Color get _pageTintSecure =>
      Theme.of(context).brightness == Brightness.light
        ? AppColors.tintSecureLight
        : AppColors.tintSecureDark;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MotionTokens.verySlow,
    )..forward();
    _skeletonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _loadSystemActivity();
    _activityAutoRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (!mounted) return;
        _loadSystemActivity(silent: true);
      },
    );
  }

  @override
  void dispose() {
    _activityAutoRefreshTimer?.cancel();
    _entryController.dispose();
    _skeletonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _showPageSkeleton => _activityLoading && !_hasLoadedActivityOnce;

  String get _greeting {
    final hour = DateTime.now().toLocal().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _relativeUpdatedText(DateTime updatedAt) {
    final diff = DateTime.now().toLocal().difference(updatedAt.toLocal());
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return 'Updated $minutes min ago';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return 'Updated $hours hr ago';
    }
    final days = diff.inDays;
    return 'Updated $days day${days == 1 ? '' : 's'} ago';
  }

  Future<void> _scrollToActivityCard() async {
    final context = _activitySectionKey.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: MotionTokens.medium,
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _openAboutPage() {
    Navigator.push(
      context,
      _route(const AboutPage()),
    );
  }

  Future<void> _loadSystemActivity({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _activityLoading = true;
        _activityError = null;
      });
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = now.month == 12
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);

    try {
      final rows = await _supabase
          .from('reports')
          .select('status, created_at')
          .gte('created_at', monthStart.toIso8601String())
          .lt('created_at', nextMonthStart.toIso8601String());

      int reviewed = 0;
      int resolved = 0;
      for (final row in rows) {
        final raw = (row['status'] ?? '').toString().toUpperCase().trim();
        if (raw == 'IN REVIEW' || raw == 'INREVIEW') reviewed++;
        if (raw == 'RESOLVED' ||
            raw == 'SUCCESS' ||
            raw == 'DONE' ||
            raw == 'CLOSED') {
          resolved++;
        }
      }

      if (!mounted) return;
      setState(() {
        _submittedCount = rows.length;
        _reviewedCount = reviewed;
        _resolvedCount = resolved;
        _lastUpdatedAt = DateTime.now().toLocal();
        _hasLoadedActivityOnce = true;
        _activityLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activityError = 'Unable to load live stats';
        _hasLoadedActivityOnce = true;
        _activityLoading = false;
      });
    }
  }

  Widget _buildFeatureHighlights() {
    return Row(
      children: [
        Expanded(
          child: _featureCard(
            icon: Icons.shield_outlined,
            title: 'Anonymous',
            subtitle: 'No identity\ntracked',
            tint: _pageTintAnonymous,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _featureCard(
            icon: Icons.location_on_outlined,
            title: 'Trackable',
            subtitle: 'Live updates',
            tint: _pageTintTrackable,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _featureCard(
            icon: Icons.lock_outline,
            title: 'Secure',
            subtitle: 'End-to-end\nsafe',
            tint: _pageTintSecure,
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyTipsCard() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(1.2),
      borderRadius: AppBorderRadius.radiusXl,
      gradient: LinearGradient(
        colors: Theme.of(context).brightness == Brightness.light
            ? const [Color(0xFFF1DEDE), Color(0xFFE9E9E9)]
            : const [Color(0xFF3A2C2C), Color(0xFF2A2A2A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: _pageSurface,
          borderRadius: AppBorderRadius.radiusLg,
          border: Border.all(color: _pageBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How It Works',
              style: AppTypography.heading4.copyWith(
                color: _pageTextPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            _stepRow(number: '1', text: 'Submit your report anonymously'),
            SizedBox(height: AppSpacing.sm),
            _stepRow(number: '2', text: 'Moderators review and update status'),
            SizedBox(height: AppSpacing.sm),
            _stepRow(number: '3', text: 'Track progress anytime from Track page'),
          ],
        ),
      ),
    );
  }

  Widget _stepRow({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.12),
            borderRadius: AppBorderRadius.radiusFull,
          ),
          child: Text(
            number,
            style: TextStyle(
                color: _primary,
              fontSize: 12,
              fontWeight: AppTypography.weightExtraBold,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: _pageTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tint,
  }) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(1.2),
      borderRadius: AppBorderRadius.radiusLg,
      gradient: LinearGradient(
        colors: Theme.of(context).brightness == Brightness.light
            ? const [Color(0xFFF2DCDC), Color(0xFFE9E9E9)]
            : const [Color(0xFF3A2C2C), Color(0xFF2A2A2A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
        decoration: BoxDecoration(
          color: _pageSurface,
          borderRadius: AppBorderRadius.radiusLg,
        ),
        child: Column(
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.16),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppBorderRadius.sm),
                  bottomRight: Radius.circular(AppBorderRadius.sm),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: AppBorderRadius.radiusMd,
              ),
              child: Icon(icon, size: 20, color: _primary),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _pageTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _pageTextSecondary,
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(1.2),
      borderRadius: AppBorderRadius.radiusXl,
      gradient: LinearGradient(
        colors: Theme.of(context).brightness == Brightness.light
            ? const [Color(0xFFF1DEDE), Color(0xFFE9E9E9)]
            : const [Color(0xFF3A2C2C), Color(0xFF2A2A2A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _pageSurface,
          borderRadius: AppBorderRadius.radiusLg,
          border: Border.all(color: _pageBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'System Activity',
                    style: TextStyle(
                      color: _pageTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Text(
                  'This Month',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                PressableScale(
                  borderRadius: AppBorderRadius.radiusSm,
                  semanticLabel: 'Refresh system activity',
                  semanticHint: 'Loads the latest moderation numbers',
                  tooltip: 'Refresh activity',
                  onTap: _loadSystemActivity,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _pageButtonBg,
                      borderRadius: AppBorderRadius.radiusSm,
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
            if (_lastUpdatedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                _relativeUpdatedText(_lastUpdatedAt!),
                style: TextStyle(
                  color: _pageTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_activityLoading)
              _buildActivityLoadingSkeleton()
            else if (_activityError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: AppBorderRadius.radiusMd,
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _activityError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _loadSystemActivity,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(92, 42),
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: AppMetricTile(
                      value: '$_submittedCount',
                      label: 'Submitted',
                      subtitle: 'This month',
                      accentColor: _primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppMetricTile(
                      value: '$_reviewedCount',
                      label: 'Reviewed',
                      subtitle: 'This month',
                      accentColor: _primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppMetricTile(
                      value: '$_resolvedCount',
                      label: 'Resolved',
                      subtitle: 'This month',
                      accentColor: _primary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLoadingSkeleton() {
    return Row(
      children: [
        Expanded(
          child: _skeletonBox(
            height: 74,
            borderRadius: 14,
            phase: 0.0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _skeletonBox(
            height: 74,
            borderRadius: 14,
            phase: 0.18,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _skeletonBox(
            height: 74,
            borderRadius: 14,
            phase: 0.36,
          ),
        ),
      ],
    );
  }

  Widget _buildPageSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Row(
            children: [
              _skeletonBox(height: 44, width: 44, borderRadius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(height: 16, width: 140, borderRadius: 7),
                    const SizedBox(height: 6),
                    _skeletonBox(height: 12, width: 120, borderRadius: 7),
                  ],
                ),
              ),
              _skeletonBox(height: 26, width: 58, borderRadius: 99),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: _skeletonBox(height: 42, borderRadius: 14, phase: 0.08),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: _skeletonBox(height: 36, borderRadius: 999, phase: 0.1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _skeletonBox(height: 36, borderRadius: 999, phase: 0.22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _skeletonBox(height: 36, borderRadius: 999, phase: 0.34),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
          child: AppSurfaceCard(
            padding: const EdgeInsets.all(1.2),
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [AppColors.heroGradientTop, AppColors.heroGradientBottom],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _skeletonBox(height: 44, width: 44, borderRadius: 14),
                      const Spacer(),
                      _skeletonBox(
                        height: 26,
                        width: 130,
                        borderRadius: 99,
                        phase: 0.15,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _skeletonBox(
                    height: 18,
                    width: 235,
                    borderRadius: 7,
                    phase: 0.08,
                  ),
                  const SizedBox(height: 8),
                  _skeletonBox(
                    height: 18,
                    width: 200,
                    borderRadius: 7,
                    phase: 0.2,
                  ),
                  const SizedBox(height: 12),
                  _skeletonBox(
                    height: 14,
                    width: double.infinity,
                    borderRadius: 7,
                    phase: 0.3,
                  ),
                  const SizedBox(height: 6),
                  _skeletonBox(
                    height: 14,
                    width: 265,
                    borderRadius: 7,
                    phase: 0.42,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _skeletonBox(
                          height: 54,
                          borderRadius: 16,
                          base: Colors.white.withValues(alpha: 0.25),
                          highlight: Colors.white.withValues(alpha: 0.45),
                          phase: 0.12,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _skeletonBox(
                          height: 54,
                          borderRadius: 16,
                          base: Colors.white.withValues(alpha: 0.18),
                          highlight: Colors.white.withValues(alpha: 0.34),
                          phase: 0.28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: _skeletonBox(
            height: 60,
            borderRadius: 16,
            phase: 0.12,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: _skeletonBox(
                  height: 132,
                  borderRadius: 17,
                  phase: 0.0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _skeletonBox(
                  height: 132,
                  borderRadius: 17,
                  phase: 0.16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _skeletonBox(
                  height: 132,
                  borderRadius: 17,
                  phase: 0.32,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: _skeletonBox(
            height: 148,
            borderRadius: 19,
            phase: 0.22,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: _skeletonBox(
            height: 128,
            borderRadius: 19,
            phase: 0.34,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: _skeletonBox(
            height: 124,
            borderRadius: 19,
            phase: 0.46,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    return _reveal(
      0.0,
      0.18,
      AppSurfaceCard(
        padding: const EdgeInsets.all(1.2),
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppColors.heroGradientTop, AppColors.heroGradientBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -35,
              right: -35,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(140),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(120),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.report_gmailerrorred_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Text(
                          'Anonymous by design',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Report issues without revealing who you are.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 22 : 26,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Submit a report, check its status, and follow live moderation activity from one place.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: PressableScale(
                          borderRadius: BorderRadius.circular(18),
                          splashColor: _primary.withValues(alpha: 0.2),
                          highlightColor: _primary.withValues(alpha: 0.1),
                          hapticType: HapticType.medium,
                          semanticLabel: 'Start report',
                          semanticHint: 'Open the report form',
                          tooltip: 'Start report',
                          onTap: () {
                            if (widget.onTabSelected != null) {
                              widget.onTabSelected!(ClasscareTab.report);
                              return;
                            }
                            Navigator.push(
                              context,
                              _route(const ReportPage(showBottomNav: false)),
                            );
                          },
                          child: Container(
                            height: 68,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _pageSurface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withValues(alpha: 0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  color: _primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Start Report',
                                  style: TextStyle(
                                    color: _primary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PressableScale(
                          borderRadius: BorderRadius.circular(18),
                          splashColor: Colors.white.withValues(alpha: 0.25),
                          highlightColor: Colors.white.withValues(alpha: 0.15),
                          hapticType: HapticType.light,
                          semanticLabel: 'Track case',
                          semanticHint: 'Open tracking page',
                          tooltip: 'Track case',
                          onTap: () {
                            if (widget.onTabSelected != null) {
                              widget.onTabSelected!(ClasscareTab.track);
                              return;
                            }
                            Navigator.push(
                              context,
                              _route(const TrackPage(showBottomNav: false)),
                            );
                          },
                          child: Container(
                            height: 68,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Track Case',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final textSize = compact ? 10.5 : 12.0;

          Widget pill(
            IconData icon,
            String text, {
            VoidCallback? onTap,
            String? semanticHint,
          }) {
            final content = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8F8), Color(0xFFFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFEAD8D8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: compact ? 13 : 14, color: const Color(0xFFB23A3A)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        maxLines: 1,
                        style: TextStyle(
                          color: const Color(0xFF6B5252),
                          fontSize: textSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (onTap == null) {
              return Expanded(child: content);
            }

            return Expanded(
              child: PressableScale(
                borderRadius: BorderRadius.circular(999),
                semanticLabel: text,
                semanticHint: semanticHint,
                onTap: onTap,
                child: content,
              ),
            );
          }

          return Row(
            children: [
              pill(Icons.visibility_off_outlined, 'Anonymous'),
              const SizedBox(width: 8),
              pill(Icons.verified_outlined, 'Verified'),
              const SizedBox(width: 8),
              pill(
                Icons.bolt_outlined,
                'Live Status',
                onTap: _scrollToActivityCard,
                semanticHint: 'Scroll to the activity card',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _skeletonBox({
    required double height,
    double? width,
    double borderRadius = 12,
    Color? base,
    Color? highlight,
    double phase = 0,
  }) {
    final baseColor = base ?? const Color(0xFFECECEC);
    final highlightColor = highlight ?? const Color(0xFFF7F7F7);

    return AnimatedBuilder(
      animation: _skeletonController,
      builder: (context, child) {
        final animated = (_skeletonController.value + phase) % 1.0;
        final t = Curves.easeInOut.transform(animated);
        final color = Color.lerp(baseColor, highlightColor, t) ?? baseColor;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }

  Widget _reveal(double begin, double end, Widget child) {
    final animation = CurvedAnimation(
      parent: _entryController,
      curve: Interval(begin, end, curve: MotionTokens.entranceCurve),
    );

    final offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(animation);

    return SlideTransition(
      position: offset,
      child: FadeTransition(
        opacity: animation.drive(Tween(begin: 0.0, end: 1.0)),
        child: child,
      ),
    );
  }

  PageRouteBuilder<void> _route(Widget page) {
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

  Widget _buildAmbientBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFAFA), Color(0xFFF6F0F0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -100,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(280),
              color: const Color(0xFFD96A6A).withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          top: 170,
          left: -80,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(220),
              color: const Color(0xFF8D2D2D).withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -60,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(190),
              color: const Color(0xFFB94A4A).withValues(alpha: 0.08),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC24747), Color(0xFF9B3434)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B3434).withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    color: Color(0xFF2B2222),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Your safe reporting space',
                  style: TextStyle(
                    color: Color(0xFF756363),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          PressableScale(
            borderRadius: BorderRadius.circular(999),
            semanticLabel: 'About privacy and moderation',
            semanticHint: 'Opens privacy and moderation information',
            tooltip: 'About privacy',
            onTap: _openAboutPage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _pageSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _pageBorder),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: _pageTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2A2020),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7A6767),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFFCB5555), Color(0xFFA33B3B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      bottomNavigationBar: widget.showBottomNav
          ? ClasscareBottomNav(
              current: ClasscareTab.home,
              onReportTap: () {
                if (widget.onTabSelected != null) {
                  widget.onTabSelected!(ClasscareTab.report);
                  return;
                }
                Navigator.push(
                  context,
                  _route(const ReportPage(showBottomNav: false)),
                );
              },
              onTrackTap: () {
                if (widget.onTabSelected != null) {
                  widget.onTabSelected!(ClasscareTab.track);
                  return;
                }
                Navigator.push(
                  context,
                  _route(const TrackPage(showBottomNav: false)),
                );
              },
            )
          : null,
      body: Stack(
        children: [
          _buildAmbientBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadSystemActivity,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: AnimatedSwitcher(
                  duration: MotionTokens.medium,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _showPageSkeleton
                      ? KeyedSubtree(
                          key: const ValueKey('home_skeleton'),
                          child: _buildPageSkeleton(),
                        )
                      : KeyedSubtree(
                          key: const ValueKey('home_content'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopHeader(),
                              _buildSignalStrip(),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                                child: _buildHeroCard(),
                              ),
                              _sectionTitle('Features', 'What makes ClassCare different'),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                                child: _reveal(
                                  0.28,
                                  0.50,
                                  _buildFeatureHighlights(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                                child: _reveal(
                                  0.42,
                                  0.62,
                                  _buildSafetyTipsCard(),
                                ),
                              ),
                              _sectionTitle('Live Moderation', 'Transparent monthly overview'),
                              Padding(
                                key: _activitySectionKey,
                                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                                child: _reveal(
                                  0.54,
                                  0.78,
                                  _buildActivityCard(),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

