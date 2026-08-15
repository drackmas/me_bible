import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../models/verse.dart';
import '../services/bible_service.dart';
import 'reader_screen.dart';

class TagVersesScreen extends StatefulWidget {
  final Tag tag;
  final String versionId;

  const TagVersesScreen({
    super.key,
    required this.tag,
    required this.versionId,
  });

  @override
  State<TagVersesScreen> createState() => _TagVersesScreenState();
}

class _TagVersesScreenState extends State<TagVersesScreen> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Map<String, dynamic>> result = [];

    for (final occ in widget.tag.occurrences) {
      final verses =
          await BibleService.loadBook(widget.versionId, occ.book);
      final verse = verses.firstWhere(
        (v) => v.chapter == occ.chapter && v.verse == occ.verse,
        orElse: () =>
            Verse(chapter: occ.chapter, verse: occ.verse, text: ''),
      );

      result.add({
        'occurrence': occ,
        'text': verse.text,
      });
    }

    setState(() {
      items = result;
      loading = false;
    });
  }

  void _jumpToVerse(TagOccurrence occ) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          initialBook: occ.book,
          initialChapter: occ.chapter,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tag: ${widget.tag.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final occ = item['occurrence'] as TagOccurrence;
                final text = item['text'] as String;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      occ.reference,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(text),
                    ),
                    onTap: () => _jumpToVerse(occ),
                  ),
                );
              },
            ),
    );
  }
}
