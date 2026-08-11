import 'package:flutter/material.dart';
import '../models/verse.dart';
import '../models/tag.dart';
import '../models/commentary.dart';
import 'highlighted_text.dart';

class VerseTile extends StatelessWidget {
  final Verse verse;
  final bool hasCommentary;
  final String? commentaryPreview;
  final List<Highlight> commentaryHighlights;
  final List<HashTag> hashtags;
  final List<Tag> tags;
  final VoidCallback onTap;
  final Function(Tag tag) onTagTap;

  const VerseTile({
    super.key,
    required this.verse,
    required this.hasCommentary,
    this.commentaryPreview,
    this.commentaryHighlights = const [],
    this.hashtags = const [],
    required this.tags,
    required this.onTap,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasExtra = hasCommentary ||
        tags.isNotEmpty ||
        commentaryHighlights.isNotEmpty ||
        hashtags.isNotEmpty;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: hasExtra ? 2 : 0,
      color: hasCommentary
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Verse number + text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${verse.verse}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HighlightedText(
                      text: verse.text,
                      highlights: commentaryHighlights,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),

              // 2. Hashtags
              if (hashtags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: hashtags.map((h) {
                    final isRed = h.color.toLowerCase() == 'red';

                    final bg = isRed
                        ? (isDark
                            ? Colors.red.shade900.withOpacity(0.45)
                            : Colors.red.shade100)
                        : (isDark
                            ? Colors.green.shade900.withOpacity(0.45)
                            : Colors.green.shade100);

                    final fg = isRed
                        ? (isDark ? Colors.red.shade200 : Colors.red.shade800)
                        : (isDark
                            ? Colors.green.shade200
                            : Colors.green.shade800);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRed
                              ? (isDark
                                  ? Colors.red.shade400
                                  : Colors.red.shade400)
                              : (isDark
                                  ? Colors.green.shade400
                                  : Colors.green.shade400),
                        ),
                      ),
                      child: Text(
                        '#${h.text}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // 3. Tags
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((tag) {
                    return ActionChip(
                      label: Text(
                        tag.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      onPressed: () => onTagTap(tag),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],

              // 4. Commentary preview
              if (hasCommentary &&
                  commentaryPreview != null &&
                  commentaryPreview!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  commentaryPreview!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
