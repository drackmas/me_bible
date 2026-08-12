import 'package:flutter/material.dart';
import '../models/bookmark.dart';
import '../services/bookmark_service.dart';
import 'bookmark_verses_screen.dart';

class BookmarkManagerScreen extends StatefulWidget {
  const BookmarkManagerScreen({super.key});

  @override
  State<BookmarkManagerScreen> createState() => _BookmarkManagerScreenState();
}

class _BookmarkManagerScreenState extends State<BookmarkManagerScreen> {
  List<Bookmark> bookmarks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    bookmarks = await BookmarkService.loadAll();
    bookmarks.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    setState(() => loading = false);
  }

  Future<void> _showEditor({Bookmark? existing}) async {
    final controller = TextEditingController(text: existing?.name ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Create Bookmark' : 'Rename Bookmark'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name (e.g. Love, Prophecy)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final name = controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    if (existing == null) {
      await BookmarkService.create(name);
    } else {
      await BookmarkService.rename(existing.id, name);
    }

    await _load();
  }

  Future<void> _delete(Bookmark bm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark?'),
        content: Text(
          'Delete "${bm.name}"?\n\n'
          'This will also remove all ${bm.verses.length} verse(s) inside it.\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BookmarkService.delete(bm.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookmarks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create bookmark',
            onPressed: () => _showEditor(),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : bookmarks.isEmpty
              ? const Center(
                  child: Text(
                    'No bookmarks yet.\nTap + to create one.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bm = bookmarks[index];
                    return ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text(bm.name),
                      subtitle: Text('${bm.verses.length} verse(s)'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditor(existing: bm),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _delete(bm),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookmarkVersesScreen(bookmark: bm),
                          ),
                        ).then((_) => _load()); // refresh count when coming back
                      },
                    );
                  },
                ),
    );
  }
}
