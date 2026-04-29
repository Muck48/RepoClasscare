import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
const String _pendingReportSubmissionsKey = 'pending_report_submissions';
const String _pendingState = 'pending';
const String _failedPermanentState = 'failed_permanent';
const Duration _pendingReportSyncTimeout = Duration(seconds: 12);
const Duration _pendingReportMaxAge = Duration(days: 7);

class PendingReportSubmission {
  final String trackingId;
  final String title;
  final String description;
  final String category;
  final String location;
  final List<String> imageUrls;
  final String queuedAt;
  final String? lastError;
  final String syncState;
  final String? userMessage;
  final int retryCount;

  const PendingReportSubmission({
    required this.trackingId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.imageUrls,
    required this.queuedAt,
    this.lastError,
    this.syncState = _pendingState,
    this.userMessage,
    this.retryCount = 0,
  });

  bool get isPermanentFailure => syncState == _failedPermanentState;
  bool get isPending => syncState == _pendingState;

  PendingReportSubmission copyWith({
    String? trackingId,
    String? title,
    String? description,
    String? category,
    String? location,
    List<String>? imageUrls,
    String? queuedAt,
    String? lastError,
    String? syncState,
    String? userMessage,
    int? retryCount,
  }) {
    return PendingReportSubmission(
      trackingId: trackingId ?? this.trackingId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      queuedAt: queuedAt ?? this.queuedAt,
      lastError: lastError ?? this.lastError,
      syncState: syncState ?? this.syncState,
      userMessage: userMessage ?? this.userMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trackingId': trackingId,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'imageUrls': imageUrls,
      'queuedAt': queuedAt,
      'lastError': lastError,
      'syncState': syncState,
      'userMessage': userMessage,
      'retryCount': retryCount,
    };
  }

  factory PendingReportSubmission.fromJson(Map<String, dynamic> json) {
    return PendingReportSubmission(
      trackingId: json['trackingId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      imageUrls: (json['imageUrls'] as List?)
              ?.map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList() ??
          const [],
      queuedAt: json['queuedAt']?.toString() ?? DateTime.now().toIso8601String(),
      lastError: json['lastError']?.toString(),
      syncState: json['syncState']?.toString() == _failedPermanentState
          ? _failedPermanentState
          : _pendingState,
      userMessage: json['userMessage']?.toString(),
      retryCount: int.tryParse(json['retryCount']?.toString() ?? '') ?? 0,
    );
  }
}

class ReportDispatchResult {
  final bool isAccepted;
  final String trackingId;
  final bool isQueued;
  final String message;

  const ReportDispatchResult({
    required this.isAccepted,
    required this.trackingId,
    required this.isQueued,
    required this.message,
  });
}

Future<List<PendingReportSubmission>> getQueueSubmissions() async {
  final items = await _loadPendingSubmissions();
  items.sort((a, b) => b.queuedAt.compareTo(a.queuedAt));
  return items;
}

Future<void> clearQueueSubmission(String trackingId) async {
  final items = await _loadPendingSubmissions();
  items.removeWhere((item) => item.trackingId == trackingId);
  await _savePendingSubmissions(items);
}

String generateTrackingId() {
  final random = Random();
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final code = List.generate(
    6,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
  return "ANG-2026-$code";
}

Future<String?> submitReport({
  required String title,
  required String description,
  required String category,
  String? location,
  String? imageUrl,
  List<String>? imageUrls,
}) async {
  try {
    final trackingId = generateTrackingId();
    final insertedTrackingId = await _insertReport(
      trackingId: trackingId,
      title: title,
      description: description,
      category: category,
      location: location,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
    );
    return insertedTrackingId;
  } catch (e) {
    debugPrint('Report submit error: $e');
    rethrow;
  }
}

Future<ReportDispatchResult> submitOrQueueReport({
  required String title,
  required String description,
  required String category,
  String? location,
  String? imageUrl,
  List<String>? imageUrls,
}) async {
  final trackingId = generateTrackingId();
  try {
    final insertedTrackingId = await _insertReport(
      trackingId: trackingId,
      title: title,
      description: description,
      category: category,
      location: location,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
    );
    return ReportDispatchResult(
      isAccepted: true,
      trackingId: insertedTrackingId,
      isQueued: false,
      message: 'รับเรื่องเรียบร้อยแล้ว',
    );
  } catch (e) {
    debugPrint('[report_service] Submit failed with unexpected error: $e');
    return ReportDispatchResult(
      isAccepted: false,
      trackingId: '',
      isQueued: false,
      message: _toUserFriendlyFallbackError(e),
    );
  }
}

Future<int> syncPendingReports({
  Duration perReportTimeout = _pendingReportSyncTimeout,
  Duration maxQueueAge = _pendingReportMaxAge,
}) async {
  final pendingReports = await _loadPendingSubmissions();
  if (pendingReports.isEmpty) return 0;

  final remaining = <PendingReportSubmission>[];
  var syncedCount = 0;
  final now = DateTime.now();

  for (final report in pendingReports) {
    if (_isStalePendingSubmission(report, now, maxQueueAge)) {
      continue;
    }
    if (report.isPermanentFailure) {
      remaining.add(report);
      continue;
    }

    try {
      await _insertReport(
        trackingId: report.trackingId,
        title: report.title,
        description: report.description,
        category: report.category,
        location: report.location,
        imageUrls: report.imageUrls,
      ).timeout(perReportTimeout);
      syncedCount++;
    } on TimeoutException catch (e) {
      remaining.add(report.copyWith(lastError: e.toString(), retryCount: report.retryCount + 1));
    } catch (e) {
      remaining.add(report.copyWith(lastError: e.toString(), retryCount: report.retryCount + 1));
    }
  }

  await _savePendingSubmissions(remaining);
  return syncedCount;
}

bool _isStalePendingSubmission(
  PendingReportSubmission submission,
  DateTime now,
  Duration maxQueueAge,
) {
  final queuedAt = DateTime.tryParse(submission.queuedAt);
  if (queuedAt == null) return false;
  return now.difference(queuedAt) > maxQueueAge;
}

Future<String> _insertReport({
  required String trackingId,
  required String title,
  required String description,
  required String category,
  String? location,
  String? imageUrl,
  List<String>? imageUrls,
}) async {
  final normalizedImageUrls = _normalizeImageUrls(
    imageUrl: imageUrl,
    imageUrls: imageUrls,
  );

  debugPrint(
    '[report_service] Insert attempt: trackingId=$trackingId, '
    'images=${normalizedImageUrls.length}',
  );

  final basePayload = <String, dynamic>{
    'tracking_id': trackingId,
    'title': title,
    'description': description,
    'category': category,
    'location': location ?? 'Not specified',
    'status': 'Pending',
  };

  final payload = <String, dynamic>{
    ...basePayload,
    if (normalizedImageUrls.isNotEmpty)
      'image_url': '{${normalizedImageUrls.map((u) => '"$u"').join(',')}}',
  };

  await supabase.from('reports').insert(payload);
  debugPrint('[report_service] Direct insert succeeded for trackingId=$trackingId');
  return trackingId;
}

String _toUserFriendlyFallbackError(Object error) {
  final message = error.toString().toLowerCase();
  if (message.contains('ยังไม่พร้อมสำหรับการส่งรายงาน')) {
    return 'ยังไม่พร้อมสำหรับการส่งรายงาน กรุณาลองใหม่อีกครั้ง';
  }
  if (message.contains('timeout') || message.contains('socket') || message.contains('network')) {
    return 'เชื่อมต่ออินเทอร์เน็ตไม่เสถียร โปรดลองอีกครั้ง';
  }
  return 'ส่งรายงานไม่สำเร็จ กรุณาลองใหม่ภายหลัง';
}

List<String> _normalizeImageUrls({
  String? imageUrl,
  List<String>? imageUrls,
}) {
  return <String>{
    if (imageUrl != null && imageUrl.trim().isNotEmpty) imageUrl.trim(),
    ...?imageUrls?.map((url) => url.trim()).where((url) => url.isNotEmpty),
  }.toList();
}

Future<List<PendingReportSubmission>> _loadPendingSubmissions() async {
  final prefs = await SharedPreferences.getInstance();
  final rawList = prefs.getStringList(_pendingReportSubmissionsKey) ?? <String>[];
  return rawList
      .map((raw) => jsonDecode(raw))
      .whereType<Map>()
      .map(
        (item) => PendingReportSubmission.fromJson(
          item.map((key, value) => MapEntry(key.toString(), value)),
        ),
      )
      .where((item) => item.trackingId.isNotEmpty)
      .toList();
}

Future<void> _savePendingSubmissions(List<PendingReportSubmission> submissions) async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = submissions.map((item) => jsonEncode(item.toJson())).toList();
  await prefs.setStringList(_pendingReportSubmissionsKey, encoded);
}
