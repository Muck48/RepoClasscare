import 'package:flutter/material.dart';
import 'package:classcare_user/theme/app_design_tokens.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    final bg = AppColors.bgByTheme(brightness);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Semantics(
              button: true,
              label: 'Go back',
              hint: 'Returns to the previous page',
              child: Tooltip(
                message: 'Back',
                child: IconButton(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: isLight ? 0.12 : 0.28),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'About ClassCare',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.shield_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, 'Our Mission'),
                  _contentText(
                    context,
                    'ClassCare exists to lower the barriers between witnessing a problem and institutional response. We believe many concerns go unreported due to fear of retaliation, social consequences, or the burden of formal processes.',
                  ),
                  const SizedBox(height: 30),
                  _sectionTitle(context, 'The Problem We Are Addressing'),
                  _problemCard(
                    context,
                    title: 'Fear of Retaliation',
                    desc: "Students worry about academic consequences or being labeled as 'difficult'.",
                    icon: Icons.shutter_speed_rounded,
                  ),
                  _problemCard(
                    context,
                    title: 'Process Intimidation',
                    desc: 'Formal complaints require meetings and statements, which can be overwhelming for those already stressed.',
                    icon: Icons.gavel_rounded,
                  ),
                  _problemCard(
                    context,
                    title: 'Uncertainty of Impact',
                    desc: "Students often do not know whether their concern qualifies for formal reporting.",
                    icon: Icons.help_outline_rounded,
                  ),
                  const SizedBox(height: 30),
                  _sectionTitle(context, 'How We Help'),
                  _featureItem(
                    context,
                    title: 'Early Warning System',
                    desc: 'Identify concerning patterns before they escalate.',
                  ),
                  _featureItem(
                    context,
                    title: 'Capturing Unreported Incidents',
                    desc: "Capture issues that often go unreported because they do not feel serious enough.",
                  ),
                  _featureItem(
                    context,
                    title: 'Psychological Safety',
                    desc: 'Knowing this system exists signals institutional commitment to listening.',
                  ),
                  const SizedBox(height: 30),
                  _sectionTitle(context, 'What Success Looks Like'),
                  _successCheck(context, 'Early intervention in systemic issues.'),
                  _successCheck(context, 'Reduced time between incident and awareness.'),
                  _successCheck(context, 'Data-driven policy changes.'),
                  const SizedBox(height: 40),
                  _contactCard(context),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryByTheme(Theme.of(context).brightness),
        ),
      ),
    );
  }

  Widget _contentText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        color: AppColors.textSecondaryByTheme(Theme.of(context).brightness),
        height: 1.6,
      ),
    );
  }

  Widget _problemCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
  }) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceByTheme(brightness),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderByTheme(brightness)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimaryByTheme(brightness),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryByTheme(brightness),
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

  Widget _featureItem(
    BuildContext context, {
    required String title,
    required String desc,
  }) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.stars_rounded, color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimaryByTheme(brightness),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryByTheme(brightness),
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

  Widget _successCheck(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryByTheme(Theme.of(context).brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Text(
            'Contact & Feedback',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          _contactItem(Icons.email_outlined, '6731503013@lamduan.mfu.ac.th'),
          const SizedBox(height: 12),
          _contactItem(Icons.support_agent_rounded, 'MFU Student Support'),
        ],
      ),
    );
  }

  Widget _contactItem(IconData icon, String text) {
    return MergeSemantics(
      child: Semantics(
        container: true,
        label: text,
        child: Tooltip(
          message: text,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.warning, size: 18),
              const SizedBox(width: 12),
              SelectableText(
                text,
                style: TextStyle(
                  color: Color(0xFFF2F4F8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
