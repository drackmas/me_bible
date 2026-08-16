import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bible_service.dart';
import '../services/theme_service.dart';
import 'reader_screen.dart';

class SearchResult {
  final String book;
  final int chapter;
  final int verse;
  final String text;

  SearchResult({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  String get reference => '$book $chapter:$verse';
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool caseSensitive = false;
  bool wholeWord = true;

  bool searching = false;
  List<SearchResult> results = [];
  String? error;

  String get versionId =>
      context.read<ThemeService>().defaultBibleVersion;

  Future<void> _performSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        results = [];
        error = 'Please enter a word or phrase';
      });
      return;
    }

    setState(() {
      searching = true;
      error = null;
      results = [];
    });

    try {
      final books = await BibleService.loadAllBooksIncludingApocrypha(versionId);
      final List<SearchResult> found = [];

      final String searchQuery = caseSensitive ? query : query.toLowerCase();

      for (final book in books) {
        final verses = await BibleService.loadBook(versionId, book);

        for (final verse in verses) {
          bool matches = false;

          if (wholeWord) {
            final pattern = RegExp(
              r'\b' + RegExp.escape(searchQuery) + r'\b',
              caseSensitive: caseSensitive,
            );
            matches = pattern.hasMatch(verse.text);
          } else {
            final textToSearch =
                caseSensitive ? verse.text : verse.text.toLowerCase();
            matches = textToSearch.contains(searchQuery);
          }

          if (matches) {
            found.add(SearchResult(
              book: book,
              chapter: verse.chapter,
              verse: verse.verse,
              text: verse.text,
            ));
          }
        }
      }

      setState(() {
        results = found;
        searching = false;
      });
    } catch (e) {
      setState(() {
        searching = false;
        error = 'Search failed: $e';
      });
    }
  }

  void _jumpToVerse(SearchResult r) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          initialBook: r.book,
          initialChapter: r.chapter,
        ),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Bible ($versionId)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Word or phrase',
                    hintText: 'e.g. Lord, son of man, heaven',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: searching ? null : _performSearch,
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Case sensitive'),
                  subtitle: Text(
                    caseSensitive
                        ? '“Lord” and “LORD” are different'
                        : '“Lord” and “LORD” are treated the same',
                  ),
                  value: caseSensitive,
                  onChanged: (v) => setState(() => caseSensitive = v),
                ),
                SwitchListTile(
                  title: const Text('Whole word only'),
                  subtitle: Text(
                    wholeWord
                        ? 'Won’t match inside other words'
                        : 'Will match even as part of another word',
                  ),
                  value: wholeWord,
                  onChanged: (v) => setState(() => wholeWord = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: searching ? null : _performSearch,
                    icon: searching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(searching ? 'Searching...' : 'Search'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
          if (!searching && results.isEmpty && _controller.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No verses found'),
            ),
          if (results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '${results.length} result${results.length == 1 ? '' : 's'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final r = results[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(
                      r.reference,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(r.text),
                    ),
                    onTap: () => _jumpToVerse(r),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
