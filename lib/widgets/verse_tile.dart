import 'package:flutter/material.dart';
import '../models/verse.dart';
import '../models/tag.dart';
import '../models/commentary.dart';
import '../models/bookmark.dart';
import '../services/bible_service.dart';
import 'highlighted_text.dart';

class VerseTile extends StatelessWidget {
  final Verse verse;
  final bool hasCommentary;
  final String? commentaryPreview;
  final List<Highlight> commentaryHighlights;
  final List<HashTag> hashtags;
  final List<Tag> tags;
  final List<Bookmark> bookmarks;
  final VoidCallback onTap;
  final Function(Tag tag) onTagTap;
  final Function(Bookmark bookmark) onBookmarkTap;
  final VoidCallback? onLongPress;

  // Reference Bible stuff
  final bool showReferenceButton;
  final bool isExpanded;
  final VoidCallback? onVerseNumberTap;
  final String currentBook;

  const VerseTile({
    super.key,
    required this.verse,
    required this.hasCommentary,
    this.commentaryPreview,
    this.commentaryHighlights = const [],
    this.hashtags = const [],
    required this.tags,
    this.bookmarks = const [],
    required this.onTap,
    required this.onTagTap,
    required this.onBookmarkTap,
    this.onLongPress,
    this.showReferenceButton = false,
    this.isExpanded = false,
    this.onVerseNumberTap,
    required this.currentBook,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasExtra = hasCommentary ||
        tags.isNotEmpty ||
        commentaryHighlights.isNotEmpty ||
        hashtags.isNotEmpty ||
        bookmarks.isNotEmpty;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: hasExtra ? 2 : 0,
      color: hasCommentary
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25)
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verse number + text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onVerseNumberTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: showReferenceButton
                          ? BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      child: Text(
                        '${verse.verse}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
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

              // Expanded reference versions
              if (isExpanded && onVerseNumberTap != null) ...[
                const SizedBox(height: 12),
                FutureBuilder<List<MapEntry<String, String?>>>(
                  future: BibleService.getAllReferenceVerses(
                    currentBook,
                    verse.chapter,
                    verse.verse,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(left: 28),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: snapshot.data!.map((entry) {
                        final versionId = entry.key;
                        final text = entry.value;
                        if (text == null || text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 28, bottom: 8),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$versionId ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  ),
                                ),
                                TextSpan(
                                  text: text,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],

              // Hashtags
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

              // Tags
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((tag) {
                    return ActionChip(
                      label: Text(tag.name, style: const TextStyle(fontSize: 12)),
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      onPressed: () => onTagTap(tag),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],

              // Bookmarks
              if (bookmarks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: bookmarks.map((bm) {
                    return ActionChip(
                      avatar: const Icon(Icons.bookmark, size: 16),
                      label: Text(bm.name, style: const TextStyle(fontSize: 12)),
                      backgroundColor:
                          Theme.of(context).colorScheme.tertiaryContainer,
                      onPressed: () => onBookmarkTap(bm),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],

              // Commentary preview
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
