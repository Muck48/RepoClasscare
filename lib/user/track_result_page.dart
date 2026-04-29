import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:classcare_user/theme/app_design_tokens.dart';
import 'constants/app_constants.dart';
import 'widgets/classcare_bottom_nav.dart';
import 'widgets/pressable_scale.dart';
import 'home_page.dart';
import 'report_page.dart';

class TrackResultPage extends StatefulWidget {
  final Map<String, dynamic> reportData;
  const TrackResultPage({super.key, required this.reportData});

  @override
  State<TrackResultPage> createState() => _TrackResultPageState();
}

class _TrackResultPageState extends State<TrackResultPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late final AnimationController _entryController;
  late final Animation<double> _pageFade;
  late final Animation<Offset> _bannerSlide;
  late final Animation<Offset> _timelineSlide;
  late final Animation<Offset> _trackingSlide;
  late final Animation<Offset> _infoSlide;
  late final Animation<Offset> _summarySlide;
  late final Animation<Offset> _imagesSlide;
  late final Animation<Offset> _commentsSlide;
  late final Animation<Offset> _descSlide;
  late final Animation<Offset> _buttonSlide;

    Brightness get _brightness => Theme.of(context).brightness;
    bool get _isLight => _brightness == Brightness.light;
    Color get _bg => AppColors.bgByTheme(_brightness);
    Color get _surface => AppColors.surfaceByTheme(_brightness);
    Color get _surfaceSecondary => _isLight
      ? AppColors.surfaceSecondaryLight
      : AppColors.surfaceSecondaryDark;
    Color get _primary => AppColors.primary;
    Color get _textPrimary => AppColors.textPrimaryByTheme(_brightness);
    Color get _textSecondary => AppColors.textSecondaryByTheme(_brightness);
    Color get _textTertiary =>
      _isLight ? AppColors.textTertiaryLight : AppColors.textTertiaryDark;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MotionTokens.slow,
    );
    _pageFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _bannerSlide = _stagger(0.00, 0.42);
    _timelineSlide = _stagger(0.10, 0.52);
    _trackingSlide = _stagger(0.20, 0.62);
    _infoSlide = _stagger(0.30, 0.72);
    _summarySlide = _stagger(0.40, 0.82);
    _imagesSlide = _stagger(0.45, 0.87);
    _commentsSlide = _stagger(0.50, 0.92);
    _descSlide = _stagger(0.56, 0.96);
    _buttonSlide = _stagger(0.62, 1.00);

    _entryController.forward();
  }

  Animation<Offset> _stagger(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(begin, end, curve: MotionTokens.entranceCurve),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  String _statusKey(String? rawStatus) {
    return (rawStatus ?? '')
        .toString()
        .toUpperCase()
        .trim()
        .replaceAll(RegExp(r'[\s_-]+'), '');
  }

  int _statusToStep(String? rawStatus) {
    final s = _statusKey(rawStatus);
    if (s == 'INREVIEW') return 1;
    if (s == 'RESOLVED' || s == 'SUCCESS' || s == 'CLOSED' || s == 'DONE') {
      return 2;
    }
    return 0;
  }

  String _normalizeStatus(String? rawStatus) {
    final s = _statusKey(rawStatus);
    if (s == 'INREVIEW') return 'In Review';
    if (s == 'RESOLVED' || s == 'SUCCESS' || s == 'DONE') return 'Resolved';
    if (s == 'CLOSED') return 'Closed';
    return 'Submitted';
  }

  String _friendlyErrorMessage(Object? error) {
    if (error is PostgrestException) {
      final code = (error.code ?? '').trim();
      if (code == 'PGRST301' || code == 'PGRST116') {
        return 'Your report session expired. Please track again from the previous page.';
      }
      return 'Unable to load your latest report status right now. Please try again in a moment.';
    }
    if (error is AuthException) {
      return 'Authentication issue detected. Please sign in again and retry.';
    }
    if (error is TimeoutException || error is RealtimeSubscribeException) {
      return 'Connection was interrupted. Tap Refresh to reconnect live updates.';
    }
    return 'Unable to load your report status right now. Please check your connection and try again.';
  }

  String? _extractCloseReason(Map<String, dynamic> data) {
    final explicit = data['close_reason']?.toString().trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final summary = data['ai_summary']?.toString() ?? '';
    const marker = 'ปิดอัตโนมัติ:';
    final idx = summary.indexOf(marker);
    if (idx < 0) return null;
    return summary.substring(idx).trim();
  }

  bool _isAutoClosedByAi(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toUpperCase().trim();
    return status == 'CLOSED' && _extractCloseReason(data) != null;
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null) return '-';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
    } catch (_) {
      return rawDate.split('T')[0];
    }
  }

  DateTime? _parseDate(dynamic rawDate) {
    final value = rawDate?.toString().trim() ?? '';
    if (value.isEmpty) return null;
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime? _firstValidDate(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final parsed = _parseDate(data[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  String _formatTimelineTime(DateTime? time) {
    if (time == null) return 'Pending';
    return _formatDate(time.toIso8601String());
  }

  List<Map<String, dynamic>> _parseAdminComments(dynamic adminCommentsRaw) {
    List<Map<String, dynamic>> comments = [];

    if (adminCommentsRaw == null) return comments;

    try {
      if (adminCommentsRaw is String) {
        final parsed = jsonDecode(adminCommentsRaw);
        if (parsed is List) {
          comments = parsed
              .whereType<Map>()
              .map(
                (item) => item.map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              )
              .toList();
        }
      } else if (adminCommentsRaw is List) {
        comments = adminCommentsRaw
            .whereType<Map>()
            .map(
              (item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
            .toList();
      }
    } catch (_) {
      comments = [];
    }

    comments.sort((a, b) {
      final aTime = _parseDate(a['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = _parseDate(b['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });

    return comments;
  }

  List<Map<String, dynamic>> _buildTimelineEvents(Map<String, dynamic> data) {
    final createdAt = _parseDate(data['created_at']) ?? DateTime.now();
    final aiTriageAt = _firstValidDate(data, [
      'ai_triage_at',
      'ai_triaged_at',
      'ai_processed_at',
      'triaged_at',
    ]);
    final status = _normalizeStatus(data['status']);
    final comments = _parseAdminComments(data['admin_comments']);
    final firstComment = comments.isNotEmpty ? comments.first : null;
    final lastComment = comments.isNotEmpty ? comments.last : null;
    final closeReason = _extractCloseReason(data);

    final events = <Map<String, dynamic>>[
      {
        'icon': Icons.upload_file_outlined,
        'title': 'Submitted',
        'subtitle': 'Report created and queued for moderation.',
        'time': createdAt,
        'active': true,
      },
      {
        'icon': Icons.auto_awesome_outlined,
        'title': 'AI triage',
        'subtitle': aiTriageAt == null
            ? 'Urgency and spam signals were analyzed. Timestamp unavailable.'
            : 'Urgency and spam signals were analyzed.',
        'time': aiTriageAt,
        'active': status != 'Submitted',
      },
    ];

    if (firstComment != null) {
      events.add({
        'icon': Icons.manage_search_outlined,
        'title': 'Under review',
        'subtitle': 'Admin started reviewing the case.',
        'time': _parseDate(firstComment['timestamp']),
        'active': status == 'In Review' || status == 'Resolved' || status == 'Closed',
      });
    } else if (status == 'In Review' || status == 'Resolved' || status == 'Closed') {
      events.add({
        'icon': Icons.manage_search_outlined,
        'title': 'Under review',
        'subtitle': 'Case is being reviewed by the team.',
        'time': _firstValidDate(data, ['review_started_at', 'reviewed_at']),
        'active': true,
      });
    }

    if (status == 'Resolved' || status == 'Closed') {
      events.add({
        'icon': status == 'Closed' ? Icons.gpp_maybe_outlined : Icons.task_alt_outlined,
        'title': status == 'Closed' ? 'Closed' : 'Resolved',
        'subtitle': closeReason != null
            ? closeReason.replaceAll('ปิดอัตโนมัติ:', '').trim()
            : 'Case finalized and no further action is required.',
        'time': _parseDate(lastComment?['timestamp']) ??
            _firstValidDate(data, ['resolved_at', 'closed_at', 'updated_at']),
        'active': true,
      });
    }

    return events;
  }

  Map<String, dynamic> _statusMeta(String status) {
    if (status == 'Closed') {
      return {
        'color': _isLight ? AppColors.errorDark : AppColors.errorLight,
        'bg': _isLight
            ? AppColors.errorLight
            : AppColors.errorDark.withValues(alpha: 0.32),
        'icon': Icons.gpp_maybe_outlined,
        'message': 'This report was automatically closed by moderation policy.',
      };
    }

    switch (status) {
      case 'In Review':
        return {
          'color': _isLight ? AppColors.warningDark : AppColors.warningLight,
          'bg': _isLight
              ? AppColors.warningLight.withValues(alpha: 0.35)
              : AppColors.warningDark.withValues(alpha: 0.28),
          'icon': Icons.search_outlined,
          'message': 'Our team is actively reviewing your report.',
        };
      case 'Resolved':
      case 'Closed':
        return {
          'color': _isLight ? AppColors.successDark : AppColors.successLight,
          'bg': _isLight
              ? AppColors.successLight.withValues(alpha: 0.32)
              : AppColors.successDark.withValues(alpha: 0.30),
          'icon': Icons.check_circle_outline,
          'message': 'This case has been resolved. Thank you for reporting.',
        };
      default:
        return {
          'color': _isLight ? AppColors.infoDark : AppColors.infoLight,
          'bg': _isLight
              ? AppColors.infoLight.withValues(alpha: 0.28)
              : AppColors.infoDark.withValues(alpha: 0.28),
          'icon': Icons.hourglass_empty_outlined,
          'message': 'Your report has been received and is queued for review.',
        };
    }
  }

  List<String> _extractImageUrls(Map<String, dynamic> data) {
    final urls = <String>{};

    void addUrl(dynamic value) {
      final candidate = value?.toString().trim() ?? '';
      if (candidate.isNotEmpty) urls.add(candidate);
    }

    final raw = data['image_url'];

    if (raw is List) {
      // Supabase คืนเป็น List โดยตรง
      for (final item in raw) {
        addUrl(item);
      }
    } else if (raw is String) {
      final str = raw.trim();
      if (str.startsWith('{') && str.endsWith('}')) {
        // Postgres array format: {"url1","url2"}
        final inner = str.substring(1, str.length - 1);
        for (final part in inner.split(',')) {
          addUrl(part.trim().replaceAll('"', ''));
        }
      } else if (str.startsWith('[') && str.endsWith(']')) {
        // JSON array format: ["url1","url2"]
        try {
          final parsed = jsonDecode(str);
          if (parsed is List) {
            for (final item in parsed) {
              addUrl(item);
            }
          }
        } catch (_) {
          addUrl(str);
        }
      } else if (str.isNotEmpty) {
        addUrl(str);
      }
    }

    return urls.toList();
  }

  String _resolveImageUrl(String rawValue) {
    final candidate = rawValue.trim();
    if (candidate.isEmpty) return candidate;
    if (candidate.startsWith('http://') || candidate.startsWith('https://')) {
      return candidate;
    }

    return supabase.storage.from(AppStorageBuckets.reportImages).getPublicUrl(candidate);
  }

  @override
  Widget build(BuildContext context) {
    final reportId = widget.reportData['ID'] ?? widget.reportData['id'];
    final hasLiveUpdates = reportId != null;
    final reportIdColumn = widget.reportData['ID'] != null ? 'ID' : 'id';
    final Stream<Map<String, dynamic>> reportStream = reportId == null
        ? Stream<Map<String, dynamic>>.value(widget.reportData)
        : supabase
              .from('reports')
              .stream(primaryKey: [reportIdColumn])
              .eq(reportIdColumn, reportId)
              .map((rows) => rows.isNotEmpty ? rows.first : widget.reportData);

    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: ClasscareBottomNav(
        current: ClasscareTab.track,
        onHomeTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        ),
        onReportTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ReportPage()),
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'Report Status',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
        backgroundColor: _primary,
        foregroundColor: _isLight ? Colors.white : AppColors.textPrimaryDark,
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: reportStream,
        initialData: widget.reportData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final message = _friendlyErrorMessage(snapshot.error);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? widget.reportData;
          final status = _normalizeStatus(data['status']);
          final step = _statusToStep(data['status']);
          final meta = _statusMeta(status);
          final aiSummary = data['ai_summary']?.toString() ?? '';
          final closeReason = _extractCloseReason(data);
          final autoClosedByAi = _isAutoClosedByAi(data);
          final imageUrls = _extractImageUrls(data);
          final isFlagged = data['is_flagged'] == true;

          return FadeTransition(
            opacity: _pageFade,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasLiveUpdates) ...[
                    _staggerSection(
                      animation: _bannerSlide,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isLight
                              ? AppColors.warningLight.withValues(alpha: 0.35)
                              : AppColors.warningDark.withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isLight
                                ? AppColors.warningLight
                                : AppColors.warning,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.wifi_off_outlined,
                              color: _isLight
                                  ? AppColors.warningDark
                                  : AppColors.warningLight,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Live updates are unavailable for this result. Pull-to-refresh or tap Refresh to fetch latest data.',
                                style: TextStyle(
                                  color: _isLight
                                      ? AppColors.warningDark
                                      : AppColors.warningLight,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _staggerSection(
                    animation: _bannerSlide,
                    child: _buildStatusBanner(status, meta),
                  ),
                  const SizedBox(height: 16),
                  _staggerSection(
                    animation: _timelineSlide,
                    child: _buildStatusTimeline(step),
                  ),
                  const SizedBox(height: 16),
                  _staggerSection(
                    animation: _trackingSlide,
                    child: _buildTrackingCard(
                      data['tracking_id'],
                      status,
                      meta,
                      isFlagged,
                      autoClosedByAi,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _staggerSection(
                    animation: _infoSlide,
                    child: _buildInfoRow(data),
                  ),
                  const SizedBox(height: 16),
                  _staggerSection(
                    animation: _infoSlide,
                    child: _buildCaseActivityTimeline(data),
                  ),
                  if (imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _staggerSection(
                      animation: _imagesSlide,
                      child: _buildAttachedImagesCard(imageUrls),
                    ),
                  ],
                  if (aiSummary.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _staggerSection(
                      animation: _summarySlide,
                      child: _buildAISummaryCard(aiSummary),
                    ),
                  ],
                  if (closeReason != null && closeReason.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _staggerSection(
                      animation: _summarySlide,
                      child: _buildCloseReasonCard(closeReason),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _staggerSection(
                    animation: _commentsSlide,
                    child: _buildAdminCommentsSection(data['admin_comments']),
                  ),
                  const SizedBox(height: 16),
                  _staggerSection(
                    animation: _descSlide,
                    child: _buildDescriptionCard(data['description']),
                  ),
                  const SizedBox(height: 24),
                  _staggerSection(
                    animation: _buttonSlide,
                    child: Center(
                      child: PressableScale(
                        onTap: () => Navigator.pop(context),
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                          label: const Text(
                            'Back to Search',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            side: BorderSide(color: _primary, width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _staggerSection({
    required Animation<Offset> animation,
    required Widget child,
  }) {
    return SlideTransition(
      position: animation,
      child: FadeTransition(opacity: _pageFade, child: child),
    );
  }

  Widget _buildStatusBanner(String status, Map<String, dynamic> meta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: meta['bg'] as Color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (meta['color'] as Color).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (meta['color'] as Color).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              meta['icon'] as IconData,
              color: meta['color'] as Color,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: meta['color'] as Color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  meta['message'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: (meta['color'] as Color).withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(int currentStep) {
    final steps = [
      {'label': 'Submitted', 'icon': Icons.upload_file_outlined},
      {'label': 'In Review', 'icon': Icons.search_outlined},
      {'label': 'Done', 'icon': Icons.task_alt_outlined},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isLight ? 0.04 : 0.24),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROGRESS',
            style: TextStyle(
              fontSize: 14,
              color: _textTertiary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i % 2 == 1) {
                final isCompleted = currentStep > i ~/ 2;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      decoration: BoxDecoration(
                        color: isCompleted
                          ? _primary
                          : (_isLight
                            ? AppColors.borderLight
                            : AppColors.borderDark),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }

              final stepIdx = i ~/ 2;
              final isCompleted = currentStep >= stepIdx;
              final isCurrent = currentStep == stepIdx;
              final stepData = steps[stepIdx];

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: isCompleted
                          ? _primary
                          : (_isLight
                            ? AppColors.borderSubtleLight
                            : AppColors.borderSubtleDark),
                      borderRadius: BorderRadius.circular(40),
                      border: isCurrent
                          ? Border.all(
                              color: _primary.withValues(alpha: 0.25),
                              width: 4,
                            )
                          : null,
                    ),
                    child: Icon(
                      stepData['icon'] as IconData,
                      color: isCompleted
                          ? Colors.white
                          : _textTertiary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stepData['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCompleted ? _primary : _textTertiary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard(
    dynamic trackingId,
    String status,
    Map<String, dynamic> meta,
    bool isFlagged,
    bool isAutoClosedByAi,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLight
              ? const [Color(0xFF2F2F2F), Color(0xFF1E1E1E)]
              : const [Color(0xFF262626), Color(0xFF141414)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TRACKING ID',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  trackingId?.toString() ?? 'N/A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                if (isFlagged) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.priority_high_outlined,
                          color: Colors.orange,
                          size: 14,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'High Priority',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isAutoClosedByAi) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isLight
                          ? AppColors.errorLight
                          : AppColors.errorDark.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gpp_maybe_outlined, color: AppColors.primary, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'Closed by AI',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: (meta['color'] as Color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (meta['color'] as Color).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == 'In Review') ...[
                  const _LivePulseDot(),
                  const SizedBox(width: 8),
                ],
                Icon(
                  meta['icon'] as IconData,
                  color: meta['color'] as Color,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    color: meta['color'] as Color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            'Category',
            data['category']?.toString() ?? 'General',
            Icons.category_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _infoCard(
            'Submitted',
            _formatDate(data['created_at']?.toString()),
            Icons.calendar_today_outlined,
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCaseActivityTimeline(Map<String, dynamic> data) {
    final events = _buildTimelineEvents(data);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_outlined, size: 16, color: _primary),
              const SizedBox(width: 8),
              Text(
                'CASE TIMELINE',
                style: TextStyle(
                  color: _primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(events.length, (index) {
            final event = events[index];
            final isLast = index == events.length - 1;
            final isActive = event['active'] == true;
            final color = isActive ? _primary : _textTertiary;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Icon(event['icon'] as IconData, size: 18, color: color),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 34,
                          color: _isLight
                              ? AppColors.borderSubtleLight
                              : AppColors.borderDark,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? color.withValues(alpha: 0.05)
                            : _surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? color.withValues(alpha: 0.18)
                              : (_isLight
                                  ? AppColors.borderSubtleLight
                                  : AppColors.borderDark),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event['title'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTimelineTime(event['time'] as DateTime?),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAISummaryCard(String summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DEB8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: Color(0xFFB67B1B),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'AI SUMMARY',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF7A5312),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF4B3A1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseReasonCard(String reason) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB23A3A).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.gpp_maybe_outlined,
                color: Color(0xFFB23A3A),
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'AUTO-CLOSE REASON',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF8B2626),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF6E1F1F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCommentsSection(dynamic adminCommentsRaw) {
    List<Map<String, dynamic>> comments = [];

    if (adminCommentsRaw != null) {
      try {
        if (adminCommentsRaw is String) {
          final parsed = jsonDecode(adminCommentsRaw);
          if (parsed is List) {
            comments = parsed
                .whereType<Map>()
                .map(
                  (item) =>
                      item.map((key, value) => MapEntry(key.toString(), value)),
                )
                .toList();
          }
        } else if (adminCommentsRaw is List) {
          comments = adminCommentsRaw
              .whereType<Map>()
              .map(
                (item) =>
                    item.map((key, value) => MapEntry(key.toString(), value)),
              )
              .toList();
        }
      } catch (_) {
        // Handle parse error gracefully
      }
    }

    if (comments.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort comments by timestamp (newest first)
    comments.sort((a, b) {
      try {
        final aTime = DateTime.parse(a['timestamp']?.toString() ?? '');
        final bTime = DateTime.parse(b['timestamp']?.toString() ?? '');
        return bTime.compareTo(aTime);
      } catch (_) {
        return 0;
      }
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 16,
                color: _primary,
              ),
              const SizedBox(width: 8),
              Text(
                'ADMIN RESPONSE',
                style: TextStyle(
                  color: _primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              final reason = comment['reason']?.toString() ?? 'Note';
              final text = comment['text']?.toString() ?? '';
              final timestamp = _formatDate(comment['timestamp']?.toString());

              Color reasonColor = const Color(0xFF8A8A8A);
              Color reasonBgColor = const Color(0xFFF0F0F0);

              if (reason.toLowerCase().contains('spam')) {
                reasonColor = const Color(0xFFD32F2F);
                reasonBgColor = const Color(0xFFFFEBEE);
              } else if (reason.toLowerCase().contains('resolved') ||
                  reason.toLowerCase().contains('closed') ||
                  reason.toLowerCase().contains('done')) {
                reasonColor = const Color(0xFF3F8E4B);
                reasonBgColor = const Color(0xFFECF7EE);
              } else if (reason.toLowerCase().contains('review')) {
                reasonColor = const Color(0xFFC88B22);
                reasonBgColor = const Color(0xFFFFF8E8);
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < comments.length - 1 ? 16 : 0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: reasonBgColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: reasonColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: reasonBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: reasonColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              reason,
                              style: TextStyle(
                                color: reasonColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timestamp,
                            style: const TextStyle(
                              color: Color(0xFF9B9B9B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedImagesCard(List<String> imageUrls) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 14,
                color: Color(0xFF7A7A7A),
              ),
              SizedBox(width: 8),
              Text(
                'ATTACHED PHOTOS',
                style: TextStyle(
                  color: Color(0xFF7A7A7A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: imageUrls.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final imageUrl = _resolveImageUrl(imageUrls[index]);
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFF4F4F4),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF9A9A9A),
                        size: 28,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(dynamic description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 14,
                color: Color(0xFF7A7A7A),
              ),
              SizedBox(width: 8),
              Text(
                'DESCRIPTION',
                style: TextStyle(
                  color: Color(0xFF7A7A7A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description?.toString() ?? 'No description provided.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot();

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = 0.35 + (_pulse.value * 0.35);
        final scale = 0.9 + (_pulse.value * 0.2);

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: glow),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

