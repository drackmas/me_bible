import 'package:flutter/material.dart';
import '../models/verse.dart';
import '../models/commentary.dart';
import '../models/tag.dart';
import '../services/bible_service.dart';
import '../services/commentary_service.dart';
import '../services/tag_service.dart';
import '../widgets/verse_tile.dart';
import '../widgets/commentary_sheet.dart';
import '../widgets/book_chapter_chooser.dart';
import 'settings_screen.dart';
import 'tag_verses_screen.dart';

class ReaderScreen extends StatefulWidget {
  final String initialBook;
  final int initialChapter;

  const ReaderScreen({
    super.key,
    this.initialBook = 'Genesis',
    this.initialChapter = 1,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  List<String> allBooks = [];
  String currentBook = 'Genesis';
  int currentChapter = 1;
  int maxChapter = 1;

  List<Verse> verses = [];
  List<Commentary> commentaries = [];
  List<Tag> allTags = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    currentBook = widget.initialBook;
    currentChapter = widget.initialChapter;
    _init();
  }

  Future<void> _init() async {
    allBooks = await BibleService.loadBookList();
    await _loadBook();
  }

  Future<void> _loadBook() async {
    setState(() => loading = true);

    verses = await BibleService.loadBook(currentBook);
    maxChapter = await BibleService.getMaxChapter(currentBook);
    commentaries = await CommentaryService.load(currentBook);
    allTags = await TagService.loadAll();

    // Keep the requested chapter if it is valid
    if (currentChapter > maxChapter) {
      currentChapter = 1;
    }

    setState(() => loading = false);
  }

  List<Verse> get chapterVerses =>
      verses.where((v) => v.chapter == currentChapter).toList();

  Commentary? getCommentary(int verse) {
    try {
      return commentaries.firstWhere(
          (c) => c.chapter == currentChapter && c.verse == verse);
    } catch (_) {
      return null;
    }
  }

  List<Tag> getTagsForVerse(int verseNumber) {
    return allTags.where((tag) {
      return tag.occurrences.any((o) =>
          o.book == currentBook &&
          o.chapter == currentChapter &&
          o.verse == verseNumber);
    }).toList();
  }

  void _openCommentary(Verse verse) {
    final existing = getCommentary(verse.verse);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CommentarySheet(
        book: currentBook,
        chapter: currentChapter,
        verse: verse.verse,
        initialText: existing?.text ?? '',
        initialHighlights: existing?.highlights ?? [],
        initialHashtags: existing?.hashtags ?? [],
        verseText: verse.text,
        onSaved: () => _loadBook(),
      ),
    );
  }

  void _openAndBibleStyleChooser() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: BookChapterChooser(
                allBooks: allBooks,
                currentBook: currentBook,
                currentChapter: currentChapter,
                scrollController: scrollController,
                onChapterSelected: (book, chapter) {
                  Navigator.pop(context);
                  setState(() {
                    currentBook = book;
                    currentChapter = chapter;
                  });
                  _loadBook();
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _openAndBibleStyleChooser,
          child: Text('$currentBook $currentChapter'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              // Reload in case tags or commentaries changed
              _loadBook();
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: chapterVerses.length,
              itemBuilder: (context, index) {
                final verse = chapterVerses[index];
                final commentary = getCommentary(verse.verse);
                final verseTags = getTagsForVerse(verse.verse);

                return VerseTile(
                  verse: verse,
                  hasCommentary: commentary != null,
                  commentaryPreview: commentary?.text,
                  commentaryHighlights: commentary?.highlights ?? [],
                  hashtags: commentary?.hashtags ?? [],
                  tags: verseTags,
                  onTap: () => _openCommentary(verse),
                  onTagTap: (tag) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TagVersesScreen(tag: tag),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _openAndBibleStyleChooser,
                  child: Text(
                    currentBook,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentChapter > 1
                    ? () => setState(() => currentChapter--)
                    : null,
              ),
              GestureDetector(
                onTap: _openAndBibleStyleChooser,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$currentChapter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentChapter < maxChapter
                    ? () => setState(() => currentChapter++)
                    : null,
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}