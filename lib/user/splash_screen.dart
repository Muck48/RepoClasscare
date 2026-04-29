import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_shell.dart';
import 'privacy_intro_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
  with SingleTickerProviderStateMixin {
  static const Duration _minimumSplashDuration = Duration(milliseconds: 1800);
  static const String _logoAsset = 'assets/images/logo.png';

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.93,
      end: 1,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    _entranceController.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    final navigator = Navigator.of(context);
    final prefsFuture = SharedPreferences.getInstance();
    final warmupFuture = _warmUpAssets();
    final minDelayFuture = Future<void>.delayed(_minimumSplashDuration);

    // Run startup work in parallel, but always keep a minimum splash duration.
    await Future.wait<void>([prefsFuture.then((_) {}), warmupFuture, minDelayFuture]);
    if (!mounted) return;

    final prefs = await prefsFuture;
    final hasAcceptedPrivacy =
        prefs.getBool(PrivacyIntroPage.privacyAcceptedKey) ?? false;

    final nextPage = hasAcceptedPrivacy ? const AppShell() : const PrivacyIntroPage();

    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  Future<void> _warmUpAssets() async {
    try {
      await precacheImage(const AssetImage(_logoAsset), context);
    } catch (_) {
      // Ignore missing asset here; build will render fallback branding safely.
    }
  }

  Widget _buildLogoFallback() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          colors: [Color(0xFFB23A3A), Color(0xFF8F2E2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB23A3A).withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.shield_rounded,
            color: Colors.white,
            size: 58,
          ),
          SizedBox(height: 10),
          Text(
            'ClassCare',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Secure reporting',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinner() {
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.red.shade700,
              ),
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: Colors.red.shade700.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCopy() {
    return Column(
      children: const [
        Text(
          'Preparing your workspace',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6A6A6A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Checking privacy status and loading assets',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF8A8A8A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.asset(
                      _logoAsset,
                      width: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildLogoFallback();
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ClassCare',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF242424),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLoadingCopy(),
                  const SizedBox(height: 14),
                  _buildSpinner(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
