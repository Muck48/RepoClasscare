import 'report_service.dart' as report_service;

class AIReportResult {
  final bool isAccepted;
  final bool isQueued;
  final String? trackingId;
  final String? message;

  const AIReportResult({
    required this.isAccepted,
    this.isQueued = false,
    this.trackingId,
    this.message,
  });
}

class AIService {
  static Future<AIReportResult> submitReport({
    required String description,
    required String location,
    required String category,
    String? imageUrl,
    List<String>? imageUrls,
  }) async {
    final cleanDescription = description.trim();
    final cleanLocation = location.trim();

    if (cleanDescription.isEmpty || cleanLocation.isEmpty) {
      return const AIReportResult(
        isAccepted: false,
        message: 'Please complete all required fields.',
      );
    }

    final result = await report_service.submitOrQueueReport(
      title: category,
      description: cleanDescription,
      category: category,
      location: cleanLocation,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
    );

    if (!result.isAccepted) {
      return AIReportResult(
        isAccepted: false,
        isQueued: result.isQueued,
        trackingId: result.trackingId.isEmpty ? null : result.trackingId,
        message: result.message,
      );
    }

    if (result.trackingId.isEmpty) {
      return const AIReportResult(
        isAccepted: false,
        message: 'Unable to create report at this time.',
      );
    }

    return AIReportResult(
      isAccepted: true,
      isQueued: result.isQueued,
      trackingId: result.trackingId,
      message: result.message,
    );
  }
}
