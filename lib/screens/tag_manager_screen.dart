import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import 'tag_verses_screen.dart';

class TagManagerScreen extends StatefulWidget {
  const TagManagerScreen({super.key});

  @override
  State<TagManagerScreen> createState() => _TagManagerScreenState();
}

class _TagManagerScreenState extends State<TagManagerScreen> {
  List<Tag> tags = [];
  bool loading = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phraseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => loading = true);
    tags = await TagService.loadAll();
    // Sort alphabetically
    tags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() => loading = false);
  }

  Future<void> _createTag() async {
    final name = nameController.text.trim();
    final phrase = phraseController.text.trim().isEmpty
        ? name
        : phraseController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a tag name')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Scanning the whole Bible...\nThis may take a few seconds.')),
          ],
        ),
      ),
    );

    try {
      final newTag = await TagService.createTag(name, phrase);

      if (mounted) {
        Navigator.pop(context); // close loading dialog
        nameController.clear();
        phraseController.clear();
        await _loadTags();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tag "$name" created with ${newTag.occurrences.length} verses',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create tag: $e')),
        );
      }
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag?'),
        content: Text('Delete the tag "${tag.name}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TagService.deleteTag(tag.name);
      await _loadTags();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tag "${tag.name}" deleted')),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tags'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ===== CREATE NEW TAG =====
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tag name',
                          hintText: 'e.g. Son of Man',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phraseController,
                        decoration: const InputDecoration(
                          labelText: 'Search phrase (optional)',
                          hintText: 'Leave empty to use the tag name',
                          border: OutlineInputBorder(),
                          helperText: 'The exact words to search for in every verse',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _createTag,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Tag & Scan Bible'),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // ===== EXISTING TAGS =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Your Tags (${tags.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: tags.isEmpty
                      ? const Center(
                          child: Text(
                            'No tags yet.\nCreate one above!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: tags.length,
                          itemBuilder: (context, index) {
                            final tag = tags[index];
                            return ListTile(
                              title: Text(tag.name),
                              subtitle: Text(
                                '${tag.occurrences.length} verses • phrase: "${tag.phrase}"',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteTag(tag),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TagVersesScreen(tag: tag),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
