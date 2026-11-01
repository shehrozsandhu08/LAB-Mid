import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/document_provider.dart';
import '../services/pdf_service.dart';
import 'pdf_viewer_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final List<File> _scannedPages = [];
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagController = TextEditingController(text: 'Scanned');
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Scanned_Doc_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _scannedPages.add(File(photo.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera/Gallery error: $e')),
        );
      }
    }
  }

  void _removePage(int index) {
    setState(() {
      _scannedPages.removeAt(index);
    });
  }

  Future<void> _generateAndSavePdf() async {
    if (_scannedPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture or select at least one page first.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final title = _titleController.text.trim().isEmpty
          ? 'Scanned_Document'
          : _titleController.text.trim();

      // Convert captured images to PDF via PdfService
      final pdfPath = await PdfService.createPdfFromImages(
        imageFiles: _scannedPages,
        title: title,
      );

      if (pdfPath != null) {
        final docProvider = context.read<DocumentProvider>();
        final tags = _tagController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();

        final added = await docProvider.addScannedPdf(
          filePath: pdfPath,
          title: title,
          tags: tags.isEmpty ? ['Scanned'] : tags,
          description: 'Document scanned via in-app Camera scanner on ${DateFormat('dd MMM yyyy').format(DateTime.now())}.',
        );

        if (mounted) {
          setState(() {
            _scannedPages.clear();
            _titleController.text = 'Scanned_Doc_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF document created and saved to library!')),
          );

          if (added && docProvider.documents.isNotEmpty) {
            final latest = docProvider.documents.first;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfViewerScreen(document: latest),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Scanner'),
        actions: [
          if (_scannedPages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All',
              onPressed: () {
                setState(() => _scannedPages.clear());
              },
            ),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Compiling images into PDF document...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Capture options
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Take Photo'),
                                  onPressed: () => _captureImage(ImageSource.camera),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('From Gallery'),
                                  onPressed: () => _captureImage(ImageSource.gallery),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Scan multi-page documents by capturing pages sequentially.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata Inputs
                  if (_scannedPages.isNotEmpty) ...[
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Document Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Scanned Pages (${_scannedPages.length})',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Save as PDF'),
                          onPressed: _generateAndSavePdf,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Grid of Scanned Pages
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollbyPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _scannedPages.length,
                      itemBuilder: (context, index) {
                        final file = _scannedPages[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                file,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => _removePage(index),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 48),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.document_scanner_outlined, size: 72, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No scanned pages yet',
                            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Use the camera or gallery buttons above to scan pages.',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
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
