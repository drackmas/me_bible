import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppStorage {
  static Directory? _dir;

  /// Returns a private folder for the app (not visible in Documents)
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

  static Future<String> pathFor(String filename) async {
    final dir = await dataDir;
    return p.join(dir.path, filename);
  }
}
