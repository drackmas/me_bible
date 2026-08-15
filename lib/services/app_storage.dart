import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppStorage {
  static Directory? _dir;

  static Future<Directory> get dataDir async {
    if (_dir != null) return _dir!;

    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'me_bible_data'));

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _dir = dir;
    return dir;
  }

  /// Version-scoped path: me_bible_data/AKJV/filename
  static Future<String> pathForVersion(String versionId, String filename) async {
    final dir = await dataDir;
    final versionDir = Directory(p.join(dir.path, versionId));
    if (!await versionDir.exists()) {
      await versionDir.create(recursive: true);
    }
    return p.join(versionDir.path, filename);
  }

  /// Legacy path (for migration only)
  static Future<String> pathFor(String filename) async {
    final dir = await dataDir;
    return p.join(dir.path, filename);
  }
}
