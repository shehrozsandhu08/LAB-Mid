/// Data model representing reading history events.
class ReadingHistory {
  final int? id;
  final int documentId;
  final int pageNumber;
  final int durationSeconds;
  final DateTime timestamp;

  // Joined fields for display
  final String? documentTitle;
  final String? documentPath;
  final int? totalPages;

  ReadingHistory({
    this.id,
    required this.documentId,
    required this.pageNumber,
    this.durationSeconds = 0,
    DateTime? timestamp,
    this.documentTitle,
    this.documentPath,
    this.totalPages,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'page_number': pageNumber,
      'duration_seconds': durationSeconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ReadingHistory.fromMap(Map<String, dynamic> map) {
    return ReadingHistory(
      id: map['id'] as int?,
      documentId: map['document_id'] as int,
      pageNumber: map['page_number'] as int? ?? 1,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      documentTitle: map['doc_title'] as String?,
      documentPath: map['file_path'] as String?,
      totalPages: map['total_pages'] as int?,
    );
  }
}
