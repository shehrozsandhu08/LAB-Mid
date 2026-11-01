import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  /// Picks a PDF file from device storage, copies it to the app storage directory,
  /// and returns a Map containing details: title, filePath, fileSize, totalPages.
  static Future<Map<String, dynamic>?> pickAndImportPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.single.path == null) {
        return null;
      }

      final sourcePath = result.files.single.path!;
      final sourceFile = File(sourcePath);
      final fileName = result.files.single.name;
      final fileSize = await sourceFile.length();

      // Copy to persistent application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final destinationDir = Directory(p.join(appDir.path, 'pdf_library'));
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final targetPath = p.join(destinationDir.path, uniqueName);
      final copiedFile = await sourceFile.copy(targetPath);

      // Estimate total pages by counting /Type /Page occurrences in PDF bytes
      int totalPages = await countPdfPages(copiedFile);

      return {
        'title': p.basenameWithoutExtension(fileName),
        'filePath': copiedFile.path,
        'fileSize': fileSize,
        'totalPages': totalPages,
      };
    } catch (e) {
      debugPrint('Error picking PDF: $e');
      return null;
    }
  }

  /// Create a multi-page PDF from a list of scanned/captured images
  static Future<String?> createPdfFromImages({
    required List<File> imageFiles,
    required String title,
  }) async {
    try {
      if (imageFiles.isEmpty) return null;

      final pdf = pw.Document();

      for (var file in imageFiles) {
        final imageBytes = await file.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(appDir.path, 'scanned_pdfs'));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final sanitizedTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName = '${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(p.join(targetDir.path, fileName));

      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      debugPrint('Error creating PDF from images: $e');
      return null;
    }
  }

  /// Convert PDF pages to PNG/JPEG images and return paths of generated images
  static Future<List<String>> convertPdfToImages({
    required String pdfPath,
    List<int>? pageNumbers, // 1-based indices, or null for all
  }) async {
    final List<String> generatedImagePaths = [];
    try {
      final file = File(pdfPath);
      if (!await file.exists()) return generatedImagePaths;

      final bytes = await file.readAsBytes();
      final tempDir = await getTemporaryDirectory();
      final exportDir = Directory(p.join(tempDir.path, 'converted_images'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      int currentIndex = 1;
      await for (final page in Printing.raster(bytes, dpi: 150)) {
        if (pageNumbers == null || pageNumbers.contains(currentIndex)) {
          final pngBytes = await page.toPng();
          final imgPath = p.join(
            exportDir.path,
            'page_${currentIndex}_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          final imgFile = File(imgPath);
          await imgFile.writeAsBytes(pngBytes);
          generatedImagePaths.add(imgFile.path);
        }
        currentIndex++;
      }
    } catch (e) {
      debugPrint('Error converting PDF to images: $e');
    }
    return generatedImagePaths;
  }

  /// Share one or more files with other apps (Email, WhatsApp, Drive, etc.)
  static Future<void> shareFiles(List<String> filePaths, {String? text, String? subject}) async {
    if (filePaths.isEmpty) return;
    final xFiles = filePaths.map((path) => XFile(path)).toList();
    await Share.shareXFiles(xFiles, text: text, subject: subject);
  }

  /// Helper to estimate page count from PDF binary stream safely
  static Future<int> countPdfPages(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final content = String.fromCharCodes(bytes);
      final regExp = RegExp(r'/Type\s*/Page\b');
      final count = regExp.allMatches(content).length;
      return count > 0 ? count : 1;
    } catch (_) {
      return 1;
    }
  }
}
