import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/pdf_document.dart';
import '../models/bookmark.dart';
import '../models/reading_history.dart';
import '../models/user_settings.dart';

/// SQLite Database Helper for persistent storage of documents, bookmarks,
/// reading history, and user preferences.
class DatabaseHelper {
  static const String _databaseName = 'pdf_utility_reader.db';
  static const int _databaseVersion = 1;

  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable Foreign Key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Documents Table
    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL UNIQUE,
        file_size INTEGER NOT NULL,
        total_pages INTEGER NOT NULL DEFAULT 1,
        last_read_page INTEGER NOT NULL DEFAULT 1,
        last_read_time TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        tags TEXT,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Bookmarks Table
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        page_number INTEGER NOT NULL,
        title TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');

    // 3. Reading History Table
    await db.execute('''
      CREATE TABLE reading_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL,
        page_number INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');

    // 4. User Preferences Table
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY,
        theme_mode TEXT NOT NULL DEFAULT 'system',
        reading_bg_color TEXT NOT NULL DEFAULT 'white',
        notification_sound TEXT NOT NULL DEFAULT 'default',
        reading_goal_minutes INTEGER NOT NULL DEFAULT 30,
        notifications_enabled INTEGER NOT NULL DEFAULT 1,
        reminder_time TEXT NOT NULL DEFAULT '20:00'
      )
    ''');

    // Insert initial default settings
    await db.insert('user_settings', {
      'id': 1,
      'theme_mode': 'system',
      'reading_bg_color': 'white',
      'notification_sound': 'default',
      'reading_goal_minutes': 30,
      'notifications_enabled': 1,
      'reminder_time': '20:00',
    });
  }

  // ==================== DOCUMENT OPERATIONS ====================

  Future<int> insertDocument(PdfDocument doc) async {
    final db = await database;
    return await db.insert(
      'documents',
      doc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PdfDocument>> getAllDocuments({String sortBy = 'created_at', bool ascending = false}) async {
    final db = await database;
    final order = ascending ? 'ASC' : 'DESC';
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      orderBy: '$sortBy $order',
    );
    return maps.map((m) => PdfDocument.fromMap(m)).toList();
  }

  Future<PdfDocument?> getDocumentById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return PdfDocument.fromMap(maps.first);
    }
    return null;
  }

  Future<PdfDocument?> getDocumentByPath(String path) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'file_path = ?',
      whereArgs: [path],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return PdfDocument.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateDocument(PdfDocument doc) async {
    final db = await database;
    return await db.update(
      'documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  Future<int> deleteDocument(int id) async {
    final db = await database;
    return await db.delete(
      'documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'documents',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateReadingProgress(int id, int page, int totalPages) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'documents',
      {
        'last_read_page': page,
        'total_pages': totalPages,
        'last_read_time': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    // Also record into reading history
    await db.insert('reading_history', {
      'document_id': id,
      'page_number': page,
      'duration_seconds': 0,
      'timestamp': now,
    });
  }

  Future<List<PdfDocument>> getFavoriteDocuments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'is_favorite = 1',
      orderBy: 'title ASC',
    );
    return maps.map((m) => PdfDocument.fromMap(m)).toList();
  }

  Future<List<PdfDocument>> getRecentDocuments({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'last_read_time IS NOT NULL',
      orderBy: 'last_read_time DESC',
      limit: limit,
    );
    return maps.map((m) => PdfDocument.fromMap(m)).toList();
  }

  Future<List<PdfDocument>> searchDocuments(String query) async {
    final db = await database;
    final q = '%$query%';
    final List<Map<String, dynamic>> maps = await db.query(
      'documents',
      where: 'title LIKE ? OR tags LIKE ? OR description LIKE ?',
      whereArgs: [q, q, q],
      orderBy: 'title ASC',
    );
    return maps.map((m) => PdfDocument.fromMap(m)).toList();
  }

  // ==================== BOOKMARK OPERATIONS ====================

  Future<int> insertBookmark(Bookmark bookmark) async {
    final db = await database;
    return await db.insert(
      'bookmarks',
      bookmark.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Bookmark>> getBookmarksForDocument(int documentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'page_number ASC',
    );
    return maps.map((m) => Bookmark.fromMap(m)).toList();
  }

  Future<List<Bookmark>> getAllBookmarks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT b.*, d.title AS doc_title, d.file_path AS file_path
      FROM bookmarks b
      JOIN documents d ON b.document_id = d.id
      ORDER BY b.created_at DESC
    ''');
    return maps.map((m) => Bookmark.fromMap(m)).toList();
  }

  Future<int> deleteBookmark(int id) async {
    final db = await database;
    return await db.delete(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isPageBookmarked(int documentId, int pageNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookmarks',
      where: 'document_id = ? AND page_number = ?',
      whereArgs: [documentId, pageNumber],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // ==================== READING HISTORY OPERATIONS ====================

  Future<int> recordReadingHistory(int documentId, int pageNumber, int durationSeconds) async {
    final db = await database;
    return await db.insert('reading_history', {
      'document_id': documentId,
      'page_number': pageNumber,
      'duration_seconds': durationSeconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<ReadingHistory>> getReadingHistory({int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT h.*, d.title AS doc_title, d.file_path AS file_path, d.total_pages AS total_pages
      FROM reading_history h
      JOIN documents d ON h.document_id = d.id
      ORDER BY h.timestamp DESC
      LIMIT ?
    ''', [limit]);
    return maps.map((m) => ReadingHistory.fromMap(m)).toList();
  }

  Future<void> clearReadingHistory() async {
    final db = await database;
    await db.delete('reading_history');
  }

  // ==================== USER SETTINGS OPERATIONS ====================

  Future<UserSettings> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_settings',
      where: 'id = 1',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserSettings.fromMap(maps.first);
    }
    return UserSettings();
  }

  Future<void> updateSettings(UserSettings settings) async {
    final db = await database;
    await db.update(
      'user_settings',
      settings.toMap(),
      where: 'id = 1',
    );
  }
}
