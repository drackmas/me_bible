import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/commentary_service.dart';
import '../services/tag_service.dart';
import '../services/bookmark_service.dart';
import '../services/theme_service.dart';
import 'tag_manager_screen.dart';
import 'bookmark_manager_screen.dart';
import 'search_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _eraseAllData(BuildContext context) async {
    // First confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase All Data?'),
        content: const Text(
          'This will permanently delete:\n\n'
          '• All commentaries\n'
          '• All highlights\n'
          '• All hashtags\n'
          '• All tags\n'
          '• All bookmarks\n\n'
          'This cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Erase Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Second (stronger) confirmation
    final reallySure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'This is your last chance.\n\n'
          'All your notes, highlights, hashtags, tags and bookmarks will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Delete Everything'),
          ),
        ],
      ),
    );

    if (reallySure != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Erasing data...'),
          ],
        ),
      ),
    );

    try {
      await CommentaryService.eraseAllCommentaries();
      await TagService.eraseAllTags();
      await BookmarkService.eraseAll();

      if (context.mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been erased'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to erase data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // ===== NAVIGATION / TOOLS =====
          const _SectionHeader(title: 'Tools & Navigation'),

          // ===== SEARCH =====
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search Bible'),
            subtitle: const Text('Search for a word or phrase across the whole Bible'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),

          // ===== TAGS =====
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Create / Manage Tags'),
            subtitle: const Text('Tag phrases like "son of man" across the whole Bible'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TagManagerScreen()),
              );
            },
          ),

          // ===== BOOKMARKS =====
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('Manage Bookmarks'),
            subtitle: const Text('Create, rename or delete bookmark collections'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookmarkManagerScreen()),
              );
            },
          ),

          const Divider(),

          // ===== APPEARANCE & READING =====
          const _SectionHeader(title: 'Appearance & Reading'),

          // ===== THEME =====
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: Text(
              switch (themeService.mode) {
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
                ThemeMode.system => 'System',
              },
            ),
            trailing: DropdownButton<ThemeMode>(
              value: themeService.mode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  context.read<ThemeService>().setMode(mode);
                }
              },
            ),
          ),

          // ===== FONT FAMILY =====
          ListTile(
            leading: const Icon(Icons.font_download_outlined),
            title: const Text('Font Family'),
            subtitle: Text(themeService.fontFamily),
            trailing: DropdownButton<String>(
              value: themeService.fontFamily,
              underline: const SizedBox(),
              items: ThemeService.fontFamilies
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (family) {
                if (family != null) {
                  context.read<ThemeService>().setFontFamily(family);
                }
              },
            ),
          ),

          // ===== FONT SIZE =====
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('Font Size'),
            subtitle: Text('${themeService.fontSize.toInt()}'),
            trailing: DropdownButton<double>(
              value: themeService.fontSize,
              underline: const SizedBox(),
              items: ThemeService.fontSizes
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.toInt().toString()),
                      ))
                  .toList(),
              onChanged: (size) {
                if (size != null) {
                  context.read<ThemeService>().setFontSize(size);
                }
              },
            ),
          ),

          // ===== KEEP SCREEN ON =====
          SwitchListTile(
            secondary: const Icon(Icons.screen_lock_portrait_outlined),
            title: const Text('Keep screen on'),
            subtitle: const Text('Prevent the screen from turning off while reading'),
            value: themeService.keepScreenOn,
            onChanged: (value) {
              context.read<ThemeService>().setKeepScreenOn(value);
            },
          ),

          const Divider(),

          // ===== DATA & BACKUP =====
          const _SectionHeader(title: 'Data & Backup'),

          // ===== EXPORT =====
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export All Data'),
            subtitle: const Text('Commentaries + Highlights + Tags + Bookmarks'),
            onTap: () async {
              try {
                final path = await CommentaryService.exportAll();
                if (path == null) return;

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Exported successfully!\n$path'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              }
            },
          ),

          // ===== IMPORT =====
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Data'),
            subtitle: const Text('Restore Commentaries + Highlights + Tags + Bookmarks'),
            onTap: () async {
              try {
                final result = await CommentaryService.importAll();

                if (context.mounted) {
                  final c = result['commentaries'] ?? 0;
                  final t = result['tags'] ?? 0;
                  final b = result['bookmarks'] ?? 0;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        (c == 0 && t == 0 && b == 0)
                            ? 'Import cancelled or no data found'
                            : 'Imported $c commentaries, $t tags and $b bookmarks',
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              }
            },
          ),

          // ===== ERASE DATA =====
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Erase All Data',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text(
              'Permanently delete all commentaries, tags, highlights, hashtags & bookmarks',
            ),
            onTap: () => _eraseAllData(context),
          ),

          const Divider(),

          // ===== EXIT APP =====
          ListTile(
            leading: const Icon(Icons.power_settings_new),
            title: const Text('Exit App'),
            subtitle: const Text('Close and exit the application'),
            onTap: () {
              SystemNavigator.pop();
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
