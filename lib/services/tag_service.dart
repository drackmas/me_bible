import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/tag.dart';
import 'bible_service.dart';

class TagService {
  static Future<String> _getPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/bible_tags.json';
  }

  static Future<List<Tag>> loadAll() async {
    try {
      final path = await _getPath();
      final file = File(path);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> data = json.decode(content);
      return data.map((e) => Tag.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveAll(List<Tag> tags) async {
    final path = await _getPath();
    final file = File(path);

    // Save the full version (with occurrences) to local storage
    final jsonList = tags.map((t) => t.toJsonFull()).toList();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonList));
  }

  /// Creates a new tag and scans the entire Bible
  static Future<Tag> createTag(String name, String phrase) async {
    final tag = Tag(name: name, phrase: phrase);
    await _rebuildOccurrences(tag);

    final allTags = await loadAll();
    allTags.removeWhere((t) => t.name.toLowerCase() == name.toLowerCase());
    allTags.add(tag);
    await saveAll(allTags);

    return tag;
  }

  static Future<void> deleteTag(String name) async {
    final allTags = await loadAll();
    allTags.removeWhere((t) => t.name.toLowerCase() == name.toLowerCase());
    await saveAll(allTags);
  }

  /// Scans the whole Bible and fills the occurrences list
  static Future<void> _rebuildOccurrences(Tag tag) async {
    final books = await BibleService.loadBookList();
    final List<TagOccurrence> occurrences = [];
    final lowerPhrase = tag.phrase.toLowerCase();

    for (final book in books) {
      final verses = await BibleService.loadBook(book);
      for (final verse in verses) {
        if (verse.text.toLowerCase().contains(lowerPhrase)) {
          occurrences.add(TagOccurrence(
            book: book,
            chapter: verse.chapter,
            verse: verse.verse,
          ));
        }
      }
    }

    tag.occurrences = occurrences;
  }

  /// Call this after importing tags (they come without occurrences)
  static Future<void> rebuildAllMissingOccurrences() async {
    final tags = await loadAll();
    bool changed = false;

    for (final tag in tags) {
      if (tag.occurrences.isEmpty) {
        await _rebuildOccurrences(tag);
        changed = true;
      }
    }

    if (changed) {
      await saveAll(tags);
    }
  }

  /// Helper used by the reader
  static Future<List<Tag>> getTagsForVerse(
      String book, int chapter, int verse) async {
    final allTags = await loadAll();
    return allTags.where((tag) {
      return tag.occurrences.any((o) =>
          o.book == book && o.chapter == chapter && o.verse == verse);
    }).toList();
  }
}