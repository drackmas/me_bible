import 'dart:convert';
import 'dart:io';
import 'app_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/tag.dart';
import 'bible_service.dart';

class TagService {
  static Future<String> _getPath() async {
    return AppStorage.pathFor('bible_tags.json');
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
    final jsonList = tags.map((t) => t.toJsonFull()).toList();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonList));
  }

  /// Creates a new tag
  static Future<Tag> createTag(
    String name,
    String phrase, {
    List<String> variants = const [],
  }) async {
    final tag = Tag(name: name, phrase: phrase, variants: variants);
    await _rebuildOccurrences(tag);

    final allTags = await loadAll();
    allTags.removeWhere((t) => t.name.toLowerCase() == name.toLowerCase());
    allTags.add(tag);
    await saveAll(allTags);

    return tag;
  }

  /// Updates an existing tag
  static Future<void> updateTag(Tag updatedTag) async {
    await _rebuildOccurrences(updatedTag);

    final allTags = await loadAll();
    final index = allTags.indexWhere(
        (t) => t.name.toLowerCase() == updatedTag.name.toLowerCase());

    if (index >= 0) {
      allTags[index] = updatedTag;
    } else {
      allTags.add(updatedTag);
    }

    await saveAll(allTags);
  }

  static Future<void> deleteTag(String name) async {
    final allTags = await loadAll();
    allTags.removeWhere((t) => t.name.toLowerCase() == name.toLowerCase());
    await saveAll(allTags);
  }

  /// Scans the whole Bible using main phrase + all variants
  static Future<void> _rebuildOccurrences(Tag tag) async {
    final books = await BibleService.loadBookList();
    final List<TagOccurrence> occurrences = [];

    // All phrases we should match (main + variants)
    final allPhrases = [tag.phrase, ...tag.variants]
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();

    final patterns = allPhrases.map((p) {
      final escaped = RegExp.escape(p);
      return RegExp(r'\b' + escaped + r'\b', caseSensitive: true);
    }).toList();

    for (final book in books) {
      final verses = await BibleService.loadBook(book);
      for (final verse in verses) {
        final matches = patterns.any((pattern) => pattern.hasMatch(verse.text));
        if (matches) {
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

  /// Used after importing tags that have no occurrences
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

  /// Force rebuild every tag (useful after fixing matching logic)
  static Future<void> rebuildAllTags() async {
    final tags = await loadAll();
    for (final tag in tags) {
      await _rebuildOccurrences(tag);
    }
    await saveAll(tags);
  }
}
