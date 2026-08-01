import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/commentary.dart';
import '../models/tag.dart';
import 'tag_service.dart';

class CommentaryService {
  static Future<String> _getPath(String book) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$book-Commentary.json';
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
  // EXPORT (Commentaries + Highlights + Hashtags + Tags)
  // ============================================================
  static Future<String?> exportAll() async {
    // 1. Collect all commentaries (includes highlights + hashtags)
    final books = await _getAllBooksWithCommentaries();
    final Map<String, dynamic> commentariesMap = {};

    for (final book in books) {
      final commentaries = await load(book);
      if (commentaries.isNotEmpty) {
        commentariesMap[book] = commentaries.map((c) => c.toJson()).toList();
      }
    }

    // 2. Collect tags (only name + phrase, NO occurrences)
    final tags = await TagService.loadAll();

    final Map<String, dynamic> exportData = {
      'commentaries': commentariesMap,
      'tags': tags.map((t) => t.toJson()).toList(), // ← clean version
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 2,
    };

    // Let user choose where to save
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Commentaries + Tags',
      fileName: 'bible_backup.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (outputPath == null) return null; // user cancelled

    if (!outputPath.toLowerCase().endsWith('.json')) {
      outputPath += '.json';
    }

    final file = File(outputPath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(exportData),
    );

    return outputPath;
  }

  // ============================================================
  // IMPORT (Commentaries + Highlights + Hashtags + Tags)
  // ============================================================
  static Future<Map<String, int>> importAll() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Commentaries + Tags',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return {'commentaries': 0, 'tags': 0};
    }

    final path = result.files.single.path;
    if (path == null) return {'commentaries': 0, 'tags': 0};

    final content = await File(path).readAsString();
    final Map<String, dynamic> data = json.decode(content);

    int commentaryCount = 0;
    int tagCount = 0;

    // ----- Import Commentaries (with highlights + hashtags) -----
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

    // ----- Import Tags (without occurrences) -----
    if (data['tags'] != null) {
      final List<dynamic> tagsList = data['tags'] as List<dynamic>;
      final tags = tagsList.map((e) => Tag.fromJson(e)).toList();
      await TagService.saveAll(tags);

      // Rebuild the occurrences by scanning the whole Bible
      await TagService.rebuildAllMissingOccurrences();

      tagCount = tags.length;
    }

    return {
      'commentaries': commentaryCount,
      'tags': tagCount,
    };
  }

  // Helper: find which books already have commentary files
  static Future<List<String>> _getAllBooksWithCommentaries() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync();

    final books = <String>[];
    for (final file in files) {
      if (file is File && file.path.endsWith('-Commentary.json')) {
        final name =
            file.uri.pathSegments.last.replaceAll('-Commentary.json', '');
        books.add(name);
      }
    }
    return books;
  }
}