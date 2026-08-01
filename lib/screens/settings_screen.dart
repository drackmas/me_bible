import 'package:flutter/material.dart';
import '../services/commentary_service.dart';
import 'tag_manager_screen.dart';
import 'search_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // ===== TAGS =====
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Create / Manage Tags'),
            subtitle: const Text('Tag phrases like "son of man" across the whole Bible'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TagManagerScreen()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search Bible'),
            subtitle: const Text('Search for a word or phrase across the whole Bible'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),

          const Divider(),

          // ===== EXPORT =====
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export All Data'),
            subtitle: const Text('Commentaries + Highlights + Tags'),
            onTap: () async {
              try {
                final path = await CommentaryService.exportAll();
                if (path == null) return; // user cancelled

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

          const Divider(),

          // ===== IMPORT =====
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Data'),
            subtitle: const Text('Restore Commentaries + Highlights + Tags'),
            onTap: () async {
              try {
                final result = await CommentaryService.importAll();

                if (context.mounted) {
                  final c = result['commentaries'] ?? 0;
                  final t = result['tags'] ?? 0;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        (c == 0 && t == 0)
                            ? 'Import cancelled or no data found'
                            : 'Imported $c commentaries and $t tags',
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
        ],
      ),
    );
  }
}
