import 'dart:convert';
import 'dart:io';
import '../models/bookmark.dart';
import 'app_storage.dart';

class BookmarkService {
  static Future<String> _getPath() async {
    return AppStorage.pathFor('bible_bookmarks.json');
  }

  static Future<List<Bookmark>> loadAll() async {
    try {
      final path = await _getPath();
      final file = File(path);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> data = json.decode(content);
      return data.map((e) => Bookmark.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveAll(List<Bookmark> bookmarks) async {
    final path = await _getPath();
    final file = File(path);
    final jsonList = bookmarks.map((b) => b.toJson()).toList();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonList),
    );
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static Future<Bookmark> create(String name) async {
    final trimmed = name.trim();
    final bookmark = Bookmark(
      id: _generateId(),
      name: trimmed,
    );

    final all = await loadAll();
    // Optional: prevent exact duplicate names (case-insensitive)
    all.removeWhere((b) => b.name.toLowerCase() == trimmed.toLowerCase());
    all.add(bookmark);
    await saveAll(all);
    return bookmark;
  }

  static Future<void> rename(String id, String newName) async {
    final all = await loadAll();
    final index = all.indexWhere((b) => b.id == id);
    if (index >= 0) {
      all[index].name = newName.trim();
      await saveAll(all);
    }
  }

  static Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((b) => b.id == id);
    await saveAll(all);
  }

  static Future<void> addVerse(String bookmarkId, BookmarkVerse verse) async {
    final all = await loadAll();
    final index = all.indexWhere((b) => b.id == bookmarkId);
    if (index < 0) return;

    if (!all[index].verses.contains(verse)) {
      all[index].verses.add(verse);
      await saveAll(all);
    }
  }

  static Future<void> removeVerse(String bookmarkId, BookmarkVerse verse) async {
    final all = await loadAll();
    final index = all.indexWhere((b) => b.id == bookmarkId);
    if (index < 0) return;

    all[index].verses.remove(verse);
    await saveAll(all);
  }

  /// Returns every bookmark that contains the given verse
  static Future<List<Bookmark>> getBookmarksForVerse(
    String book,
    int chapter,
    int verse,
  ) async {
    final all = await loadAll();
    final target = BookmarkVerse(book: book, chapter: chapter, verse: verse);
    return all.where((b) => b.verses.contains(target)).toList();
  }

  static Future<void> eraseAll() async {
    final path = await _getPath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
