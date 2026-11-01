import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/document_provider.dart';
import '../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isExporting = false;
  String? _lastExportedPath;

  Future<void> _exportMetadataCsv() async {
    setState(() => _isExporting = true);
    try {
      final docProvider = context.read<DocumentProvider>();
      final path = await ExportService.exportMetadataToCsv(docProvider.allDocuments);
      setState(() => _lastExportedPath = path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Metadata exported to CSV!'),
            action: SnackBarAction(
              label: 'Share / Email',
              onPressed: () => ExportService.shareFile(
                path,
                subject: 'PDF Library Metadata Export',
                text: 'Attached is the exported CSV metadata for my PDF documents.',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportBookmarksCsv() async {
    setState(() => _isExporting = true);
    try {
      final docProvider = context.read<DocumentProvider>();
      final path = await ExportService.exportBookmarksToCsv(docProvider.allBookmarks);
      setState(() => _lastExportedPath = path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bookmarks exported to CSV!'),
            action: SnackBarAction(
              label: 'Share / Email',
              onPressed: () => ExportService.shareFile(
                path,
                subject: 'Saved Bookmarks Export',
                text: 'Attached is the exported CSV of my saved page bookmarks.',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportHistoryCsv() async {
    setState(() => _isExporting = true);
    try {
      final docProvider = context.read<DocumentProvider>();
      final path = await ExportService.exportHistoryToCsv(docProvider.readingHistory);
      setState(() => _lastExportedPath = path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reading history exported to CSV!'),
            action: SnackBarAction(
              label: 'Share / Email',
              onPressed: () => ExportService.shareFile(
                path,
                subject: 'Reading History Export',
                text: 'Attached is the exported CSV log of my reading history sessions.',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportFullPdfReport() async {
    setState(() => _isExporting = true);
    try {
      final docProvider = context.read<DocumentProvider>();
      final path = await ExportService.generatePdfReport(
        documents: docProvider.allDocuments,
        bookmarks: docProvider.allBookmarks,
        history: docProvider.readingHistory,
      );
      setState(() => _lastExportedPath = path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Full PDF Report generated successfully!'),
            action: SnackBarAction(
              label: 'Share / Email',
              onPressed: () => ExportService.shareFile(
                path,
                subject: 'PDF Reader Comprehensive Summary Report',
                text: 'Please find attached the comprehensive PDF report generated from PDF Reader & Utility App.',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report generation error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Export & Sharing Hub'),
      ),
      body: _isExporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating export package...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.output, size: 36, color: theme.colorScheme.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Export your PDF metadata, reading logs, and bookmarks into CSV or a formal PDF report. You can send exports directly via Email or other apps.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text('Export Formats', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Option 1: Full PDF Summary Report
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.picture_as_pdf, color: Colors.white),
                      ),
                      title: const Text('Comprehensive PDF Report'),
                      subtitle: const Text('Formatted document overview, reading stats, bookmarks, and catalog.'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _exportFullPdfReport,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option 2: Document Metadata CSV
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.table_chart, color: Colors.white),
                      ),
                      title: const Text('Document Metadata (CSV)'),
                      subtitle: const Text('Spreadsheet of titles, tags, file sizes, pages, and reading status.'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _exportMetadataCsv,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option 3: Bookmarks CSV
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.amber,
                        child: Icon(Icons.bookmark, color: Colors.white),
                      ),
                      title: const Text('Bookmarks (CSV)'),
                      subtitle: const Text('Export bookmarked pages, notes, titles, and creation timestamps.'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _exportBookmarksCsv,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option 4: Reading History CSV
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.history, color: Colors.white),
                      ),
                      title: const Text('Reading History Logs (CSV)'),
                      subtitle: const Text('Complete log of reading sessions, pages read, and dates.'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _exportHistoryCsv,
                    ),
                  ),

                  if (_lastExportedPath != null) ...[
                    const SizedBox(height: 24),
                    Text('Latest Exported File', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _lastExportedPath!,
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share),
                            tooltip: 'Share / Email',
                            onPressed: () => ExportService.shareFile(_lastExportedPath!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
