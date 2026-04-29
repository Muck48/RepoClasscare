import 'package:classcare_user/user/app_shell.dart';
import 'package:classcare_user/user/privacy_policy_page.dart';
import 'package:flutter/material.dart';
import 'package:classcare_user/theme/motion_tokens.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howKey = GlobalKey();
  final GlobalKey _privacyKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: MotionTokens.standardCurve,
    );
  }

  void _goHome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  void _openPrivacyPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      endDrawer: isMobile ? _buildMobileMenu() : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'ClassCare',
          style: TextStyle(
            color: Color(0xFFB23A3A),
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        actions: isMobile
            ? [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Color(0xFFB23A3A),
                    ),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ]
            : _buildDesktopNavActions(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(),
            Container(key: _featuresKey, child: _buildFeatures()),
            _buildHowItWorks(),
            _buildUrgencySection(),
            _buildTrustSignals(),
            _buildCta(),
            Container(key: _privacyKey),
            _buildFooter(),
            Container(key: _contactKey),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDesktopNavActions() {
    return [
      TextButton(
        onPressed: () => _scrollTo(_featuresKey),
        child: const Text(
          'Features',
          style: TextStyle(color: Color(0xFF4A4A4A)),
        ),
      ),
      TextButton(
        onPressed: () => _scrollTo(_howKey),
        child: const Text(
          'How it works',
          style: TextStyle(color: Color(0xFF4A4A4A)),
        ),
      ),
      TextButton(
        onPressed: _openPrivacyPage,
        child: const Text(
          'Privacy',
          style: TextStyle(color: Color(0xFF4A4A4A)),
        ),
      ),
      const SizedBox(width: 8),
      _HoverButton(label: 'Open App', filled: true, onPressed: _goHome),
      const SizedBox(width: 14),
    ];
  }

  Widget _buildMobileMenu() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const ListTile(
              title: Text(
                'ClassCare',
                style: TextStyle(
                  color: Color(0xFFB23A3A),
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded),
              title: const Text('Features'),
              onTap: () {
                Navigator.pop(context);
                _scrollTo(_featuresKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.route_rounded),
              title: const Text('How it works'),
              onTap: () {
                Navigator.pop(context);
                _scrollTo(_howKey);
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy'),
              onTap: () {
                Navigator.pop(context);
                _openPrivacyPage();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Open App'),
              onTap: () {
                Navigator.pop(context);
                _goHome();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 900;
        final maxContent = width > 1200 ? 1120.0 : width - 32;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 36 : 56,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB23A3A), Color(0xFF8B2D2D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContent),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroText(isMobile: true),
                        const SizedBox(height: 20),
                        _buildHeroImage(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildHeroText(isMobile: false)),
                        const SizedBox(width: 28),
                        SizedBox(width: 320, child: _buildHeroImage()),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroText({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: const Text(
            'AI Powered by Llama 3.3 70B',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'รายงานปัญหา\nปลอดภัย ไม่ระบุตัวตน',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 32 : 44,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'ClassCare ช่วยให้คุณรายงานปัญหาในองค์กรได้อย่างปลอดภัย ระบบ AI จะวิเคราะห์ความเร่งด่วน และติดตามสถานะได้ทุกเวลาด้วย Tracking ID',
          style: TextStyle(
            color: Colors.white.withOpacity(0.86),
            height: 1.65,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _HeroInfoChip(
              icon: Icons.shield_outlined,
              label: 'Anonymous by design',
            ),
            _HeroInfoChip(
              icon: Icons.auto_awesome_rounded,
              label: 'AI urgency scoring',
            ),
            _HeroInfoChip(
              icon: Icons.confirmation_number_outlined,
              label: 'Track with ID',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 22,
          runSpacing: 10,
          children: const [
            _HeroStat(value: '100%', label: 'Anonymous'),
            _HeroStat(value: 'AI', label: 'Auto-analysis'),
            _HeroStat(value: 'Real-time', label: 'Status tracking'),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=900&q=80',
            height: 270,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(height: 270, color: const Color(0xFF7E2B2B)),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.08),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Privacy Protected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    final cards = [
      _FeatureItem(
        icon: Icons.lock_outline_rounded,
        title: 'ไม่ต้อง Login',
        desc:
            'ไม่เก็บข้อมูลส่วนตัว ไม่มีบัญชีผู้ใช้ รายงานได้ทันทีโดยไม่ต้องกังวล',
      ),
      _FeatureItem(
        icon: Icons.auto_awesome_rounded,
        title: 'AI วิเคราะห์ความเร่งด่วน',
        desc:
        'Llama 3.3 70B ประเมิน Urgency Score 1-5 โดยอัตโนมัติ รายงานเร่งด่วนถูกจัดการก่อน',
      ),
      _FeatureItem(
        icon: Icons.confirmation_number_outlined,
        title: 'Tracking ID',
        desc:
            'ทุกรายงานมี Tracking ID ที่ไม่ซ้ำกัน ติดตามสถานะได้ตลอดเวลาโดยไม่ต้องมีบัญชี',
      ),
      _FeatureItem(
        icon: Icons.shield_moon_outlined,
        title: 'Zero-Knowledge Proof',
        desc:
            'สถาปัตยกรรมเน้นความเป็นส่วนตัวแบบไม่เปิดเผยตัวตน ลดโอกาสการเข้าถึงข้อมูลอ่อนไหว',
      ),
      _FeatureItem(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Admin Dashboard',
        desc:
            'ผู้ดูแลระบบจัดการรายงานผ่าน Dashboard พร้อม Real-time stream และอัปเดตสถานะ',
      ),
      _FeatureItem(
        icon: Icons.filter_alt_outlined,
        title: 'กรองสแปมอัตโนมัติ',
        desc:
            'AI ตรวจจับรายงานที่ไม่เหมาะสมหรือซ้ำซ้อน ป้องกันการใช้งานในทางที่ผิด',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontal = width < 700 ? 16.0 : 24.0;
        final columns = width >= 1280
            ? 4
            : width >= 1024
            ? 3
            : width >= 680
            ? 2
            : 1;

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 56, horizontal, 56),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Features',
                    style: TextStyle(
                      color: Color(0xFFB23A3A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ทำไมต้อง ClassCare?',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ออกแบบมาเพื่อลดอุปสรรคในการรายงานปัญหา ให้ทุกคนกล้าพูดถึงสิ่งที่สำคัญ',
                    style: TextStyle(
                      color: Color(0xFF5D5D5D),
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GridView.builder(
                    shrinkWrap: true,
                    itemCount: cards.length,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: width < 680 ? 1.7 : 1.16,
                    ),
                    itemBuilder: (_, index) => _HoverCard(item: cards[index]),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHowItWorks() {
    final steps = const [
      _StepItem(
        title: 'เลือกหมวดหมู่และกรอกรายละเอียด',
        desc:
            'ระบุประเภทปัญหา สถานที่ และอธิบายเหตุการณ์ที่เกิดขึ้น ไม่ต้องระบุชื่อ',
        icon: Icons.edit_note_rounded,
      ),
      _StepItem(
        title: 'AI วิเคราะห์และออก Tracking ID',
        desc:
            'Llama 3.3 70B ประเมินความเร่งด่วนและความเหมาะสม จากนั้นระบบสร้าง ANG-2026-XXXXXX ให้คุณ',
        icon: Icons.psychology_alt_rounded,
      ),
      _StepItem(
        title: 'ติดตามสถานะได้ตลอดเวลา',
        desc: 'กรอก Tracking ID เพื่อดูสถานะ ตั้งแต่ Pending จนถึง Resolved',
        icon: Icons.radar_rounded,
      ),
    ];

    return Container(
      key: _howKey,
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontal = width < 700 ? 16.0 : 24.0;
          final isMobile = width < 900;

          return Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 56, horizontal, 56),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    const Text(
                      'How it works',
                      style: TextStyle(
                        color: Color(0xFFB23A3A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'เริ่มใช้งานใน 3 ขั้นตอน',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ง่าย รวดเร็ว ไม่ต้องสมัครสมาชิก',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF5D5D5D), fontSize: 15),
                    ),
                    const SizedBox(height: 30),
                    isMobile
                        ? Column(
                            children: List.generate(
                              steps.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _StepCard(
                                  step: steps[index],
                                  index: index,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            children: List.generate(
                              steps.length,
                              (index) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 0 : 8,
                                    right: index == steps.length - 1 ? 0 : 8,
                                  ),
                                  child: _StepCard(
                                    step: steps[index],
                                    index: index,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUrgencySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontal = width < 700 ? 16.0 : 24.0;
        final isMobile = width < 950;

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 56, horizontal, 56),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUrgencyLeft(),
                        const SizedBox(height: 18),
                        _buildUrgencyRight(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildUrgencyLeft()),
                        const SizedBox(width: 26),
                        Expanded(child: _buildUrgencyRight()),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUrgencyLeft() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'AI Urgency System',
          style: TextStyle(
            color: Color(0xFFB23A3A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'ระบบประเมินความเร่งด่วน',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          'AI ให้คะแนน 1-5 กับทุกรายงาน เพื่อจัดลำดับความสำคัญโดยอัตโนมัติ',
          style: TextStyle(color: Color(0xFF5D5D5D), height: 1.6, fontSize: 15),
        ),
        SizedBox(height: 18),
        _UrgencyBar(label: 'ระดับ 5 - เร่งด่วนมาก', score: '5.0', ratio: 0.90),
        _UrgencyBar(
          label: 'ระดับ 4 - เร่งด่วน (AI Flag)',
          score: '4.0',
          ratio: 0.72,
        ),
        _UrgencyBar(label: 'ระดับ 3 - ปานกลาง', score: '3.0', ratio: 0.54),
        _UrgencyBar(label: 'ระดับ 2 - ต่ำ', score: '2.0', ratio: 0.36),
        _UrgencyBar(label: 'ระดับ 1 - ทั่วไป', score: '1.0', ratio: 0.18),
      ],
    );
  }

  Widget _buildUrgencyRight() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6D2CD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'การตัดสินใจของ AI',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'ทุกรายงานผ่านการวิเคราะห์ด้วย Llama 3.3 70B ก่อนบันทึก ระบบจะตัดสินใจ 3 ทาง',
            style: TextStyle(color: Color(0xFF5D5D5D), height: 1.6),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DecisionChip(
                label: 'ACCEPT - รับเรื่องปกติ',
                bg: Color(0xFFEAF3DE),
                fg: Color(0xFF3B6D11),
              ),
              _DecisionChip(
                label: 'FLAG - เร่งด่วน (>=4.0)',
                bg: Color(0xFFFFF4DC),
                fg: Color(0xFF854F0B),
              ),
              _DecisionChip(
                label: 'REJECT - ตรวจพบสแปม',
                bg: Color(0xFFFEF0F0),
                fg: Color(0xFFA32D2D),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            'รายงานที่ได้รับ FLAG จะถูกแจ้งเตือนผู้ดูแลระบบทันที เพื่อตอบสนองได้รวดเร็ว',
            style: TextStyle(
              color: Color(0xFF666666),
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustSignals() {
    final testimonials = const [
      _QuoteItem(
        text:
            'หลังใช้ ClassCare อัตราการแจ้งปัญหาเพิ่มขึ้นชัดเจน และจัดการเคสเร่งด่วนได้เร็วขึ้นมาก',
        author: 'ฝ่ายกิจการนักศึกษา',
        org: 'มหาวิทยาลัยพันธมิตร',
      ),
      _QuoteItem(
        text:
            'ระบบไม่บังคับล็อกอิน ทำให้นักศึกษากล้ารายงานมากขึ้น พร้อมติดตามผลด้วย Tracking ID',
        author: 'คณะกรรมการคุณภาพ',
        org: 'เครือข่ายโรงเรียนเอกชน',
      ),
      _QuoteItem(
        text:
            'Dashboard และ AI ช่วยให้ทีมเราโฟกัสเคสสำคัญได้แม่นยำ ลดเวลาคัดกรองงานซ้ำซ้อน',
        author: 'ผู้ดูแลระบบกลาง',
        org: 'ศูนย์บริการนักเรียน',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontal = width < 700 ? 16.0 : 24.0;
        final isMobile = width < 900;

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 56),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: const [
                      _StatCard(value: '500+', label: 'โรงเรียนที่ดูแลแล้ว'),
                      _StatCard(value: '48k+', label: 'รายงานที่ประมวลผล'),
                      _StatCard(
                        value: '92%',
                        label: 'เคสตอบกลับภายใน 24 ชั่วโมง',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Testimonials',
                    style: TextStyle(
                      color: Color(0xFFB23A3A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เสียงจากผู้ใช้งานจริง',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  isMobile
                      ? Column(
                          children: List.generate(
                            testimonials.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _HoverQuoteCard(item: testimonials[index]),
                            ),
                          ),
                        )
                      : Row(
                          children: List.generate(
                            testimonials.length,
                            (index) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: index == 0 ? 0 : 6,
                                  right: index == testimonials.length - 1
                                      ? 0
                                      : 6,
                                ),
                                child: _HoverQuoteCard(
                                  item: testimonials[index],
                                ),
                              ),
                            ),
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

  Widget _buildCta() {
    return Container(
      color: const Color(0xFFB23A3A),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 54),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text(
                'พร้อมรายงานปัญหาแล้วหรือยัง?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'ปลอดภัย ไม่ระบุตัวตน มี AI ช่วยวิเคราะห์ และติดตามสถานะได้ตลอดเวลา',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _HeroActionButton(
                    label: 'Open App',
                    filled: true,
                    onPressed: _goHome,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: const Color(0xFF151515),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 760;

              if (isMobile) {
                return Column(
                  children: [
                    const Text(
                      'ClassCare • MFU Student Support System • © 2026',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _buildFooterButtons(),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ClassCare • MFU Student Support System • © 2026',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  Wrap(spacing: 8, children: _buildFooterButtons()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFooterButtons() {
    return [
      _FooterButton(
        icon: Icons.privacy_tip_outlined,
        label: 'Privacy Policy',
        onPressed: _openPrivacyPage,
      ),
      _FooterButton(
        icon: Icons.mail_outline_rounded,
        label: 'Contact',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact: support@classcare.app')),
          );
        },
      ),
      _FooterButton(
        icon: Icons.language_rounded,
        label: 'Social',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Social: @classcare_official')),
          );
        },
      ),
    ];
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

class _QuoteItem {
  final String text;
  final String author;
  final String org;

  const _QuoteItem({
    required this.text,
    required this.author,
    required this.org,
  });
}

class _StepItem {
  final String title;
  final String desc;
  final IconData icon;

  const _StepItem({
    required this.title,
    required this.desc,
    required this.icon,
  });
}

class _HoverButton extends StatefulWidget {
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  const _HoverButton({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFB23A3A);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()..translate(0, _hover ? -1.5 : 0),
        child: widget.filled
            ? ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: _hover ? 6 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(widget.label),
              )
            : OutlinedButton(
                onPressed: widget.onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(widget.label),
              ),
      ),
    );
  }
}

class _HeroActionButton extends StatefulWidget {
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  const _HeroActionButton({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  @override
  State<_HeroActionButton> createState() => _HeroActionButtonState();
}

class _HeroActionButtonState extends State<_HeroActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _hover ? 1.03 : 1.0,
        child: widget.filled
            ? ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFB23A3A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              )
            : OutlinedButton(
                onPressed: widget.onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.62)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  final _FeatureItem item;

  const _HoverCard({required this.item});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()..translate(0, _hover ? -3.0 : 0.0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.78),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hover ? const Color(0xFFB23A3A) : const Color(0xFFD8D4CF),
            width: _hover ? 1.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(_hover ? 0.09 : 0.05),
              blurRadius: _hover ? 14 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF0F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.item.icon,
                color: const Color(0xFFB23A3A),
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.item.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              widget.item.desc,
              style: const TextStyle(
                color: Color(0xFF555555),
                height: 1.55,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final _StepItem step;
  final int index;

  const _StepCard({required this.step, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0DDD8)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFB23A3A),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            '0${index + 1}',
            style: const TextStyle(
              color: Color(0xFFB23A3A),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            step.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF555555),
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgencyBar extends StatelessWidget {
  final String label;
  final String score;
  final double ratio;

  const _UrgencyBar({
    required this.label,
    required this.score,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF565656),
                  ),
                ),
              ),
              Text(
                score,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE7E3DE),
              borderRadius: BorderRadius.circular(99),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFB23A3A),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _DecisionChip({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0DDD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFB23A3A),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF585858)),
          ),
        ],
      ),
    );
  }
}

class _HoverQuoteCard extends StatefulWidget {
  final _QuoteItem item;

  const _HoverQuoteCard({required this.item});

  @override
  State<_HoverQuoteCard> createState() => _HoverQuoteCardState();
}

class _HoverQuoteCardState extends State<_HoverQuoteCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.identity()..translate(0, _hover ? -2.5 : 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hover ? const Color(0xFFB23A3A) : const Color(0xFFE0DDD8),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withOpacity(_hover ? 0.08 : 0.04),
              blurRadius: _hover ? 14 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.format_quote_rounded,
              color: Color(0xFFB23A3A),
              size: 24,
            ),
            const SizedBox(height: 10),
            Text(
              widget.item.text,
              style: const TextStyle(
                color: Color(0xFF555555),
                height: 1.55,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.item.author,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Text(
              widget.item.org,
              style: const TextStyle(color: Color(0xFF6A6A6A), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _FooterButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.25)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12),
        ),
      ],
    );
  }
}

class _HeroInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
