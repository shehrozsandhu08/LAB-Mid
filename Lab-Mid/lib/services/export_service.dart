import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/bookmark.dart';
import '../models/pdf_document.dart';
import '../models/reading_history.dart';

class ExportService {
  /// Export document metadata to CSV file
  static Future<String> exportMetadataToCsv(List<PdfDocument> documents) async {
    final List<List<dynamic>> rows = [
      [
        'ID',
        'Title',
        'File Path',
        'File Size (Bytes)',
        'Total Pages',
        'Last Read Page',
        'Progress (%)',
        'Last Read Time',
        'Is Favorite',
        'Tags',
        'Description',
        'Created At'
      ]
    ];

    for (var doc in documents) {
      rows.add([
        doc.id ?? '',
        doc.title,
        doc.filePath,
        doc.fileSize,
        doc.totalPages,
        doc.lastReadPage,
        (doc.progressPercentage * 100).toStringAsFixed(1),
        doc.lastReadTime?.toIso8601String() ?? 'Never',
        doc.isFavorite ? 'Yes' : 'No',
        doc.tags.join('; '),
        doc.description,
        doc.createdAt.toIso8601String(),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(
      dir.path,
      'pdf_metadata_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
    );
    final file = File(filePath);
    await file.writeAsString(csvData);
    return file.path;
  }

  /// Export bookmarks list to CSV file
  static Future<String> exportBookmarksToCsv(List<Bookmark> bookmarks) async {
    final List<List<dynamic>> rows = [
      [
        'Bookmark ID',
        'Document ID',
        'Document Title',
        'Page Number',
        'Bookmark Title',
        'Note',
        'Created At'
      ]
    ];

    for (var b in bookmarks) {
      rows.add([
        b.id ?? '',
        b.documentId,
        b.documentTitle ?? 'Unknown Document',
        b.pageNumber,
        b.title,
        b.note,
        b.createdAt.toIso8601String(),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(
      dir.path,
      'bookmarks_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
    );
    final file = File(filePath);
    await file.writeAsString(csvData);
    return file.path;
  }

  /// Export reading history to CSV file
  static Future<String> exportHistoryToCsv(List<ReadingHistory> history) async {
    final List<List<dynamic>> rows = [
      [
        'History ID',
        'Document ID',
        'Document Title',
        'Page Read',
        'Duration (Seconds)',
        'Timestamp'
      ]
    ];

    for (var h in history) {
      rows.add([
        h.id ?? '',
        h.documentId,
        h.documentTitle ?? 'Document #${h.documentId}',
        h.pageNumber,
        h.durationSeconds,
        h.timestamp.toIso8601String(),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(
      dir.path,
      'reading_history_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
    );
    final file = File(filePath);
    await file.writeAsString(csvData);
    return file.path;
  }

  /// Generate a formal PDF summary report containing Library, Bookmarks & History
  static Future<String> generatePdfReport({
    required List<PdfDocument> documents,
    required List<Bookmark> bookmarks,
    required List<ReadingHistory> history,
  }) async {
    final pdf = pw.Document();
    final nowFormatted = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PDF Reader Application - Report',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text(nowFormatted,
                      style: const pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Statistics Overview
            pw.Text('Library Summary Overview',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox('Total Documents', documents.length.toString()),
                _buildStatBox('Favorites',
                    documents.where((d) => d.isFavorite).length.toString()),
                _buildStatBox('Total Bookmarks', bookmarks.length.toString()),
                _buildStatBox('History Entries', history.length.toString()),
              ],
            ),
            pw.SizedBox(height: 20),

            // Documents Table
            pw.Text('Document Catalog',
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Title', 'Size', 'Pages', 'Last Read', 'Progress'],
              data: documents.map((doc) => [
                doc.title,
                doc.formattedFileSize,
                '${doc.lastReadPage}/${doc.totalPages}',
                doc.lastReadTime != null
                    ? DateFormat('dd/MM/yy').format(doc.lastReadTime!)
                    : 'Unread',
                '${(doc.progressPercentage * 100).toStringAsFixed(0)}%',
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),

            // Bookmarks Section
            pw.Text('Saved Bookmarks',
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            bookmarks.isEmpty
                ? pw.Text('No bookmarks recorded.', style: const pw.TextStyle(color: PdfColors.grey600))
                : pw.TableHelper.fromTextArray(
                    headers: ['Document', 'Page', 'Title', 'Note'],
                    data: bookmarks.take(15).map((b) => [
                      b.documentTitle ?? 'Doc #${b.documentId}',
                      'Page ${b.pageNumber}',
                      b.title,
                      b.note.isEmpty ? '-' : b.note,
                    ]).toList(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                  ),
          ];
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(
      dir.path,
      'reader_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 2),
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  /// Share file via system sharing dialog (supporting Email, WhatsApp, etc.)
  static Future<void> shareFile(String filePath, {String? subject, String? text}) async {
    final xFile = XFile(filePath);
    await Share.shareXFiles([xFile], subject: subject, text: text);
  }
}
