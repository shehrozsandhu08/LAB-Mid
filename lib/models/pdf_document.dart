import 'dart:convert';

/// Data model representing a PDF document in the library.
class PdfDocument {
  final int? id;
  final String title;
  final String filePath;
  final int fileSize; // in bytes
  final int totalPages;
  final int lastReadPage;
  final DateTime? lastReadTime;
  final bool isFavorite;
  final List<String> tags;
  final String description;
  final DateTime createdAt;

  PdfDocument({
    this.id,
    required this.title,
    required this.filePath,
    required this.fileSize,
    this.totalPages = 1,
    this.lastReadPage = 1,
    this.lastReadTime,
    this.isFavorite = false,
    this.tags = const [],
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progressPercentage {
    if (totalPages <= 0) return 0.0;
    final progress = lastReadPage / totalPages;
    return progress.clamp(0.0, 1.0);
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'file_path': filePath,
      'file_size': fileSize,
      'total_pages': totalPages,
      'last_read_page': lastReadPage,
      'last_read_time': lastReadTime?.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'tags': jsonEncode(tags),
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PdfDocument.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null && map['tags'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['tags']);
        if (decoded is List) {
          parsedTags = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedTags = map['tags'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    return PdfDocument(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Untitled',
      filePath: map['file_path'] as String? ?? '',
      fileSize: map['file_size'] as int? ?? 0,
      totalPages: map['total_pages'] as int? ?? 1,
      lastReadPage: map['last_read_page'] as int? ?? 1,
      lastReadTime: map['last_read_time'] != null
          ? DateTime.tryParse(map['last_read_time'] as String)
          : null,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      tags: parsedTags,
      description: map['description'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  PdfDocument copyWith({
    int? id,
    String? title,
    String? filePath,
    int? fileSize,
    int? totalPages,
    int? lastReadPage,
    DateTime? lastReadTime,
    bool? isFavorite,
    List<String>? tags,
    String? description,
    DateTime? createdAt,
  }) {
    return PdfDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      totalPages: totalPages ?? this.totalPages,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      lastReadTime: lastReadTime ?? this.lastReadTime,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
