import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/verse.dart';

class BibleService {
  // --------------------------------------------------
  // Available translations (single-file JSON)
  // --------------------------------------------------

  static List<Map<String, dynamic>>? _allBibles;

  static Future<List<Map<String, dynamic>>> loadAllBibles() async {
    if (_allBibles != null) return _allBibles!;
    final raw = await rootBundle.loadString('assets/referencebibles.json');
    _allBibles = List<Map<String, dynamic>>.from(json.decode(raw));
    return _allBibles!;
  }

  static Future<List<Map<String, dynamic>>> loadPrimaryCapableBibles() async {
    final all = await loadAllBibles();
    return all.where((b) => b['canBePrimary'] == true).toList();
  }

  // versionId → bookName → chapter → verse → text
  static final Map<String, Map<String, Map<int, Map<int, String>>>> _cache = {};

  // Apocrypha (legacy per-book files)
  static final Map<String, Map<int, Map<int, String>>> _apocryphaCache = {};
  static List<String>? _apocryphaBookList;

  static Future<void> _ensureLoaded(String versionId) async {
    if (_cache.containsKey(versionId)) return;

    final bibles = await loadAllBibles();
    final info = bibles.cast<Map<String, dynamic>?>().firstWhere(
          (b) => b?['id'] == versionId,
          orElse: () => null,
        );
    if (info == null) {
      throw Exception('Unknown Bible version: $versionId');
    }

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

    _cache[versionId] = map;
  }

  // --------------------------------------------------
  // Apocrypha
  // --------------------------------------------------

  static Future<List<String>> loadApocryphaBooks() async {
    if (_apocryphaBookList != null) return _apocryphaBookList!;
    final raw = await rootBundle.loadString('assets/Apocrypha.json');
    final List<dynamic> data = json.decode(raw);
    _apocryphaBookList = data.map((e) => e.toString()).toList();
    return _apocryphaBookList!;
  }

  static Future<bool> isApocryphaBook(String bookName) async {
    final list = await loadApocryphaBooks();
    return list.contains(bookName);
  }

  static Future<void> _ensureApocryphaBookLoaded(String bookName) async {
    if (_apocryphaCache.containsKey(bookName)) return;

    final raw = await rootBundle.loadString('assets/$bookName.json');
    final data = json.decode(raw);
    final List chaptersRaw = data['chapters'] as List;

    final chapters = <int, Map<int, String>>{};
    for (final ch in chaptersRaw) {
      final chNum = int.parse(ch['chapter'].toString());
      final verses = <int, String>{};
      for (final v in ch['verses'] as List) {
        verses[int.parse(v['verse'].toString())] = v['text'] as String;
      }
      chapters[chNum] = verses;
    }
    _apocryphaCache[bookName] = chapters;
  }

  // --------------------------------------------------
  // Book lists
  // --------------------------------------------------

  /// Canonical books from the selected single-file version.
  static Future<List<String>> loadBooks(String versionId) async {
    await _ensureLoaded(versionId);
    final books = _cache[versionId]!.keys.toList();
    books.sort(_canonicalBookOrder);
    return books;
  }

  /// Canonical + Apocrypha (search / tag rebuild).
  static Future<List<String>> loadAllBooksIncludingApocrypha(
      String versionId) async {
    final canonical = await loadBooks(versionId);
    final apo = await loadApocryphaBooks();
    return [...canonical, ...apo];
  }

  static int _canonicalBookOrder(String a, String b) {
    const order = [
      'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
      'Joshua', 'Judges', 'Ruth',
      'I Samuel', 'II Samuel', '1 Samuel', '2 Samuel',
      'I Kings', 'II Kings', '1 Kings', '2 Kings',
      'I Chronicles', 'II Chronicles', '1 Chronicles', '2 Chronicles',
      'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
      'Ecclesiastes', 'Song of Solomon', 'Isaiah', 'Jeremiah', 'Lamentations',
      'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah',
      'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
      'Matthew', 'Mark', 'Luke', 'John', 'Acts',
      'Romans', 'I Corinthians', 'II Corinthians', '1 Corinthians', '2 Corinthians',
      'Galatians', 'Ephesians', 'Philippians', 'Colossians',
      'I Thessalonians', 'II Thessalonians', '1 Thessalonians', '2 Thessalonians',
      'I Timothy', 'II Timothy', '1 Timothy', '2 Timothy',
      'Titus', 'Philemon', 'Hebrews', 'James',
      'I Peter', 'II Peter', '1 Peter', '2 Peter',
      'I John', 'II John', 'III John', '1 John', '2 John', '3 John',
      'Jude', 'Revelation', 'Revelation of John',
    ];
    final ia = order.indexOf(a);
    final ib = order.indexOf(b);
    if (ia == -1 && ib == -1) return a.compareTo(b);
    if (ia == -1) return 1;
    if (ib == -1) return -1;
    return ia.compareTo(ib);
  }

  // --------------------------------------------------
  // Load book (version or apocrypha)
  // --------------------------------------------------

  static Future<List<Verse>> loadBook(String versionId, String bookName) async {
    if (await isApocryphaBook(bookName)) {
      return _loadApocryphaBook(bookName);
    }

    await _ensureLoaded(versionId);
    final normalized = normalizeBookName(bookName);
    final chapters = _cache[versionId]?[normalized] ??
        _cache[versionId]?[bookName];

    if (chapters == null) return [];
    return _chaptersToVerses(chapters);
  }

  static Future<List<Verse>> _loadApocryphaBook(String bookName) async {
    await _ensureApocryphaBookLoaded(bookName);
    final chapters = _apocryphaCache[bookName];
    if (chapters == null) return [];
    return _chaptersToVerses(chapters);
  }

  static List<Verse> _chaptersToVerses(Map<int, Map<int, String>> chapters) {
    final allVerses = <Verse>[];
    final sortedChapters = chapters.keys.toList()..sort();

    for (final ch in sortedChapters) {
      final verses = chapters[ch]!;
      final sortedVerses = verses.keys.toList()..sort();
      for (final v in sortedVerses) {
        allVerses.add(Verse(
          chapter: ch,
          verse: v,
          text: verses[v]!,
        ));
      }
    }
    return allVerses;
  }

  static Future<int> getMaxChapter(String versionId, String bookName) async {
    if (await isApocryphaBook(bookName)) {
      await _ensureApocryphaBookLoaded(bookName);
      final chapters = _apocryphaCache[bookName];
      if (chapters == null || chapters.isEmpty) return 1;
      return chapters.keys.reduce((a, b) => a > b ? a : b);
    }

    await _ensureLoaded(versionId);
    final normalized = normalizeBookName(bookName);
    final chapters = _cache[versionId]?[normalized] ??
        _cache[versionId]?[bookName];
    if (chapters == null || chapters.isEmpty) return 1;
    return chapters.keys.reduce((a, b) => a > b ? a : b);
  }

  static Future<List<int>> getChapterNumbers(
      String versionId, String bookName) async {
    if (await isApocryphaBook(bookName)) {
      await _ensureApocryphaBookLoaded(bookName);
      final chapters = _apocryphaCache[bookName];
      if (chapters == null) return [1];
      final list = chapters.keys.toList()..sort();
      return list;
    }

    await _ensureLoaded(versionId);
    final normalized = normalizeBookName(bookName);
    final chapters = _cache[versionId]?[normalized] ??
        _cache[versionId]?[bookName];
    if (chapters == null) return [1];
    final list = chapters.keys.toList()..sort();
    return list;
  }

  // --------------------------------------------------
  // Reference verses (other single-file versions only)
  // --------------------------------------------------

  static Future<String?> getReferenceVerse(
    String versionId,
    String appBookName,
    int chapter,
    int verse,
  ) async {
    if (await isApocryphaBook(appBookName)) return null;

    await _ensureLoaded(versionId);
    final normalized = normalizeBookName(appBookName);
    return _cache[versionId]?[normalized]?[chapter]?[verse] ??
        _cache[versionId]?[appBookName]?[chapter]?[verse];
  }

  static Future<List<MapEntry<String, String?>>> getAllReferenceVerses(
    String primaryVersionId,
    String appBookName,
    int chapter,
    int verse,
  ) async {
    if (await isApocryphaBook(appBookName)) return [];

    final bibles = await loadAllBibles();
    final results = <MapEntry<String, String?>>[];

    for (final b in bibles) {
      final id = b['id'] as String;
      if (id == primaryVersionId) continue;
      final text =
          await getReferenceVerse(id, appBookName, chapter, verse);
      results.add(MapEntry(id, text));
    }
    return results;
  }

  static String normalizeBookName(String appName) {
    const map = {
      '1Samuel': 'I Samuel',
      '2Samuel': 'II Samuel',
      '1Kings': 'I Kings',
      '2Kings': 'II Kings',
      '1Chronicles': 'I Chronicles',
      '2Chronicles': 'II Chronicles',
      'SongofSolomon': 'Song of Solomon',
      '1Corinthians': 'I Corinthians',
      '2Corinthians': 'II Corinthians',
      '1Thessalonians': 'I Thessalonians',
      '2Thessalonians': 'II Thessalonians',
      '1Timothy': 'I Timothy',
      '2Timothy': 'II Timothy',
      '1Peter': 'I Peter',
      '2Peter': 'II Peter',
      '1John': 'I John',
      '2John': 'II John',
      '3John': 'III John',
      'Revelation': 'Revelation of John',
    };
    return map[appName] ?? appName;
  }

  static Future<String> getVersionDisplayName(String versionId) async {
    final bibles = await loadAllBibles();
    final info = bibles.cast<Map<String, dynamic>?>().firstWhere(
          (b) => b?['id'] == versionId,
          orElse: () => null,
        );
    return info?['name'] as String? ?? versionId;
  }
}
