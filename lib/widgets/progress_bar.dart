import 'package:flutter/material.dart';

class ReadingProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int currentPage;
  final int totalPages;
  final bool showLabel;

  const ReadingProgressBar({
    super.key,
    required this.progress,
    required this.currentPage,
    required this.totalPages,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentage = (clampedProgress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page $currentPage of $totalPages',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clampedProgress,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              clampedProgress >= 1.0 ? Colors.green : theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
