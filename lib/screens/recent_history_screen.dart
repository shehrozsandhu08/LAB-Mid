import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/pdf_document.dart';
import '../providers/document_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/progress_bar.dart';
import 'pdf_viewer_screen.dart';

class RecentHistoryScreen extends StatelessWidget {
  const RecentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent & Reading History'),
        actions: [
          if (docProvider.readingHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear History',
              onPressed: () => _confirmClearHistory(context),
            ),
        ],
      ),
      body: docProvider.recentDocuments.isEmpty && docProvider.readingHistory.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.history,
              title: 'No Reading History',
              message: 'When you open and read documents, your reading progress and history sessions will appear here.',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resume Reading Section
                  if (docProvider.recentDocuments.isNotEmpty) ...[
                    Text(
                      'Resume Reading',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docProvider.recentDocuments.length,
                      itemBuilder: (context, index) {
                        final doc = docProvider.recentDocuments[index];
                        return Card(
                          elevation: 1.5,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doc.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (doc.lastReadTime != null)
                                            Text(
                                              'Last read ${DateFormat('MMM d, hh:mm a').format(doc.lastReadTime!)}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                            ),
                                        ],
                                      ),
                                    ),
                                    FilledButton.tonalIcon(
                                      icon: const Icon(Icons.play_arrow, size: 16),
                                      label: const Text('Resume'),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PdfViewerScreen(
                                              document: doc,
                                              initialPage: doc.lastReadPage,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ReadingProgressBar(
                                  progress: doc.progressPercentage,
                                  currentPage: doc.lastReadPage,
                                  totalPages: doc.totalPages,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Detailed History Timeline
                  if (docProvider.readingHistory.isNotEmpty) ...[
                    Text(
                      'Session History Log',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docProvider.readingHistory.length,
                      itemBuilder: (context, index) {
                        final item = docProvider.readingHistory[index];
                        return Card(
                          elevation: 0.5,
                          margin: const EdgeInsets.only(bottom: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                              child: Icon(Icons.menu_book, color: theme.colorScheme.primary, size: 20),
                            ),
                            title: Text(
                              item.documentTitle ?? 'Document #${item.documentId}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Read Page ${item.pageNumber} • ${DateFormat('MMM d, yyyy - hh:mm a').format(item.timestamp)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () {
                              final doc = docProvider.allDocuments.firstWhere(
                                (d) => d.id == item.documentId,
                                orElse: () => PdfDocument(
                                  id: item.documentId,
                                  title: item.documentTitle ?? 'Document',
                                  filePath: item.documentPath ?? '',
                                  fileSize: 0,
                                ),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PdfViewerScreen(
                                    document: doc,
                                    initialPage: item.pageNumber,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Reading History'),
        content: const Text('Are you sure you want to clear all reading session logs? Your documents will remain safe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<DocumentProvider>().clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
