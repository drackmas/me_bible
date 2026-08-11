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
  // Load a single book
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
}
