import 'package:flutter/material.dart';
import 'app_surfaces.dart';

enum ClasscareTab { home, report, track }

class ClasscareBottomNav extends StatelessWidget {
  final ClasscareTab current;
  final VoidCallback? onHomeTap;
  final VoidCallback? onReportTap;
  final VoidCallback? onTrackTap;

  const ClasscareBottomNav({
    super.key,
    required this.current,
    this.onHomeTap,
    this.onReportTap,
    this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: AppSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E1E1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          child: Row(
            children: [
              Expanded(
                child: _item(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  active: current == ClasscareTab.home,
                  activeColor: primary,
                  onTap: current == ClasscareTab.home ? null : onHomeTap,
                ),
              ),
              Expanded(
                child: _item(
                  icon: Icons.edit_note_outlined,
                  label: 'Report',
                  active: current == ClasscareTab.report,
                  activeColor: primary,
                  onTap: current == ClasscareTab.report ? null : onReportTap,
                ),
              ),
              Expanded(
                child: _item(
                  icon: Icons.search_outlined,
                  label: 'Track',
                  active: current == ClasscareTab.track,
                  activeColor: primary,
                  onTap: current == ClasscareTab.track ? null : onTrackTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    required VoidCallback? onTap,
  }) {
    final color = active ? activeColor : const Color(0xFF8A95A8);
    final semanticLabel = '$label tab';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? activeColor.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Semantics(
        button: true,
        selected: active,
        label: semanticLabel,
        hint: active ? 'Current tab' : 'Switch to $label tab',
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: active ? 0.1 : 0,
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
}
