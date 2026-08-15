import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import '../services/theme_service.dart';
import 'tag_verses_screen.dart';

class TagManagerScreen extends StatefulWidget {
  const TagManagerScreen({super.key});

  @override
  State<TagManagerScreen> createState() => _TagManagerScreenState();
}

class _TagManagerScreenState extends State<TagManagerScreen> {
  List<Tag> tags = [];
  bool loading = true;

  String get versionId =>
      context.read<ThemeService>().defaultBibleVersion;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => loading = true);
    tags = await TagService.loadAll(versionId);
    tags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() => loading = false);
  }

  Future<void> _showTagEditor({Tag? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phraseController =
        TextEditingController(text: existing?.phrase ?? '');
    final variantController = TextEditingController();
    List<String> variants = List.from(existing?.variants ?? []);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(existing == null ? 'Create Tag' : 'Edit Tag'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tag name (what you see)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phraseController,
                      decoration: const InputDecoration(
                        labelText: 'Main search phrase',
                        border: OutlineInputBorder(),
                        helperText: 'Exact phrase to search for',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Extra matching phrases (variants)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: variantController,
                            decoration: const InputDecoration(
                              hintText: 'Add another phrase...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: () {
                            final text = variantController.text.trim();
                            if (text.isNotEmpty && !variants.contains(text)) {
                              setStateDialog(() {
                                variants.add(text);
                                variantController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (variants.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: variants.map((v) {
                          return Chip(
                            label: Text(v),
                            onDeleted: () {
                              setStateDialog(() => variants.remove(v));
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
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
      },
    );

    if (result == true) {
      final name = nameController.text.trim();
      final phrase = phraseController.text.trim();

      if (name.isEmpty || phrase.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and main phrase are required')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Scanning Bible...'),
            ],
          ),
        ),
      );

      try {
        if (existing == null) {
          await TagService.createTag(versionId, name, phrase,
              variants: variants);
        } else {
          final updated = Tag(
            name: name,
            phrase: phrase,
            variants: variants,
          );
          await TagService.updateTag(versionId, updated);
        }

        if (mounted) {
          Navigator.pop(context);
          await _loadTags();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    existing == null ? 'Tag created' : 'Tag updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag?'),
        content: Text('Delete "${tag.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await TagService.deleteTag(versionId, tag.name);
      await _loadTags();
    }
  }

  Future<void> _rebuildAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rebuild All Tags?'),
        content: Text(
            'This will re-scan the entire $versionId Bible for every tag. It may take a while.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Rebuild')),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Rebuilding all tags...'),
            ],
          ),
        ),
      );

      await TagService.rebuildAllTags(versionId);

      if (mounted) {
        Navigator.pop(context);
        await _loadTags();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All tags rebuilt')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Tags ($versionId)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rebuild all tags',
            onPressed: _rebuildAll,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTagEditor(),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tags.isEmpty
              ? const Center(child: Text('No tags yet.\nTap + to create one.'))
              : ListView.builder(
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    return ListTile(
                      title: Text(tag.name),
                      subtitle: Text(
                        '${tag.occurrences.length} verses'
                        '${tag.variants.isNotEmpty ? ' • +${tag.variants.length} variants' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showTagEditor(existing: tag),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _deleteTag(tag),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TagVersesScreen(
                              tag: tag,
                              versionId: versionId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
