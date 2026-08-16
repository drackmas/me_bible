import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/verse.dart';
import '../models/commentary.dart';
import '../models/tag.dart';
import '../models/bookmark.dart';
import '../services/bible_service.dart';
import '../services/commentary_service.dart';
import '../services/tag_service.dart';
import '../services/bookmark_service.dart';
import '../services/theme_service.dart';
import '../widgets/verse_tile.dart';
import '../widgets/commentary_sheet.dart';
import '../widgets/book_chapter_chooser.dart';
import 'settings_screen.dart';
import 'tag_verses_screen.dart';
import 'bookmark_verses_screen.dart';

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
  List<Bookmark> allBookmarks = [];
  bool loading = true;
  bool isApocrypha = false;

  Set<int> expandedVerses = {};

  String get versionId =>
      context.read<ThemeService>().defaultBibleVersion;

  @override
  void initState() {
    super.initState();
    currentBook = widget.initialBook;
    currentChapter = widget.initialChapter;
    _init();
  }

  Future<void> _init() async {
    allBooks = await BibleService.loadBooks(versionId);
    await _loadBook();
  }

  Future<void> _loadBook() async {
    setState(() => loading = true);

    final vid = versionId;

    verses = await BibleService.loadBook(vid, currentBook);
    maxChapter = await BibleService.getMaxChapter(vid, currentBook);
    commentaries = await CommentaryService.load(vid, currentBook);
    allTags = await TagService.loadAll(vid);
    allBookmarks = await BookmarkService.loadAll(vid);
    isApocrypha = await BibleService.isApocryphaBook(currentBook);

    if (currentChapter > maxChapter) {
      currentChapter = 1;
    }

    expandedVerses.clear();

    setState(() => loading = false);
  }

  List<Bookmark> getBookmarksForVerse(int verseNumber) {
    final target = BookmarkVerse(
      book: currentBook,
      chapter: currentChapter,
      verse: verseNumber,
    );
    return allBookmarks.where((b) => b.verses.contains(target)).toList();
  }

  Future<void> _showBookmarkSheet(Verse verse) async {
    final current = BookmarkVerse(
      book: currentBook,
      chapter: currentChapter,
      verse: verse.verse,
    );
    final vid = versionId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      title: Text(
                        'Add to Bookmark',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (allBookmarks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No bookmarks yet. Create one below.'),
                      ),
                    ...allBookmarks.map((bm) {
                      final already = bm.verses.contains(current);
                      return CheckboxListTile(
                        title: Text(bm.name),
                        subtitle: Text('${bm.verses.length} verse(s)'),
                        value: already,
                        onChanged: (checked) async {
                          if (checked == true) {
                            await BookmarkService.addVerse(vid, bm.id, current);
                          } else {
                            await BookmarkService.removeVerse(
                                vid, bm.id, current);
                          }
                          allBookmarks = await BookmarkService.loadAll(vid);
                          setModalState(() {});
                          setState(() {});
                        },
                      );
                    }),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Create new bookmark…'),
                      onTap: () async {
                        final name = await _askBookmarkName();
                        if (name != null && name.isNotEmpty) {
                          final newBm =
                              await BookmarkService.create(vid, name);
                          await BookmarkService.addVerse(
                              vid, newBm.id, current);
                          allBookmarks = await BookmarkService.loadAll(vid);
                          if (context.mounted) Navigator.pop(context);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _askBookmarkName() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Bookmark'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name (e.g. Love)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
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
    final vid = versionId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CommentarySheet(
        versionId: vid,
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
                versionId: versionId,
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
    // Rebuild when default Bible changes
    final themeService = context.watch<ThemeService>();
    final currentVersion = themeService.defaultBibleVersion;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _openAndBibleStyleChooser,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('$currentBook $currentChapter'),
              Text(
                currentVersion,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
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
              // Reload everything in case the default Bible (or data) changed
              allBooks = await BibleService.loadBooks(versionId);
              await _loadBook();
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
                  bookmarks: getBookmarksForVerse(verse.verse),
                  onTap: () => _openCommentary(verse),
                  onTagTap: (tag) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TagVersesScreen(
                          tag: tag,
                          versionId: versionId,
                        ),
                      ),
                    );
                  },
                  onBookmarkTap: (bm) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookmarkVersesScreen(
                          bookmark: bm,
                          versionId: versionId,
                        ),
                      ),
                    );
                  },
                  onLongPress: () => _showBookmarkSheet(verse),
                  showReferenceButton: !isApocrypha,
                  isExpanded: expandedVerses.contains(verse.verse),
                  currentBook: currentBook,
                  primaryVersionId: versionId,
                  onVerseNumberTap: isApocrypha
                      ? null
                      : () {
                          setState(() {
                            if (expandedVerses.contains(verse.verse)) {
                              expandedVerses.remove(verse.verse);
                            } else {
                              expandedVerses.add(verse.verse);
                            }
                          });
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
                    ? () {
                        setState(() => currentChapter--);
                      }
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
                    ? () {
                        setState(() => currentChapter++);
                      }
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
