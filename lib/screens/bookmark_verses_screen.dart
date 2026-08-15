import 'package:flutter/material.dart';
import '../models/bookmark.dart';
import '../models/verse.dart';
import '../services/bible_service.dart';
import '../services/bookmark_service.dart';
import 'reader_screen.dart';

class BookmarkVersesScreen extends StatefulWidget {
  final Bookmark bookmark;
  final String versionId;

  const BookmarkVersesScreen({
    super.key,
    required this.bookmark,
    required this.versionId,
  });

  @override
  State<BookmarkVersesScreen> createState() => _BookmarkVersesScreenState();
}

class _BookmarkVersesScreenState extends State<BookmarkVersesScreen> {
  late Bookmark bookmark;
  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    bookmark = widget.bookmark;
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    final all = await BookmarkService.loadAll(widget.versionId);
    bookmark = all.firstWhere(
      (b) => b.id == widget.bookmark.id,
      orElse: () => widget.bookmark,
    );

    final List<Map<String, dynamic>> result = [];

    for (final bv in bookmark.verses) {
      final verses =
          await BibleService.loadBook(widget.versionId, bv.book);
      final verse = verses.firstWhere(
        (v) => v.chapter == bv.chapter && v.verse == bv.verse,
        orElse: () =>
            Verse(chapter: bv.chapter, verse: bv.verse, text: ''),
      );

      result.add({
        'bookmarkVerse': bv,
        'text': verse.text,
      });
    }

    setState(() {
      items = result;
      loading = false;
    });
  }

  Future<void> _removeVerse(BookmarkVerse bv) async {
    await BookmarkService.removeVerse(widget.versionId, bookmark.id, bv);
    await _load();
  }

  void _jumpToVerse(BookmarkVerse bv) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          initialBook: bv.book,
          initialChapter: bv.chapter,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bookmark.name),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('No verses in this bookmark yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final bv = item['bookmarkVerse'] as BookmarkVerse;
                    final text = item['text'] as String;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          bv.reference,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(text),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          tooltip: 'Remove from bookmark',
                          onPressed: () => _removeVerse(bv),
                        ),
                        onTap: () => _jumpToVerse(bv),
                      ),
                    );
                  },
                ),
    );
  }
}
