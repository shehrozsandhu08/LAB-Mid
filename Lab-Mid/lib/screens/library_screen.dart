import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pdf_document.dart';
import '../providers/document_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_state.dart';
import 'document_details_screen.dart';
import 'export_screen.dart';
import 'pdf_to_image_screen.dart';
import 'pdf_viewer_screen.dart';
import 'search_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  void _showSortDialog(BuildContext context) {
    final docProvider = context.read<DocumentProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Sort Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('Recently Added (Newest first)'),
                onTap: () {
                  docProvider.setSorting('created_at', false);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Title (A to Z)'),
                onTap: () {
                  docProvider.setSorting('title', true);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.data_usage),
                title: const Text('File Size (Largest first)'),
                onTap: () {
                  docProvider.setSorting('file_size', false);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_stories),
                title: const Text('Pages (Most pages first)'),
                onTap: () {
                  docProvider.setSorting('total_pages', false);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PdfDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to remove "${doc.title}" and its local file?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<DocumentProvider>().deleteDocument(doc.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Library',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Documents',
            onPressed: () => _showSortDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export Hub',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExportScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => docProvider.refreshAll(),
        child: Column(
          children: [
            // Tag filtering row
            if (docProvider.allTags.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: docProvider.selectedTag == null,
                      onSelected: (_) => docProvider.filterByTag(null),
                    ),
                    const SizedBox(width: 6),
                    ...docProvider.allTags.map((tag) {
                      final isSelected = docProvider.selectedTag == tag;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: FilterChip(
                          label: Text('#$tag'),
                          selected: isSelected,
                          onSelected: (_) => docProvider.filterByTag(isSelected ? null : tag),
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // Document count bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${docProvider.documents.length} ${docProvider.documents.length == 1 ? 'Document' : 'Documents'}',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (docProvider.selectedTag != null)
                    Text(
                      'Filtered by #${docProvider.selectedTag}',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                    ),
                ],
              ),
            ),

            // Main documents list
            Expanded(
              child: docProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : docProvider.documents.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.folder_open,
                          title: 'No Documents in Library',
                          message: 'Tap "Import PDF" below or use the Scanner tab to import documents from your device.',
                          actionLabel: 'Import PDF',
                          onAction: () async {
                            final imported = await docProvider.importPdf();
                            if (imported && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('PDF imported into library!')),
                              );
                            }
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80, top: 4),
                          itemCount: docProvider.documents.length,
                          itemBuilder: (context, index) {
                            final doc = docProvider.documents[index];
                            return DocumentCard(
                              document: doc,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PdfViewerScreen(document: doc),
                                  ),
                                );
                              },
                              onFavoriteToggle: () => docProvider.toggleFavorite(doc.id!),
                              onEdit: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DocumentDetailsScreen(document: doc),
                                  ),
                                );
                              },
                              onDelete: () => _confirmDelete(context, doc),
                              onConvertToImage: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PdfToImageScreen(document: doc),
                                  ),
                                );
                              },
                              onExport: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ExportScreen(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Import PDF'),
        onPressed: () async {
          final imported = await docProvider.importPdf();
          if (imported && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF document imported successfully!')),
            );
          }
        },
      ),
    );
  }
}
