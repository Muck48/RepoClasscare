import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:classcare_user/theme/motion_tokens.dart';
import 'widgets/classcare_bottom_nav.dart';
import 'home_page.dart';
import 'report_page.dart';
import 'track_page.dart';

class SuccessPage extends StatefulWidget {
  final String trackingId;
  final bool isQueued;
  final String? decision;
  final String? closeReason;
  final String? message;

  const SuccessPage({
    super.key,
    required this.trackingId,
    this.isQueued = false,
    this.decision,
    this.closeReason,
    this.message,
  });

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _cardController;
  late final AnimationController _pulseController;
  late final AnimationController _confettiController;

  late final Animation<double> _checkScale;
  late final Animation<double> _checkOpacity;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _pulseAnim;
  late final List<_ConfettiParticle> _confettiParticles;

  bool _isCopied = false;
  bool _isNavigating = false;
  Timer? _cardEntranceTimer;

  static const String _supportEmail = '6731503013@lamduan.mfu.ac.th';

  static const Color _bg = Color(0xFFF8F8F8);

  Color get _primary => Theme.of(context).primaryColor;

  bool get _isAutoClosed => widget.decision?.toUpperCase() == 'CLOSED';
  bool get _isQueued => widget.isQueued;
  bool get _shouldCelebrate => !_isQueued && !_isAutoClosed;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: MotionTokens.verySlow,
    );
    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutBack,
    ).drive(Tween(begin: 0.7, end: 1.0));
    _checkOpacity = CurvedAnimation(parent: _checkController, curve: Curves.easeOut);

    _cardController = AnimationController(
      vsync: this,
      duration: MotionTokens.standard,
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardController, curve: MotionTokens.entranceCurve));
    _cardOpacity = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    final random = math.Random();
    _confettiParticles = List.generate(42, (index) {
      const palette = [
        Color(0xFFFFE082),
        Color(0xFFFFCC80),
        Color(0xFFFFAB91),
        Color(0xFFB3E5FC),
        Color(0xFFC5E1A5),
      ];
      return _ConfettiParticle(
        startX: random.nextDouble(),
        endYFactor: 0.55 + random.nextDouble() * 0.4,
        size: 5 + random.nextDouble() * 6,
        spinTurns: 0.5 + random.nextDouble() * 1.8,
        delay: random.nextDouble() * 0.35,
        phase: random.nextDouble() * math.pi * 2,
        color: palette[random.nextInt(palette.length)],
      );
    });
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    _checkController.forward();
    if (_shouldCelebrate) {
      _confettiController.forward();
    } else {
      _confettiController.value = 1;
    }
    _cardEntranceTimer = Timer(MotionTokens.fastMedium, () {
      if (mounted) _cardController.forward();
    });
  }

  @override
  void dispose() {
    _cardEntranceTimer?.cancel();
    if (_pulseController.isAnimating) {
      _pulseController.stop(canceled: true);
    }
    _checkController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _navigateOnce(VoidCallback navigationAction) {
    if (!mounted || _isNavigating) return;
    setState(() => _isNavigating = true);
    if (_pulseController.isAnimating) {
      _pulseController.stop(canceled: true);
    }
    navigationAction();
  }

  void _goHome() {
    _navigateOnce(() {
      Navigator.pushAndRemoveUntil(
        context,
        _route(const HomePage()),
        (route) => false,
      );
    });
  }

  void _goToTrackPrefilled() {
    _navigateOnce(() {
      Navigator.push(
        context,
        _route(TrackPage(initialTrackingId: widget.trackingId)),
      );
    });
  }

  void _submitNewReport() {
    _navigateOnce(() {
      Navigator.pushAndRemoveUntil(
        context,
        _route(const ReportPage()),
        (route) => false,
      );
    });
  }

  void _contactSupport() {
    Clipboard.setData(const ClipboardData(text: _supportEmail));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Support email copied: $_supportEmail'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.trackingId));
    setState(() => _isCopied = true);
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: ClasscareBottomNav(
        current: ClasscareTab.home,
        onReportTap: () => Navigator.pushReplacement(
          context,
          _route(const ReportPage()),
        ),
        onTrackTap: () => Navigator.pushReplacement(
          context,
          _route(TrackPage(initialTrackingId: widget.trackingId)),
        ),
      ),
      body: Stack(
        children: [
          if (_shouldCelebrate)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ConfettiPainter(
                        progress: _confettiController.value,
                        particles: _confettiParticles,
                      ),
                    );
                  },
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.42,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB23A3A), Color(0xFF942F2F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -60,
                    right: -40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(180),
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(120),
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _PressableScale(
                      onTap: _goHome,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.42)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
                            SizedBox(width: 8),
                            Text(
                              'Home',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ScaleTransition(
                  scale: _checkScale,
                  child: FadeTransition(
                    opacity: _checkOpacity,
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: _pulseAnim.value,
                              child: Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(104),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.24),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(80),
                                color: Colors.white.withOpacity(0.15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.32),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _checkOpacity,
                  child: Column(
                    children: [
                      Text(
                        _isQueued
                            ? 'Saved Offline'
                            : _isAutoClosed
                                ? 'Report Auto-Closed'
                                : 'Report Submitted!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.message ??
                            (_isQueued
                                ? 'Your report has been saved on this device and will sync automatically when the connection returns.'
                                : _isAutoClosed
                                    ? 'This report was automatically closed by moderation policy.'
                                    : 'We have received your report successfully.'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SlideTransition(
                    position: _cardSlide,
                    child: FadeTransition(
                      opacity: _cardOpacity,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                          child: Column(
                            children: [
                              if (_isAutoClosed) ...[
                                _buildAutoCloseReasonCard(),
                                const SizedBox(height: 16),
                                _buildAutoCloseActionsCard(),
                                const SizedBox(height: 16),
                              ],
                              _buildTrackingCard(),
                              const SizedBox(height: 24),
                              _buildWhatHappensNextCard(),
                              const SizedBox(height: 16),
                              _PressableScale(
                                onTap: _copyToClipboard,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 240),
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: _isCopied
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF3F9B46),
                                              Color(0xFF2B7A31),
                                            ],
                                          )
                                        : const LinearGradient(
                                            colors: [Color(0xFFB23A3A), Color(0xFF8B2D2D)],
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isCopied ? Colors.green : _primary)
                                            .withOpacity(0.28),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 220),
                                        child: Icon(
                                          _isCopied
                                              ? Icons.check_circle_outline
                                              : Icons.copy_all_outlined,
                                          key: ValueKey(_isCopied),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 220),
                                        child: Text(
                                          _isCopied ? 'Copied!' : 'Copy Tracking ID',
                                          key: ValueKey(_isCopied ? 'copied' : 'copy'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _PressableScale(
                                onTap: _goToTrackPrefilled,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton.icon(
                                    onPressed: _goToTrackPrefilled,
                                    icon: const Icon(Icons.track_changes_outlined, size: 20),
                                    label: const Text(
                                      'Track with This ID',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF303030),
                                      side: const BorderSide(
                                        color: Color(0xFFD6D6D6),
                                        width: 1.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _PressableScale(
                                onTap: _goHome,
                                child: TextButton.icon(
                                  onPressed: _goHome,
                                  icon: const Icon(Icons.home_outlined, size: 18),
                                  label: const Text(
                                    'Back to Home',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: _primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Your Tracking ID',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF242424),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.trackingId,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _primary,
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isQueued ? const Color(0xFFEAF3FF) : const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isQueued ? const Color(0xFFB7D4FF) : const Color(0xFFF0E0B8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isQueued ? Icons.cloud_upload_outlined : Icons.info_outline,
                  color: _isQueued ? const Color(0xFF2E6FB3) : const Color(0xFF8C6315),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isQueued
                        ? 'Offline saved. Auto-sync is pending. Tap "Track with This ID" after reconnecting to confirm it is synced.'
                        : 'Save this ID. You will need it for status tracking.',
                    style: TextStyle(
                      color: _isQueued ? const Color(0xFF2E6FB3) : const Color(0xFF7E5A15),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  Widget _buildAutoCloseReasonCard() {
    final reason = widget.closeReason?.trim().isNotEmpty == true
        ? widget.closeReason!.trim()
        : 'เข้าข่ายสแปมหรือเนื้อหาไม่เป็นประโยชน์ต่อการดำเนินการ';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB23A3A).withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gpp_maybe_outlined, color: Color(0xFFB23A3A), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-close reason',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF8B2626),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    color: Color(0xFF6E1F1F),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatHappensNextCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_outlined, size: 18, color: Color(0xFF2F2F2F)),
              SizedBox(width: 8),
              Text(
                'What happens next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2A2A2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildNextItem(
            icon: _isQueued ? Icons.save_outlined : Icons.cloud_done_outlined,
            title: _isQueued ? 'Saved on Device' : 'Submitted',
            subtitle: _isQueued
                ? 'Your report is stored locally until internet is available.'
                : 'Your report is safely recorded in the system.',
          ),
          _buildNextItem(
            icon: _isQueued ? Icons.sync_outlined : Icons.manage_search_rounded,
            title: _isQueued ? 'Waiting to Sync' : 'Moderation Review',
            subtitle: _isQueued
                ? 'Once reconnected, syncing starts automatically in the background.'
                : 'The team validates report quality and urgency.',
          ),
          _buildNextItem(
            icon: _isQueued
                ? Icons.track_changes_outlined
                : Icons.notifications_active_outlined,
            title: _isQueued ? 'Confirm Sync in Track' : 'Status Update',
            subtitle: _isQueued
                ? 'Use "Track with This ID" after reconnecting to see live status.'
                : 'Most cases receive a first update within 24 hours.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAutoCloseActionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5D7D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What would you like to do next?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submitNewReport,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Submit New Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7B2626),
                    side: const BorderSide(color: Color(0xFFD9BABA)),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _contactSupport,
                  icon: const Icon(Icons.support_agent_outlined, size: 18),
                  label: const Text('Contact Support'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B2D2D),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: _primary, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F2F2F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PageRouteBuilder<void> _route(Widget page) {
    return PageRouteBuilder<void>(
      transitionDuration: MotionTokens.medium,
      reverseTransitionDuration: MotionTokens.medium,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(parent: animation, curve: MotionTokens.entranceCurve);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: MotionTokens.entranceCurve));
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1;

  void _setPressed(bool pressed) {
    setState(() => _scale = pressed ? 0.97 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
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
  }
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.startX,
    required this.endYFactor,
    required this.size,
    required this.spinTurns,
    required this.delay,
    required this.phase,
    required this.color,
  });

  final double startX;
  final double endYFactor;
  final double size;
  final double spinTurns;
  final double delay;
  final double phase;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress, required this.particles});

  final double progress;
  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    for (final particle in particles) {
      final local = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final eased = Curves.easeOutCubic.transform(local);
      final xDrift = math.sin((eased * math.pi * 3) + particle.phase) * (10 + particle.size);
      final x = particle.startX * size.width + xDrift;
      final yStart = -36 - particle.size;
      final yEnd = size.height * particle.endYFactor;
      final y = yStart + (yEnd - yStart) * eased;
      final rotation = particle.spinTurns * local * math.pi * 2;
      final opacity = (1 - local * 0.45).clamp(0.0, 1.0);

      final paint = Paint()..color = particle.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 1.35,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.particles != particles;
  }
}
