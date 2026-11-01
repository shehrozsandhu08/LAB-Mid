import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/pdf_document.dart';
import '../providers/document_provider.dart';
import 'export_screen.dart';
import 'pdf_to_image_screen.dart';
import 'pdf_viewer_screen.dart';

class DocumentDetailsScreen extends StatefulWidget {
  final PdfDocument document;

  const DocumentDetailsScreen({super.key, required this.document});

  @override
  State<DocumentDetailsScreen> createState() => _DocumentDetailsScreenState();
}

class _DocumentDetailsScreenState extends State<DocumentDetailsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _tagInputController;
  late List<String> _tags;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document.title);
    _descController = TextEditingController(text: widget.document.description);
    _tagInputController = TextEditingController();
    _tags = List.from(widget.document.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _tagInputController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagInputController.clear();
        _hasChanges = true;
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    final docProvider = context.read<DocumentProvider>();
    await docProvider.updateMetadata(
      id: widget.document.id!,
      title: _titleController.text.trim(),
      tags: _tags,
      description: _descController.text.trim(),
    );

    setState(() {
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document metadata updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Details & Metadata'),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save Changes',
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with File Stats
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.picture_as_pdf, color: Colors.red.shade800, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.document.title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Size: ${widget.document.formattedFileSize}  •  ${widget.document.totalPages} Pages',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'Added: ${DateFormat('dd MMM yyyy, hh:mm a').format(widget.document.createdAt)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Edit Title
            Text('Document Title', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter document title',
                prefixIcon: Icon(Icons.title),
              ),
              onChanged: (_) => setState(() => _hasChanges = true),
            ),
            const SizedBox(height: 18),

            // Tags Management
            Text('Tags & Categories', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagInputController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Add a tag (e.g. Study, Work, Notes)',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addTag,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text('#$tag'),
                  onDeleted: () => _removeTag(tag),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Description / Notes
            Text('Description / Annotations', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter document description or personal notes...',
              ),
              onChanged: (_) => setState(() => _hasChanges = true),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Text('Quick Operations', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Read PDF'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(document: widget.document),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('To Images'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfToImageScreen(document: widget.document),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Export Hub'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExportScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    onPressed: _hasChanges ? _saveChanges : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
