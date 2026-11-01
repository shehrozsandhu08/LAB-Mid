import 'dart:io';
import 'package:flutter/material.dart';
import '../models/pdf_document.dart';
import '../services/pdf_service.dart';

class PdfToImageScreen extends StatefulWidget {
  final PdfDocument document;

  const PdfToImageScreen({super.key, required this.document});

  @override
  State<PdfToImageScreen> createState() => _PdfToImageScreenState();
}

class _PdfToImageScreenState extends State<PdfToImageScreen> {
  bool _convertAll = true;
  final TextEditingController _pageInputController = TextEditingController();
  bool _isConverting = false;
  List<String> _convertedImages = [];

  @override
  void dispose() {
    _pageInputController.dispose();
    super.dispose();
  }

  Future<void> _performConversion() async {
    List<int>? pageNumbers;

    if (!_convertAll) {
      final input = _pageInputController.text.trim();
      if (input.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please specify page numbers (e.g. 1, 2, 5)')),
        );
        return;
      }

      try {
        pageNumbers = input
            .split(',')
            .map((e) => int.parse(e.trim()))
            .where((p) => p >= 1 && p <= widget.document.totalPages)
            .toList();

        if (pageNumbers.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid pages. Document has ${widget.document.totalPages} pages.')),
          );
          return;
        }
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid format. Use numbers separated by commas (e.g. 1, 2, 3)')),
        );
        return;
      }
    }

    setState(() {
      _isConverting = true;
      _convertedImages = [];
    });

    try {
      final images = await PdfService.convertPdfToImages(
        pdfPath: widget.document.filePath,
        pageNumbers: pageNumbers,
      );

      setState(() {
        _convertedImages = images;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Converted ${images.length} pages to high-resolution PNG images!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversion failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConverting = false);
      }
    }
  }

  void _shareAllImages() {
    if (_convertedImages.isEmpty) return;
    PdfService.shareFiles(
      _convertedImages,
      subject: 'Converted Pages - ${widget.document.title}',
      text: 'Converted pages from ${widget.document.title}',
    );
  }

  void _shareSingleImage(String path, int pageIndex) {
    PdfService.shareFiles(
      [path],
      subject: '${widget.document.title} - Page $pageIndex',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF to Image Converter'),
        actions: [
          if (_convertedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share All Images',
              onPressed: _shareAllImages,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target document summary
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
                title: Text(widget.document.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${widget.document.totalPages} Pages • ${widget.document.formattedFileSize}'),
              ),
            ),
            const SizedBox(height: 16),

            // Selection mode
            Text('Pages to Convert', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            RadioListTile<bool>(
              value: true,
              groupValue: _convertAll,
              title: const Text('Convert All Pages'),
              subtitle: Text('Renders all ${widget.document.totalPages} pages into images'),
              onChanged: (val) => setState(() => _convertAll = val!),
            ),
            RadioListTile<bool>(
              value: false,
              groupValue: _convertAll,
              title: const Text('Selected Pages Only'),
              subtitle: const Text('Specify exact page numbers (e.g. 1, 3, 5)'),
              onChanged: (val) => setState(() => _convertAll = val!),
            ),

            if (!_convertAll) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _pageInputController,
                  decoration: InputDecoration(
                    labelText: 'Page numbers (1 to ${widget.document.totalPages})',
                    hintText: 'e.g. 1, 2, 4',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.transform),
                label: Text(_isConverting ? 'Converting Pages...' : 'Convert to Images'),
                onPressed: _isConverting ? null : _performConversion,
              ),
            ),
            const SizedBox(height: 24),

            if (_isConverting) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Rendering high quality page raster images...'),
                  ],
                ),
              ),
            ],

            if (_convertedImages.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Converted Images (${_convertedImages.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share All'),
                    onPressed: _shareAllImages,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _convertedImages.length,
                itemBuilder: (context, index) {
                  final path = _convertedImages[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(path), fit: BoxFit.cover),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withOpacity(0.65),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Page ${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, size: 18, color: Colors.white),
                                  onPressed: () => _shareSingleImage(path, index + 1),
                                  tooltip: 'Share Image',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
}
