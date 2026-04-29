import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import 'report_page.dart';
import 'track_page.dart';
import 'widgets/classcare_bottom_nav.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = ClasscareTab.home});

  final ClasscareTab initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  double _contentOpacity = 1;
  DateTime? _lastBackPressedAt;

  @override
  void initState() {
    super.initState();
    _currentIndex = _tabToIndex(widget.initialTab);
  }

  int _tabToIndex(ClasscareTab tab) {
    switch (tab) {
      case ClasscareTab.home:
        return 0;
      case ClasscareTab.report:
        return 1;
      case ClasscareTab.track:
        return 2;
    }
  }

  Future<void> _switchToTab(ClasscareTab tab) async {
    final nextIndex = _tabToIndex(tab);
    if (nextIndex == _currentIndex) return;

    setState(() => _contentOpacity = 0);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() {
      _currentIndex = nextIndex;
      _contentOpacity = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentIndex != 0) {
          _switchToTab(ClasscareTab.home);
          return;
        }

        final now = DateTime.now();
        final shouldExit =
            _lastBackPressedAt != null &&
            now.difference(_lastBackPressedAt!) < const Duration(seconds: 2);

        if (shouldExit) {
          SystemNavigator.pop();
          return;
        }

        _lastBackPressedAt = now;
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        body: AnimatedOpacity(
          opacity: _contentOpacity,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: IndexedStack(
            index: _currentIndex,
            children: [
              HomePage(
                showBottomNav: false,
                onTabSelected: _switchToTab,
              ),
              ReportPage(
                showBottomNav: false,
                onTabSelected: _switchToTab,
              ),
              TrackPage(
                showBottomNav: false,
                onTabSelected: _switchToTab,
              ),
            ],
          ),
        ),
        bottomNavigationBar: ClasscareBottomNav(
          current: ClasscareTab.values[_currentIndex],
          onHomeTap: () => _switchToTab(ClasscareTab.home),
          onReportTap: () => _switchToTab(ClasscareTab.report),
          onTrackTap: () => _switchToTab(ClasscareTab.track),
        ),
      ),
    );
  }
}
