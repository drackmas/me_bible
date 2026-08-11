import 'package:flutter/material.dart';
import '../services/bible_service.dart';

class BookChapterChooser extends StatefulWidget {
  final String currentBook;
  final int currentChapter;
  final ScrollController scrollController;
  final Function(String book, int chapter) onChapterSelected;

  const BookChapterChooser({
    super.key,
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
  List<String> currentBooks = [];
  int maxChapter = 1;
  bool loading = false;
  bool showingBooks = false; // false = showing chapters of current book

  // Short abbreviations
  static const Map<String, String> abbreviations = {
    'Genesis': 'Gen',
    'Exodus': 'Exod',
    'Leviticus': 'Lev',
    'Numbers': 'Num',
    'Deuteronomy': 'Deut',
    'Joshua': 'Josh',
    'Judges': 'Judg',
    'Ruth': 'Ruth',
    '1Samuel': '1Sam',
    '2Samuel': '2Sam',
    '1Kings': '1Kgs',
    '2Kings': '2Kgs',
    '1Chronicles': '1Chr',
    '2Chronicles': '2Chr',
    'Ezra': 'Ezra',
    'Nehemiah': 'Neh',
    'Esther': 'Esth',
    'Job': 'Job',
    'Psalms': 'Ps',
    'Proverbs': 'Prov',
    'Ecclesiastes': 'Eccl',
    'SongofSolomon': 'Song',
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
    '1Corinthians': '1Cor',
    '2Corinthians': '2Cor',
    'Galatians': 'Gal',
    'Ephesians': 'Eph',
    'Philippians': 'Phil',
    'Colossians': 'Col',
    '1Thessalonians': '1Thess',
    '2Thessalonians': '2Thess',
    '1Timothy': '1Tim',
    '2Timothy': '2Tim',
    'Titus': 'Titus',
    'Philemon': 'Phlm',
    'Hebrews': 'Heb',
    'James': 'Jas',
    '1Peter': '1Pet',
    '2Peter': '2Pet',
    '1John': '1John',
    '2John': '2John',
    '3John': '3John',
    'Jude': 'Jude',
    'Revelation': 'Rev',
    // Apocrypha
    '1Esdras': '1Esd',
    '2Esdras': '2Esd',
    'Tobit': 'Tob',
    'Judith': 'Jdt',
    'AdditionsToEsther': 'AddEsth',
    'WisdomOfSolomon': 'Wis',
    'Sirach': 'Sir',
    '1Baruch': '1Bar',
    '2Baruch': '2Bar',
    'PrayerofAzariah': 'PrAzar',
    'Susanna': 'Sus',
    'BelAndTheDragon': 'Bel',
    'PrayerofManasseh': 'PrMan',
    '1Maccabees': '1Macc',
    '2Maccabees': '2Macc',
    'EpistleofJeremiah': 'EpJer',
    '1Enoch': '1En',
    '2Enoch': '2En',
  };

  @override
  void initState() {
    super.initState();
    selectedBook = widget.currentBook;
    _loadMaxChapter(widget.currentBook);
  }

  Future<void> _loadMaxChapter(String book) async {
    setState(() => loading = true);
    maxChapter = await BibleService.getMaxChapter(book);
    if (mounted) setState(() => loading = false);
  }

  Future<void> _showKjvBooks() async {
    setState(() => loading = true);
    final books = await BibleService.loadKjvBooks();
    setState(() {
      currentBooks = books;
      showingBooks = true;
      selectedBook = null;
      loading = false;
    });
  }

  Future<void> _showApocryphaBooks() async {
    setState(() => loading = true);
    final books = await BibleService.loadApocryphaBooks();
    setState(() {
      currentBooks = books;
      showingBooks = true;
      selectedBook = null;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Drag handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 8),

        // Title + KJV / Apocrypha buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedBook ?? (showingBooks ? 'Select Book' : widget.currentBook),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // KJV button
              TextButton(
                onPressed: _showKjvBooks,
                style: TextButton.styleFrom(
                  foregroundColor: showingBooks && currentBooks.isNotEmpty && 
                      currentBooks.first == 'Genesis'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                child: const Text('KJV'),
              ),
              // Apocrypha button
              TextButton(
                onPressed: _showApocryphaBooks,
                style: TextButton.styleFrom(
                  foregroundColor: showingBooks && currentBooks.isNotEmpty && 
                      currentBooks.first != 'Genesis'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                child: const Text('Apocrypha'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Content
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : showingBooks
                  ? _buildBookGrid()
                  : _buildChapterGrid(),
        ),
      ],
    );
  }

  // Book grid (same style as before)
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
      itemCount: currentBooks.length,
      itemBuilder: (context, index) {
        final book = currentBooks[index];
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
              setState(() {
                selectedBook = book;
                showingBooks = false;
              });
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

  // Chapter grid (same style as before)
  Widget _buildChapterGrid() {
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
