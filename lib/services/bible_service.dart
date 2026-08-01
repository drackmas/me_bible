import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/verse.dart';

class BibleService {
  static Future<List<String>> loadBookList() async {
    final String jsonString = await rootBundle.loadString('assets/Books.json');
    final List<dynamic> data = json.decode(jsonString);
    return data.map((e) => e.toString()).toList();
  }

  static Future<List<Verse>> loadBook(String bookName) async {
    final String jsonString =
        await rootBundle.loadString('assets/$bookName.json');

    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> chapters = data['chapters'] as List<dynamic>;

    final List<Verse> allVerses = [];

    for (final chapterData in chapters) {
      final int chapterNum = int.parse(chapterData['chapter'].toString());
      final List<dynamic> verses = chapterData['verses'] as List<dynamic>;

      for (final verseData in verses) {
        allVerses.add(Verse.fromJson(verseData, chapterNum));
      }
    }

    return allVerses;
  }

  static Future<int> getMaxChapter(String bookName) async {
    final verses = await loadBook(bookName);
    if (verses.isEmpty) return 1;
    return verses.map((v) => v.chapter).reduce((a, b) => a > b ? a : b);
  }
}
