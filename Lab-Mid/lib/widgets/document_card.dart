import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pdf_document.dart';
import 'progress_bar.dart';

class DocumentCard extends StatelessWidget {
  final PdfDocument document;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onConvertToImage;
  final VoidCallback onExport;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onConvertToImage,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF Document icon badge
                  Container(
                    width: 48,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 28),
                          Text(
                            'PDF',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and metadata info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              document.formattedFileSize,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                            const Text(' • '),
                            Text(
                              '${document.totalPages} pages',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                            if (document.lastReadTime != null) ...[
                              const Text(' • '),
                              Text(
                                DateFormat('MMM d').format(document.lastReadTime!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Favorite toggle
                  IconButton(
                    icon: Icon(
                      document.isFavorite ? Icons.star : Icons.star_border,
                      color: document.isFavorite ? Colors.amber.shade700 : Colors.grey,
                    ),
                    onPressed: onFavoriteToggle,
                    tooltip: document.isFavorite ? 'Remove Favorite' : 'Mark as Favorite',
                  ),

                  // Menu actions
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      switch (val) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'convert':
                          onConvertToImage();
                          break;
                        case 'export':
                          onExport();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 10),
                            Text('Edit Metadata'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'convert',
                        child: Row(
                          children: [
                            Icon(Icons.image_outlined, size: 20),
                            SizedBox(width: 10),
                            Text('Convert to Images'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined, size: 20),
                            SizedBox(width: 10),
                            Text('Export / Share'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Tags chips
              if (document.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: document.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Reading Progress Bar
              const SizedBox(height: 10),
              ReadingProgressBar(
                progress: document.progressPercentage,
                currentPage: document.lastReadPage,
                totalPages: document.totalPages,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
