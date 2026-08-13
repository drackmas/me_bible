import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/verse.dart';

class BibleService {
  // --------------------------------------------------
  // Book lists
  // --------------------------------------------------

  static Future<List<String>> loadKjvBooks() async {
    final String jsonString =
        await rootBundle.loadString('assets/Books.json');
    final List<dynamic> data = json.decode(jsonString);
    return data.map((e) => e.toString()).toList();
  }

  static Future<List<String>> loadApocryphaBooks() async {
    final String jsonString =
        await rootBundle.loadString('assets/Apocrypha.json');
    final List<dynamic> data = json.decode(jsonString);
    return data.map((e) => e.toString()).toList();
  }

  /// Combined list used by Search, Tags, etc.
  static Future<List<String>> loadAllBooks() async {
    final kjv = await loadKjvBooks();
    final apo = await loadApocryphaBooks();
    return [...kjv, ...apo];
  }

  /// Kept for backward compatibility
  static Future<List<String>> loadBookList() => loadAllBooks();

  // --------------------------------------------------
  // Load a single book (main KJV-style)
  // --------------------------------------------------

  static Future<List<Verse>> loadBook(String bookName) async {
    final String jsonString =
        await rootBundle.loadString('assets/$bookName.json');

    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> chapters = data['chapters'] as List<dynamic>;

    final List<Verse> allVerses = [];

    for (final chapterData in chapters) {
      final int chapterNum =
          int.parse(chapterData['chapter'].toString());

      final List<dynamic> verses =
          chapterData['verses'] as List<dynamic>;

      for (final verseData in verses) {
        allVerses.add(
          Verse.fromJson(verseData, chapterNum),
        );
      }
    }

    return allVerses;
  }

  // --------------------------------------------------
  // Chapter helpers
  // --------------------------------------------------

  static Future<List<int>> getChapterNumbers(String bookName) async {
    final String jsonString =
        await rootBundle.loadString('assets/$bookName.json');

    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> chapters = data['chapters'] as List<dynamic>;

    final List<int> chapterNumbers = [];

    for (final chapterData in chapters) {
      final int chapterNum =
          int.parse(chapterData['chapter'].toString());
      chapterNumbers.add(chapterNum);
    }

    chapterNumbers.sort();
    return chapterNumbers.toSet().toList();
  }

  static Future<int> getMaxChapter(String bookName) async {
    final chapterNumbers = await getChapterNumbers(bookName);
    if (chapterNumbers.isEmpty) return 1;
    return chapterNumbers.last;
  }

  // --------------------------------------------------
  // REFERENCE BIBLES (BSB etc.)
  // --------------------------------------------------

  static List<Map<String, dynamic>>? _referenceBibles;

  // versionId → bookName → chapter → verse → text
  static final Map<String, Map<String, Map<int, Map<int, String>>>> _refCache = {};

  static Future<List<Map<String, dynamic>>> loadReferenceBibles() async {
    if (_referenceBibles != null) return _referenceBibles!;
    final raw = await rootBundle.loadString('assets/referencebibles.json');
    _referenceBibles = List<Map<String, dynamic>>.from(json.decode(raw));
    return _referenceBibles!;
  }

  /// Convert your app book names to the names used inside BSB.json
  static String normalizeBookName(String appName) {
    const map = {
      // Samuel
      '1Samuel': 'I Samuel',
      '2Samuel': 'II Samuel',

      // Kings
      '1Kings': 'I Kings',
      '2Kings': 'II Kings',

      // Chronicles
      '1Chronicles': 'I Chronicles',
      '2Chronicles': 'II Chronicles',

      // Song of Solomon
      'SongofSolomon': 'Song of Solomon',

      // Corinthians
      '1Corinthians': 'I Corinthians',
      '2Corinthians': 'II Corinthians',

      // Thessalonians
      '1Thessalonians': 'I Thessalonians',
      '2Thessalonians': 'II Thessalonians',

      // Timothy
      '1Timothy': 'I Timothy',
      '2Timothy': 'II Timothy',

      // Peter
      '1Peter': 'I Peter',
      '2Peter': 'II Peter',

      // John
      '1John': 'I John',
      '2John': 'II John',
      '3John': 'III John',
    };
    return map[appName] ?? appName;
  }

  /// Returns the text of one verse from one reference version
  static Future<String?> getReferenceVerse(
    String versionId,
    String appBookName,
    int chapter,
    int verse,
  ) async {
    final bibles = await loadReferenceBibles();
    final info = bibles.cast<Map<String, dynamic>?>().firstWhere(
          (b) => b?['id'] == versionId,
          orElse: () => null,
        );
    if (info == null) return null;

    // Load & cache the whole translation the first time it is used
    if (!_refCache.containsKey(versionId)) {
      final file = info['file'] as String;
      final raw = await rootBundle.loadString('assets/$file');
      final data = json.decode(raw);
      final books = data['books'] as List;

      final map = <String, Map<int, Map<int, String>>>{};

      for (final book in books) {
        final name = book['name'] as String;
        final chapters = <int, Map<int, String>>{};

        for (final ch in book['chapters']) {
          final chNum = int.parse(ch['chapter'].toString());
          final verses = <int, String>{};

          for (final v in ch['verses']) {
            verses[int.parse(v['verse'].toString())] = v['text'] as String;
          }
          chapters[chNum] = verses;
        }
        map[name] = chapters;
      }
      _refCache[versionId] = map;
    }

    final normalized = normalizeBookName(appBookName);
    return _refCache[versionId]?[normalized]?[chapter]?[verse];
  }

  /// Convenience: get all reference versions for one verse at once
  static Future<List<MapEntry<String, String?>>> getAllReferenceVerses(
    String appBookName,
    int chapter,
    int verse,
  ) async {
    final bibles = await loadReferenceBibles();
    final results = <MapEntry<String, String?>>[];

    for (final b in bibles) {
      final id = b['id'] as String;
      final text = await getReferenceVerse(id, appBookName, chapter, verse);
      results.add(MapEntry(id, text));
    }
    return results;
  }
}
