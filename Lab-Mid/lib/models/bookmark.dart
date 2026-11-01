/// Data model for bookmarked pages within a PDF.
class Bookmark {
  final int? id;
  final int documentId;
  final int pageNumber;
  final String title;
  final String note;
  final DateTime createdAt;

  // Joined metadata for UI convenience
  final String? documentTitle;
  final String? documentPath;

  Bookmark({
    this.id,
    required this.documentId,
    required this.pageNumber,
    required this.title,
    this.note = '',
    DateTime? createdAt,
    this.documentTitle,
    this.documentPath,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'page_number': pageNumber,
      'title': title,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int?,
      documentId: map['document_id'] as int,
      pageNumber: map['page_number'] as int,
      title: map['title'] as String? ?? 'Page ${map['page_number']}',
      note: map['note'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      documentTitle: map['doc_title'] as String?,
      documentPath: map['file_path'] as String?,
    );
  }

  Bookmark copyWith({
    int? id,
    int? documentId,
    int? pageNumber,
    String? title,
    String? note,
    DateTime? createdAt,
    String? documentTitle,
    String? documentPath,
  }) {
    return Bookmark(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      title: title ?? this.title,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      documentTitle: documentTitle ?? this.documentTitle,
      documentPath: documentPath ?? this.documentPath,
    );
  }
}
