import 'package:flutter/material.dart';
import 'widgets/app_surfaces.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const Color _primary = Color(0xFFB23A3A);
  static const Color _bg = Color(0xFFF8F8F8);
  static const Color _textStrong = Color(0xFF242424);
  static const Color _textMuted = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _textStrong,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: _textStrong,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Updated: April 24, 2026',
              style: TextStyle(
                color: _textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            AppInfoBanner(
              icon: Icons.warning_amber_rounded,
              title: 'For non-emergency use only',
              message:
                  'ClassCare is for school or campus concerns that can be reviewed after submission. If someone is in immediate danger, contact campus security or emergency services right away.',
              backgroundColor: const Color(0xFFFFF8E8),
              borderColor: const Color(0xFFE8C77E),
              iconColor: _primary,
              textColor: _textStrong,
            ),
            const SizedBox(height: 20),
            AppSurfaceCard(
              padding: const EdgeInsets.all(18),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9E2E2)),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(
                    icon: Icons.verified_user_outlined,
                    title: 'What the app sends',
                    subtitle:
                        'Only the details you choose to enter are sent with a report.',
                    accentColor: _primary,
                  ),
                  const SizedBox(height: 14),
                  _buildBulletPoint('Category and description of the issue'),
                  _buildBulletPoint('Location you enter or select on the map'),
                  _buildBulletPoint('Optional photo attachments if you add them'),
                  _buildBulletPoint('A tracking ID returned after submission'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppSurfaceCard(
              padding: const EdgeInsets.all(18),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9E2E2)),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(
                    icon: Icons.lock_outline_rounded,
                    title: 'What we do not require',
                    subtitle:
                        'You can submit without creating an account or identity profile.',
                    accentColor: _primary,
                  ),
                  const SizedBox(height: 14),
                  _buildBulletPoint('No account or login is required'),
                  _buildBulletPoint('No name, phone number, or email is required'),
                  _buildBulletPoint('No profile is created for reporting'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppSurfaceCard(
              padding: const EdgeInsets.all(18),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9E2E2)),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(
                    icon: Icons.storage_outlined,
                    title: 'Local app data',
                    subtitle:
                        'A small amount of draft data stays on your device to speed up reporting.',
                    accentColor: _primary,
                  ),
                  const SizedBox(height: 14),
                  _buildBulletPoint(
                    'Draft description, category, location, and step progress',
                  ),
                  _buildBulletPoint('Recent locations you used before'),
                  _buildBulletPoint(
                    'Recent tracking IDs so you can reopen them quickly',
                  ),
                  _buildBulletPoint(
                    'This local data can be cleared from the app at any time',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppSurfaceCard(
              padding: const EdgeInsets.all(18),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9E2E2)),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(
                    icon: Icons.photo_library_outlined,
                    title: 'Photos and uploads',
                    subtitle:
                        'Photos are optional and only uploaded when you choose to attach them.',
                    accentColor: _primary,
                  ),
                  const SizedBox(height: 14),
                  _buildBulletPoint('Photos are optional'),
                  _buildBulletPoint('Only the images you select are uploaded'),
                  _buildBulletPoint('File types are limited to JPG, JPEG, and PNG'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppSurfaceCard(
              padding: const EdgeInsets.all(18),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9E2E2)),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(
                    icon: Icons.visibility_outlined,
                    title: 'How we use your report',
                    subtitle:
                        'Reports are reviewed, assigned a tracking ID, and shown status updates in the app.',
                    accentColor: _primary,
                  ),
                  const SizedBox(height: 14),
                  _buildBulletPoint('To route the report to the right review process'),
                  _buildBulletPoint('To generate and display your tracking ID'),
                  _buildBulletPoint('To show report status updates in the app'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppSurfaceCard(
              padding: const EdgeInsets.all(18),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9E2E2)),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(
                    icon: Icons.security_outlined,
                    title: 'Data access and sharing',
                    subtitle:
                        'We keep access limited to what is needed to run the reporting flow.',
                    accentColor: _primary,
                  ),
                  const SizedBox(height: 14),
                  _buildBulletPoint('We do not sell your report data'),
                  _buildBulletPoint('We do not use ads or tracking pixels in the app'),
                  _buildBulletPoint('We only keep data needed for the reporting flow'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(
              Icons.fiber_manual_record_rounded,
              size: 11,
              color: _primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
