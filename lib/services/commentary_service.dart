import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../models/commentary.dart';
import '../models/tag.dart';
import '../models/bookmark.dart';
import 'tag_service.dart';
import 'bookmark_service.dart';
import 'app_storage.dart';

class CommentaryService {
  static Future<String> _getPath(String versionId, String book) async {
    return AppStorage.pathForVersion(versionId, '$book-Commentary.json');
  }

  static Future<List<Commentary>> load(String versionId, String book) async {
    try {
      final path = await _getPath(versionId, book);
      final file = File(path);
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> data = json.decode(content);
      return data.map((e) => Commentary.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> save(
      String versionId, String book, List<Commentary> list) async {
    final path = await _getPath(versionId, book);
    final file = File(path);
    final jsonList = list.map((c) => c.toJson()).toList();
    await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonList));
  }

  static Future<void> upsert(
      String versionId, String book, Commentary commentary) async {
    final list = await load(versionId, book);
    final index = list.indexWhere(
        (c) => c.chapter == commentary.chapter && c.verse == commentary.verse);
    if (index >= 0) {
      list[index] = commentary;
    } else {
      list.add(commentary);
    }
    await save(versionId, book, list);
  }

  static Future<void> delete(
      String versionId, String book, int chapter, int verse) async {
    final list = await load(versionId, book);
    list.removeWhere((c) => c.chapter == chapter && c.verse == verse);
    await save(versionId, book, list);
  }

  // ============================================================
  // EXPORT
  // ============================================================
  static Future<String?> exportAll(String versionId) async {
    final books = await _getAllBooksWithCommentaries(versionId);
    final Map<String, dynamic> commentariesMap = {};

    for (final book in books) {
      final commentaries = await load(versionId, book);
      if (commentaries.isNotEmpty) {
        commentariesMap[book] =
            commentaries.map((c) => c.toJson()).toList();
      }
    }

    final tags = await TagService.loadAll(versionId);
    final bookmarks = await BookmarkService.loadAll(versionId);

    final Map<String, dynamic> exportData = {
      'versionId': versionId,
      'commentaries': commentariesMap,
      'tags': tags.map((t) => t.toJson()).toList(),
      'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'schemaVersion': 4,
    };

    final jsonString =
        const JsonEncoder.withIndent('  ').convert(exportData);
    final bytes = utf8.encode(jsonString);

    final String? result = await FilePicker.saveFile(
      dialogTitle: 'Export Commentaries + Tags + Bookmarks',
      fileName: 'bible_backup_$versionId.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(bytes),
    );

    return result;
  }

  // ============================================================
  // IMPORT
  // ============================================================
  static Future<Map<String, int>> importAll({String? forceVersionId}) async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Import Commentaries + Tags + Bookmarks',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return {'commentaries': 0, 'tags': 0, 'bookmarks': 0};
    }

    final path = result.files.single.path;
    if (path == null) {
      return {'commentaries': 0, 'tags': 0, 'bookmarks': 0};
    }

    final content = await File(path).readAsString();
    final Map<String, dynamic> data = json.decode(content);

    final versionId =
        forceVersionId ?? data['versionId'] as String? ?? 'AKJV';

    int commentaryCount = 0;
    int tagCount = 0;
    int bookmarkCount = 0;

    if (data['commentaries'] != null) {
      final Map<String, dynamic> commentariesMap =
          Map<String, dynamic>.from(data['commentaries']);

      for (final entry in commentariesMap.entries) {
        final book = entry.key;
        final List<dynamic> list = entry.value as List<dynamic>;
        final commentaries =
            list.map((e) => Commentary.fromJson(e)).toList();
        await save(versionId, book, commentaries);
        commentaryCount += commentaries.length;
      }
    }

    if (data['tags'] != null) {
      final List<dynamic> tagsList = data['tags'] as List<dynamic>;
      final tags = tagsList.map((e) => Tag.fromJson(e)).toList();
      await TagService.saveAll(versionId, tags);
      await TagService.rebuildAllMissingOccurrences(versionId);
      tagCount = tags.length;
    }

    if (data['bookmarks'] != null) {
      final List<dynamic> bmList = data['bookmarks'] as List<dynamic>;
      final bookmarks = bmList
          .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
          .toList();
      await BookmarkService.saveAll(versionId, bookmarks);
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
  static Future<void> eraseAllCommentaries(String versionId) async {
    final books = await _getAllBooksWithCommentaries(versionId);
    for (final book in books) {
      final path = await _getPath(versionId, book);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  static Future<List<String>> _getAllBooksWithCommentaries(
      String versionId) async {
    final dir = await AppStorage.dataDir;
    final versionDir = Directory(p.join(dir.path, versionId));
    if (!await versionDir.exists()) return [];

    final files = versionDir.listSync();
    final books = <String>[];
    for (final file in files) {
      if (file is File && file.path.endsWith('-Commentary.json')) {
        final name =
            p.basename(file.path).replaceAll('-Commentary.json', '');
        books.add(name);
      }
    }
    return books;
  }
}
