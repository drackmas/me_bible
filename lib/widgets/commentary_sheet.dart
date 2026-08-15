import 'package:flutter/material.dart';
import '../models/commentary.dart';
import '../services/commentary_service.dart';
import 'highlighted_text.dart';

class CommentarySheet extends StatefulWidget {
  final String versionId;
  final String book;
  final int chapter;
  final int verse;
  final String initialText;
  final List<Highlight> initialHighlights;
  final List<HashTag> initialHashtags;
  final String verseText;
  final VoidCallback onSaved;

  const CommentarySheet({
    super.key,
    required this.versionId,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.initialText,
    this.initialHighlights = const [],
    this.initialHashtags = const [],
    required this.verseText,
    required this.onSaved,
  });

  @override
  State<CommentarySheet> createState() => _CommentarySheetState();
}

class _CommentarySheetState extends State<CommentarySheet> {
  late TextEditingController controller;
  late List<Highlight> highlights;
  late List<HashTag> hashtags;

  final TextEditingController highlightController = TextEditingController();
  final TextEditingController hashtagController = TextEditingController();

  String selectedHighlightColor = 'yellow';
  String selectedHashtagColor = 'green';

  final highlightColors = [
    'yellow',
    'green',
    'blue',
    'pink',
    'orange',
    'purple'
  ];

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
    highlights = List.from(widget.initialHighlights);
    hashtags = List.from(widget.initialHashtags);
  }

  @override
  void dispose() {
    controller.dispose();
    highlightController.dispose();
    hashtagController.dispose();
    super.dispose();
  }

  void _addHighlight() {
    final phrase = highlightController.text.trim();
    if (phrase.isEmpty) return;

    if (highlights.any((h) => h.text.toLowerCase() == phrase.toLowerCase())) {
      return;
    }

    setState(() {
      highlights.add(Highlight(text: phrase, color: selectedHighlightColor));
      highlightController.clear();
    });
  }

  void _addHashtag() {
    String text = hashtagController.text.trim();
    if (text.isEmpty) return;

    if (text.startsWith('#')) {
      text = text.substring(1);
    }

    if (text.isEmpty) return;

    if (hashtags.any((h) => h.text.toLowerCase() == text.toLowerCase())) {
      return;
    }

    setState(() {
      hashtags.add(HashTag(text: text, color: selectedHashtagColor));
      hashtagController.clear();
    });
  }

  Future<void> _save() async {
    final text = controller.text.trim();

    if (text.isEmpty && highlights.isEmpty && hashtags.isEmpty) {
      await CommentaryService.delete(
        widget.versionId,
        widget.book,
        widget.chapter,
        widget.verse,
      );
    } else {
      await CommentaryService.upsert(
        widget.versionId,
        widget.book,
        Commentary(
          chapter: widget.chapter,
          verse: widget.verse,
          text: text,
          highlights: highlights,
          hashtags: hashtags,
        ),
      );
    }

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  Color _chipColor(String name, {required bool isDark}) {
    switch (name) {
      case 'green':
        return isDark ? Colors.green.shade700 : Colors.green.shade200;
      case 'blue':
        return isDark ? Colors.blue.shade700 : Colors.blue.shade200;
      case 'pink':
        return isDark ? Colors.pink.shade700 : Colors.pink.shade200;
      case 'orange':
        return isDark ? Colors.orange.shade700 : Colors.orange.shade200;
      case 'purple':
        return isDark ? Colors.purple.shade700 : Colors.purple.shade200;
      default:
        return isDark ? Colors.yellow.shade800 : Colors.yellow.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.book} ${widget.chapter}:${widget.verse}  (${widget.versionId})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: HighlightedText(
                text: widget.verseText,
                highlights: highlights,
              ),
            ),

            const SizedBox(height: 20),

            const Text('Hashtags',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: hashtagController,
                    decoration: const InputDecoration(
                      labelText: 'Add hashtag',
                      hintText: 'e.g. heaven',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '#',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'green', label: Text('Green')),
                    ButtonSegment(value: 'red', label: Text('Red')),
                  ],
                  selected: {selectedHashtagColor},
                  onSelectionChanged: (set) {
                    setState(() => selectedHashtagColor = set.first);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addHashtag,
                ),
              ],
            ),
            if (hashtags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: hashtags.map((h) {
                  final isRed = h.color == 'red';
                  final bg = isRed
                      ? (isDark
                          ? Colors.red.shade900.withOpacity(0.45)
                          : Colors.red.shade100)
                      : (isDark
                          ? Colors.green.shade900.withOpacity(0.45)
                          : Colors.green.shade100);

                  return Chip(
                    label: Text('#${h.text}'),
                    backgroundColor: bg,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => hashtags.remove(h));
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            const Text('Highlights',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: highlightController,
                    decoration: const InputDecoration(
                      labelText: 'Phrase to highlight',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedHighlightColor,
                  items: highlightColors
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => selectedHighlightColor = v);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addHighlight,
                ),
              ],
            ),
            if (highlights.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: highlights.map((h) {
                  return Chip(
                    label: Text(h.text),
                    backgroundColor: _chipColor(h.color, isDark: isDark),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => highlights.remove(h));
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            const Text('Commentary',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Write your commentary / notes here...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                if (widget.initialText.isNotEmpty ||
                    widget.initialHighlights.isNotEmpty ||
                    widget.initialHashtags.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await CommentaryService.delete(
                        widget.versionId,
                        widget.book,
                        widget.chapter,
                        widget.verse,
                      );
                      widget.onSaved();
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
