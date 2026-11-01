import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/pdf_document.dart';
import '../providers/document_provider.dart';
import '../providers/theme_provider.dart';
import 'document_details_screen.dart';
import 'pdf_to_image_screen.dart';

class PdfViewerScreen extends StatefulWidget {
  final PdfDocument document;
  final int initialPage;

  const PdfViewerScreen({
    super.key,
    required this.document,
    this.initialPage = 1,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  late int _currentPage;
  int _totalPages = 1;
  bool _isBookmarked = false;
  bool _isControlsVisible = true;
  String _activeReadingTheme = 'normal'; // 'normal', 'sepia', 'night'

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _currentPage = widget.initialPage > 0 ? widget.initialPage : widget.document.lastReadPage;
    _totalPages = widget.document.totalPages > 0 ? widget.document.totalPages : 1;
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final docProvider = context.read<DocumentProvider>();
    final bookmarked = await docProvider.isPageBookmarked(widget.document.id!, _currentPage);
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
      });
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    setState(() {
      _currentPage = details.newPageNumber;
    });
    _checkBookmarkStatus();

    // Persist progress to SQLite
    final docProvider = context.read<DocumentProvider>();
    docProvider.updateReadingProgress(
      docId: widget.document.id!,
      currentPage: _currentPage,
      totalPages: _totalPages,
    );
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPages = details.document.pages.count;
    });

    if (_currentPage > 1) {
      _pdfViewerController.jumpToPage(_currentPage);
    }
  }

  void _showJumpToPageDialog() {
    final controller = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jump to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Page Number (1 - $_totalPages)',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _pdfViewerController.jumpToPage(page);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a page between 1 and $_totalPages')),
                );
              }
            },
            child: const Text('Jump'),
          ),
        ],
      ),
    );
  }

  void _toggleBookmark() async {
    final docProvider = context.read<DocumentProvider>();
    if (_isBookmarked) {
      // Find existing bookmark and remove
      final bookmarks = docProvider.allBookmarks;
      final existing = bookmarks.firstWhere(
        (b) => b.documentId == widget.document.id && b.pageNumber == _currentPage,
        orElse: () => bookmarks.first,
      );
      if (existing.id != null) {
        await docProvider.removeBookmark(existing.id!);
        setState(() => _isBookmarked = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bookmark removed')),
          );
        }
      }
    } else {
      final titleController = TextEditingController(text: 'Page $_currentPage');
      final noteController = TextEditingController();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Bookmark Page $_currentPage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final success = await docProvider.addBookmark(
                  docId: widget.document.id!,
                  pageNumber: _currentPage,
                  title: titleController.text.trim().isEmpty
                      ? 'Page $_currentPage'
                      : titleController.text.trim(),
                  note: noteController.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (success) {
                  setState(() => _isBookmarked = true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Page bookmarked successfully')),
                    );
                  }
                }
              },
              child: const Text('Save Bookmark'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.document.filePath);
    final themeProvider = context.watch<ThemeProvider>();

    // Apply color filter according to selected reading background theme
    ColorFilter? filter;
    if (_activeReadingTheme == 'sepia') {
      filter = const ColorFilter.matrix(<double>[
        0.393, 0.769, 0.189, 0, 0,
        0.349, 0.686, 0.168, 0, 0,
        0.272, 0.534, 0.131, 0, 0,
        0,     0,     0,     1, 0,
      ]);
    } else if (_activeReadingTheme == 'night') {
      filter = const ColorFilter.matrix(<double>[
        -1,  0,  0, 0, 255,
         0, -1,  0, 0, 255,
         0,  0, -1, 0, 255,
         0,  0,  0, 1, 0,
      ]);
    }

    return Scaffold(
      backgroundColor: themeProvider.readingBackgroundColor,
      appBar: _isControlsVisible
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Jump to Page',
                  onPressed: _showJumpToPageDialog,
                ),
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? Colors.amber : null,
                  ),
                  tooltip: _isBookmarked ? 'Bookmarked' : 'Add Bookmark',
                  onPressed: _toggleBookmark,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.palette_outlined),
                  tooltip: 'Reading Theme',
                  onSelected: (mode) {
                    setState(() {
                      _activeReadingTheme = mode;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'normal',
                      child: Text('Normal (Day)'),
                    ),
                    const PopupMenuItem(
                      value: 'sepia',
                      child: Text('Sepia (Warm)'),
                    ),
                    const PopupMenuItem(
                      value: 'night',
                      child: Text('Inverted (Night Mode)'),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'details':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DocumentDetailsScreen(document: widget.document),
                          ),
                        );
                        break;
                      case 'convert':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfToImageScreen(document: widget.document),
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Text('Document Details'),
                    ),
                    const PopupMenuItem(
                      value: 'convert',
                      child: Text('Convert to Images'),
                    ),
                  ],
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isControlsVisible = !_isControlsVisible;
          });
        },
        child: !file.existsSync()
            ? const Center(child: Text('File not found on device storage.'))
            : ColorFiltered(
                colorFilter: filter ??
                    const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                child: SfPdfViewer.file(
                  file,
                  controller: _pdfViewerController,
                  onPageChanged: _onPageChanged,
                  onDocumentLoaded: _onDocumentLoaded,
                  enableDoubleTapZooming: true,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                ),
              ),
      ),
      bottomNavigationBar: _isControlsVisible
          ? Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Theme.of(context).bottomAppBarTheme.color ?? Theme.of(context).cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    tooltip: 'First Page',
                    onPressed: () => _pdfViewerController.jumpToPage(1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigate_before),
                    tooltip: 'Previous Page',
                    onPressed: () => _pdfViewerController.previousPage(),
                  ),
                  InkWell(
                    onTap: _showJumpToPageDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigate_next),
                    tooltip: 'Next Page',
                    onPressed: () => _pdfViewerController.nextPage(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    tooltip: 'Last Page',
                    onPressed: () => _pdfViewerController.jumpToPage(_totalPages),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
