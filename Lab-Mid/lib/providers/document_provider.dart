import 'dart:io';
import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/bookmark.dart';
import '../models/pdf_document.dart';
import '../models/reading_history.dart';
import '../services/notification_service.dart';
import '../services/pdf_service.dart';

class DocumentProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<PdfDocument> _allDocuments = [];
  List<PdfDocument> _filteredDocuments = [];
  List<PdfDocument> _favoriteDocuments = [];
  List<PdfDocument> _recentDocuments = [];
  List<Bookmark> _allBookmarks = [];
  List<ReadingHistory> _readingHistory = [];

  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedTag;
  String _sortBy = 'created_at';
  bool _sortAscending = false;

  // Getters
  List<PdfDocument> get documents => _filteredDocuments;
  List<PdfDocument> get allDocuments => _allDocuments;
  List<PdfDocument> get favoriteDocuments => _favoriteDocuments;
  List<PdfDocument> get recentDocuments => _recentDocuments;
  List<Bookmark> get allBookmarks => _allBookmarks;
  List<ReadingHistory> get readingHistory => _readingHistory;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;

  Set<String> get allTags {
    final Set<String> tags = {};
    for (var doc in _allDocuments) {
      tags.addAll(doc.tags);
    }
    return tags;
  }

  DocumentProvider() {
    refreshAll();
  }

  Future<void> refreshAll() async {
    _isLoading = true;
    notifyListeners();

    await loadDocuments();
    await loadFavorites();
    await loadRecentHistory();
    await loadBookmarks();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDocuments() async {
    _allDocuments = await _db.getAllDocuments(
      sortBy: _sortBy,
      ascending: _sortAscending,
    );
    _applyFilterAndSearch();
  }

  Future<void> loadFavorites() async {
    _favoriteDocuments = await _db.getFavoriteDocuments();
  }

  Future<void> loadRecentHistory() async {
    _recentDocuments = await _db.getRecentDocuments(limit: 15);
    _readingHistory = await _db.getReadingHistory(limit: 50);
  }

  Future<void> loadBookmarks() async {
    _allBookmarks = await _db.getAllBookmarks();
  }

  Future<bool> importPdf() async {
    _isLoading = true;
    notifyListeners();

    final result = await PdfService.pickAndImportPdf();
    if (result != null) {
      final newDoc = PdfDocument(
        title: result['title'],
        filePath: result['filePath'],
        fileSize: result['fileSize'],
        totalPages: result['totalPages'],
        tags: ['Imported'],
      );

      final id = await _db.insertDocument(newDoc);
      if (id > 0) {
        await NotificationService().notifyDocumentAdded(newDoc.title);
        await refreshAll();
        return true;
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> addScannedPdf({
    required String filePath,
    required String title,
    List<String> tags = const ['Scanned'],
    String description = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    final file = File(filePath);
    final size = await file.length();
    final pages = await PdfService.countPdfPages(file);

    final newDoc = PdfDocument(
      title: title,
      filePath: filePath,
      fileSize: size,
      totalPages: pages,
      tags: tags,
      description: description,
    );

    final id = await _db.insertDocument(newDoc);
    if (id > 0) {
      await NotificationService().notifyDocumentAdded(title);
      await refreshAll();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> updateMetadata({
    required int id,
    required String title,
    required List<String> tags,
    required String description,
  }) async {
    final existing = await _db.getDocumentById(id);
    if (existing != null) {
      final updated = existing.copyWith(
        title: title.trim().isEmpty ? existing.title : title.trim(),
        tags: tags,
        description: description,
      );
      await _db.updateDocument(updated);
      await refreshAll();
    }
  }

  Future<void> deleteDocument(int id) async {
    final doc = await _db.getDocumentById(id);
    if (doc != null) {
      // Delete file from disk if exists
      try {
        final file = File(doc.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }

      await _db.deleteDocument(id);
      await refreshAll();
    }
  }

  Future<void> toggleFavorite(int id) async {
    final doc = await _db.getDocumentById(id);
    if (doc != null) {
      final newFav = !doc.isFavorite;
      await _db.toggleFavorite(id, newFav);
      await refreshAll();
    }
  }

  Future<void> updateReadingProgress({
    required int docId,
    required int currentPage,
    required int totalPages,
  }) async {
    await _db.updateReadingProgress(docId, currentPage, totalPages);
    await loadDocuments();
    await loadRecentHistory();
    notifyListeners();
  }

  Future<bool> addBookmark({
    required int docId,
    required int pageNumber,
    required String title,
    String note = '',
  }) async {
    final bookmark = Bookmark(
      documentId: docId,
      pageNumber: pageNumber,
      title: title,
      note: note,
    );
    final id = await _db.insertBookmark(bookmark);
    if (id > 0) {
      await loadBookmarks();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> removeBookmark(int bookmarkId) async {
    await _db.deleteBookmark(bookmarkId);
    await loadBookmarks();
    notifyListeners();
  }

  Future<bool> isPageBookmarked(int docId, int pageNumber) async {
    return await _db.isPageBookmarked(docId, pageNumber);
  }

  Future<void> clearHistory() async {
    await _db.clearReadingHistory();
    await loadRecentHistory();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilterAndSearch();
    notifyListeners();
  }

  void filterByTag(String? tag) {
    _selectedTag = tag;
    _applyFilterAndSearch();
    notifyListeners();
  }

  void setSorting(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    loadDocuments();
    notifyListeners();
  }

  void _applyFilterAndSearch() {
    _filteredDocuments = _allDocuments.where((doc) {
      final matchesQuery = _searchQuery.isEmpty ||
          doc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doc.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doc.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesTag = _selectedTag == null ||
          _selectedTag!.isEmpty ||
          doc.tags.contains(_selectedTag);

      return matchesQuery && matchesTag;
    }).toList();
  }
}
