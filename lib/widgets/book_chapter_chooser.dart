import 'package:flutter/material.dart';
import '../services/bible_service.dart';

class BookChapterChooser extends StatefulWidget {
  final List<String> allBooks;
  final String currentBook;
  final int currentChapter;
  final ScrollController scrollController;
  final Function(String book, int chapter) onChapterSelected;

  const BookChapterChooser({
    super.key,
    required this.allBooks,
    required this.currentBook,
    required this.currentChapter,
    required this.scrollController,
    required this.onChapterSelected,
  });

  @override
  State<BookChapterChooser> createState() => _BookChapterChooserState();
}

class _BookChapterChooserState extends State<BookChapterChooser> {
  String? selectedBook;
  int maxChapter = 1;
  bool loadingChapters = false;

  // AndBible-style short abbreviations
  static const Map<String, String> abbreviations = {
    'Genesis': 'Gen',
    'Exodus': 'Exod',
    'Leviticus': 'Lev',
    'Numbers': 'Num',
    'Deuteronomy': 'Deut',
    'Joshua': 'Josh',
    'Judges': 'Judg',
    'Ruth': 'Ruth',
    '1 Samuel': '1Sam',
    '2 Samuel': '2Sam',
    '1 Kings': '1Kgs',
    '2 Kings': '2Kgs',
    '1 Chronicles': '1Chr',
    '2 Chronicles': '2Chr',
    'Ezra': 'Ezra',
    'Nehemiah': 'Neh',
    'Esther': 'Esth',
    'Job': 'Job',
    'Psalms': 'Ps',
    'Proverbs': 'Prov',
    'Ecclesiastes': 'Eccl',
    'Song of Solomon': 'Song',
    'Isaiah': 'Isa',
    'Jeremiah': 'Jer',
    'Lamentations': 'Lam',
    'Ezekiel': 'Ezek',
    'Daniel': 'Dan',
    'Hosea': 'Hos',
    'Joel': 'Joel',
    'Amos': 'Amos',
    'Obadiah': 'Obad',
    'Jonah': 'Jonah',
    'Micah': 'Mic',
    'Nahum': 'Nah',
    'Habakkuk': 'Hab',
    'Zephaniah': 'Zeph',
    'Haggai': 'Hag',
    'Zechariah': 'Zech',
    'Malachi': 'Mal',
    'Matthew': 'Matt',
    'Mark': 'Mark',
    'Luke': 'Luke',
    'John': 'John',
    'Acts': 'Acts',
    'Romans': 'Rom',
    '1 Corinthians': '1Cor',
    '2 Corinthians': '2Cor',
    'Galatians': 'Gal',
    'Ephesians': 'Eph',
    'Philippians': 'Phil',
    'Colossians': 'Col',
    '1 Thessalonians': '1Thess',
    '2 Thessalonians': '2Thess',
    '1 Timothy': '1Tim',
    '2 Timothy': '2Tim',
    'Titus': 'Titus',
    'Philemon': 'Phlm',
    'Hebrews': 'Heb',
    'James': 'Jas',
    '1 Peter': '1Pet',
    '2 Peter': '2Pet',
    '1 John': '1John',
    '2 John': '2John',
    '3 John': '3John',
    'Jude': 'Jude',
    'Revelation': 'Rev',
  };

  @override
  void initState() {
    super.initState();
    selectedBook = widget.currentBook;
    _loadMaxChapter(widget.currentBook);
  }

  Future<void> _loadMaxChapter(String book) async {
    setState(() => loadingChapters = true);
    maxChapter = await BibleService.getMaxChapter(book);
    setState(() => loadingChapters = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                selectedBook == null ? 'Select Book' : selectedBook!,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (selectedBook != null)
                TextButton(
                  onPressed: () => setState(() => selectedBook = null),
                  child: const Text('All Books'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: selectedBook == null ? _buildBookGrid() : _buildChapterGrid(),
        ),
      ],
    );
  }

  Widget _buildBookGrid() {
    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.55,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.allBooks.length,
      itemBuilder: (context, index) {
        final book = widget.allBooks[index];
        final isSelected = book == widget.currentBook;
        final abbrev = abbreviations[book] ?? book;

        return Material(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() => selectedBook = book);
              _loadMaxChapter(book);
            },
            child: Center(
              child: Text(
                abbrev,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapterGrid() {
    if (loadingChapters) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.15,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: maxChapter,
      itemBuilder: (context, index) {
        final chapter = index + 1;
        final isSelected = selectedBook == widget.currentBook &&
            chapter == widget.currentChapter;

        return Material(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              widget.onChapterSelected(selectedBook!, chapter);
            },
            child: Center(
              child: Text(
                '$chapter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
