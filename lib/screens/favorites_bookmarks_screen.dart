import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bookmark.dart';
import '../models/pdf_document.dart';
import '../providers/document_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_state.dart';
import 'document_details_screen.dart';
import 'export_screen.dart';
import 'pdf_to_image_screen.dart';
import 'pdf_viewer_screen.dart';

class FavoritesBookmarksScreen extends StatefulWidget {
  const FavoritesBookmarksScreen({super.key});

  @override
  State<FavoritesBookmarksScreen> createState() => _FavoritesBookmarksScreenState();
}

class _FavoritesBookmarksScreenState extends State<FavoritesBookmarksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openDocumentAtPage(BuildContext context, Bookmark bookmark) {
    final docProvider = context.read<DocumentProvider>();
    final doc = docProvider.allDocuments.firstWhere(
      (d) => d.id == bookmark.documentId,
      orElse: () => PdfDocument(
        id: bookmark.documentId,
        title: bookmark.documentTitle ?? 'Document',
        filePath: bookmark.documentPath ?? '',
        fileSize: 0,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          document: doc,
          initialPage: bookmark.pageNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites & Bookmarks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.star),
              text: 'Favorites (${docProvider.favoriteDocuments.length})',
            ),
            Tab(
              icon: const Icon(Icons.bookmark),
              text: 'Bookmarks (${docProvider.allBookmarks.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Favorite Documents
          docProvider.favoriteDocuments.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.star_border,
                  title: 'No Favorite Documents Yet',
                  message: 'Star important documents in your library for quick one-tap access.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docProvider.favoriteDocuments.length,
                  itemBuilder: (context, index) {
                    final doc = docProvider.favoriteDocuments[index];
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

          // Tab 2: Bookmarked Pages
          docProvider.allBookmarks.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.bookmark_border,
                  title: 'No Bookmarked Pages',
                  message: 'When reading a PDF, tap the bookmark icon to save specific pages here for future reference.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  itemCount: docProvider.allBookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = docProvider.allBookmarks[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber.shade100,
                          child: Text(
                            'p.${bookmark.pageNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                        title: Text(
                          bookmark.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookmark.documentTitle ?? 'Document #${bookmark.documentId}',
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                            ),
                            if (bookmark.note.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                bookmark.note,
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Remove Bookmark',
                          onPressed: () {
                            docProvider.removeBookmark(bookmark.id!);
                          },
                        ),
                        onTap: () => _openDocumentAtPage(context, bookmark),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PdfDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to remove "${doc.title}" from your library?'),
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
}
