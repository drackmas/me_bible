import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/commentary.dart';
import '../models/tag.dart';
import 'tag_service.dart';
import 'app_storage.dart';
import 'package:path/path.dart' as p;   // only needed in commentary_service
import '../models/bookmark.dart';
import 'bookmark_service.dart';

class CommentaryService {
  static Future<String> _getPath(String book) async {
    return AppStorage.pathFor('$book-Commentary.json');
  }
  static Future<List<Commentary>> load(String book) async {
    try {
      final path = await _getPath(book);
      final file = File(path);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> data = json.decode(content);
      return data.map((e) => Commentary.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> save(String book, List<Commentary> list) async {
    final path = await _getPath(book);
    final file = File(path);
    final jsonList = list.map((c) => c.toJson()).toList();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonList));
  }

  static Future<void> upsert(String book, Commentary commentary) async {
    final list = await load(book);
    final index = list.indexWhere(
        (c) => c.chapter == commentary.chapter && c.verse == commentary.verse);
    if (index >= 0) {
      list[index] = commentary;
    } else {
      list.add(commentary);
    }
    await save(book, list);
  }

  static Future<void> delete(String book, int chapter, int verse) async {
    final list = await load(book);
    list.removeWhere((c) => c.chapter == chapter && c.verse == verse);
    await save(book, list);
  }

  // ============================================================
  // EXPORT
  // ============================================================
  static Future<String?> exportAll() async {
    final books = await _getAllBooksWithCommentaries();
    final Map<String, dynamic> commentariesMap = {};

    for (final book in books) {
      final commentaries = await load(book);
      if (commentaries.isNotEmpty) {
        commentariesMap[book] =
            commentaries.map((c) => c.toJson()).toList();
      }
    }

    final tags = await TagService.loadAll();
    final bookmarks = await BookmarkService.loadAll();

    final Map<String, dynamic> exportData = {
      'commentaries': commentariesMap,
      'tags': tags.map((t) => t.toJson()).toList(),
      'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 3,
    };

    final jsonString =
        const JsonEncoder.withIndent('  ').convert(exportData);
    final bytes = utf8.encode(jsonString);

    final String? result = await FilePicker.saveFile(
      dialogTitle: 'Export Commentaries + Tags + Bookmarks',
      fileName: 'bible_backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(bytes),
    );

    if (result == null) return null;

    return result;
  }

  // ============================================================
  // IMPORT
  // ============================================================
  static Future<Map<String, int>> importAll() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Import Commentaries + Tags + Bookmarks',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return {'commentaries': 0, 'tags': 0, 'bookmarks': 0};
    }

    final path = result.files.single.path;
    if (path == null) return {'commentaries': 0, 'tags': 0, 'bookmarks': 0};

    final content = await File(path).readAsString();
    final Map<String, dynamic> data = json.decode(content);

    int commentaryCount = 0;
    int tagCount = 0;
    int bookmarkCount = 0;

    if (data['commentaries'] != null) {
      final Map<String, dynamic> commentariesMap =
          Map<String, dynamic>.from(data['commentaries']);

      for (final entry in commentariesMap.entries) {
        final book = entry.key;
        final List<dynamic> list = entry.value as List<dynamic>;
        final commentaries = list.map((e) => Commentary.fromJson(e)).toList();
        await save(book, commentaries);
        commentaryCount += commentaries.length;
      }
    }

    if (data['tags'] != null) {
      final List<dynamic> tagsList = data['tags'] as List<dynamic>;
      final tags = tagsList.map((e) => Tag.fromJson(e)).toList();
      await TagService.saveAll(tags);
      await TagService.rebuildAllMissingOccurrences();
      tagCount = tags.length;
    }

    if (data['bookmarks'] != null) {
      final List<dynamic> bmList = data['bookmarks'] as List<dynamic>;
      final bookmarks = bmList
          .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
          .toList();
      await BookmarkService.saveAll(bookmarks);
      bookmarkCount = bookmarks.length;
    }

    return {
      'commentaries': commentaryCount,
      'tags': tagCount,
      'bookmarks': bookmarkCount,
    };
  }
  
  // ============================================================
  // ERASE
  // ============================================================
  static Future<void> eraseAllCommentaries() async {
    final books = await _getAllBooksWithCommentaries();
    for (final book in books) {
      final path = await _getPath(book);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  static Future<List<String>> _getAllBooksWithCommentaries() async {
    final dir = await AppStorage.dataDir;
    final files = dir.listSync();

    final books = <String>[];
    for (final file in files) {
      if (file is File && file.path.endsWith('-Commentary.json')) {
        final name = p.basename(file.path).replaceAll('-Commentary.json', '');
        books.add(name);
      }
    }
    return books;
  }
}
