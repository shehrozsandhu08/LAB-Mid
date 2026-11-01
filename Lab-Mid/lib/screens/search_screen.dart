import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/document_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_state.dart';
import 'document_details_screen.dart';
import 'export_screen.dart';
import 'pdf_to_image_screen.dart';
import 'pdf_viewer_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = context.watch<DocumentProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search by title, tag, or description...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          onChanged: (val) {
            docProvider.search(val);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                docProvider.search('');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tags Bar
          if (docProvider.allTags.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Tags'),
                    selected: docProvider.selectedTag == null,
                    onSelected: (_) => docProvider.filterByTag(null),
                  ),
                  const SizedBox(width: 8),
                  ...docProvider.allTags.map((tag) {
                    final isSelected = docProvider.selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
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

          Expanded(
            child: docProvider.documents.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'No Documents Found',
                    message: 'Try adjusting your search terms or selecting a different tag filter.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                        onDelete: () {
                          docProvider.deleteDocument(doc.id!);
                        },
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
    );
  }
}
