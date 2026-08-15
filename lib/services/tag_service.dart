import 'dart:convert';
import 'dart:io';
import '../models/tag.dart';
import 'app_storage.dart';
import 'bible_service.dart';

class TagService {
  static Future<String> _getPath(String versionId) async {
    return AppStorage.pathForVersion(versionId, 'bible_tags.json');
  }

  static Future<List<Tag>> loadAll(String versionId) async {
    try {
      final path = await _getPath(versionId);
      final file = File(path);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> data = json.decode(content);
      return data.map((e) => Tag.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveAll(String versionId, List<Tag> tags) async {
    final path = await _getPath(versionId);
    final file = File(path);
    final jsonList = tags.map((t) => t.toJsonFull()).toList();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonList));
  }

  static Future<Tag> createTag(
    String versionId,
    String name,
    String phrase, {
    List<String> variants = const [],
  }) async {
    final tag = Tag(name: name, phrase: phrase, variants: variants);
    await _rebuildOccurrences(versionId, tag);

    final allTags = await loadAll(versionId);
    allTags.removeWhere((t) => t.name.toLowerCase() == name.toLowerCase());
    allTags.add(tag);
    await saveAll(versionId, allTags);

    return tag;
  }

  static Future<void> updateTag(String versionId, Tag updatedTag) async {
    await _rebuildOccurrences(versionId, updatedTag);

    final allTags = await loadAll(versionId);
    final index = allTags.indexWhere(
        (t) => t.name.toLowerCase() == updatedTag.name.toLowerCase());

    if (index >= 0) {
      allTags[index] = updatedTag;
    } else {
      allTags.add(updatedTag);
    }

    await saveAll(versionId, allTags);
  }

  static Future<void> deleteTag(String versionId, String name) async {
    final allTags = await loadAll(versionId);
    allTags.removeWhere((t) => t.name.toLowerCase() == name.toLowerCase());
    await saveAll(versionId, allTags);
  }

  static Future<void> _rebuildOccurrences(String versionId, Tag tag) async {
    final books = await BibleService.loadBooks(versionId);
    final List<TagOccurrence> occurrences = [];

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
      final verses = await BibleService.loadBook(versionId, book);
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

  static Future<void> rebuildAllMissingOccurrences(String versionId) async {
    final tags = await loadAll(versionId);
    bool changed = false;

    for (final tag in tags) {
      if (tag.occurrences.isEmpty) {
        await _rebuildOccurrences(versionId, tag);
        changed = true;
      }
    }

    if (changed) {
      await saveAll(versionId, tags);
    }
  }

  static Future<void> rebuildAllTags(String versionId) async {
    final tags = await loadAll(versionId);
    for (final tag in tags) {
      await _rebuildOccurrences(versionId, tag);
    }
    await saveAll(versionId, tags);
  }

  static Future<void> eraseAllTags(String versionId) async {
    final path = await _getPath(versionId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
