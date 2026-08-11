import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/verse.dart';

class BibleService {
  static Future<List<String>> loadBookList() async {
    final String jsonString =
        await rootBundle.loadString('assets/Books.json');

    final List<dynamic> data = json.decode(jsonString);

    return data.map((e) => e.toString()).toList();
  }

  static Future<List<Verse>> loadBook(String bookName) async {
    final String jsonString =
        await rootBundle.loadString('assets/$bookName.json');

    final Map<String, dynamic> data = json.decode(jsonString);

    final List<dynamic> chapters =
        data['chapters'] as List<dynamic>;

    final List<Verse> allVerses = [];

    for (final chapterData in chapters) {
      final int chapterNum =
          int.parse(chapterData['chapter'].toString());

      final List<dynamic> verses =
          chapterData['verses'] as List<dynamic>;

      for (final verseData in verses) {
        allVerses.add(
          Verse.fromJson(
            verseData,
            chapterNum,
          ),
        );
      }
    }

    return allVerses;
  }

  // -------------------------------------------------------------------------
  // Return the ACTUAL chapter numbers contained in a book.
  //
  // This is important for books such as Additions to Esther, whose chapters
  // are numbered 10-16 rather than 1-7.
  // -------------------------------------------------------------------------

  static Future<List<int>> getChapterNumbers(
    String bookName,
  ) async {
    final String jsonString =
        await rootBundle.loadString('assets/$bookName.json');

    final Map<String, dynamic> data =
        json.decode(jsonString);

    final List<dynamic> chapters =
        data['chapters'] as List<dynamic>;

    final List<int> chapterNumbers = [];

    for (final chapterData in chapters) {
      final int chapterNum =
          int.parse(chapterData['chapter'].toString());

      chapterNumbers.add(chapterNum);
    }

    // Keep them numerically ordered and remove duplicates just in case.
    chapterNumbers.sort();

    return chapterNumbers.toSet().toList();
  }

  // -------------------------------------------------------------------------
  // Kept for compatibility with the rest of the app.
  //
  // Returns the highest chapter number.
  // -------------------------------------------------------------------------

  static Future<int> getMaxChapter(
    String bookName,
  ) async {
    final chapterNumbers =
        await getChapterNumbers(bookName);

    if (chapterNumbers.isEmpty) {
      return 1;
    }

    return chapterNumbers.last;
  }
}