import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/note.dart';
import 'note_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];
  List<Note> filtered = [];
  String query = '';
  bool sortDescending = true;
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final result = await StorageService.getNotes();
    if (!mounted) return;
    setState(() {
      notes = result;
      _applyFilters();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      if (!_isSelecting) {
        _selectedIds.clear();
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected?'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} note(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final id in _selectedIds) {
        await StorageService.deleteNote(id);
      }
      _selectedIds.clear();
      _isSelecting = false;
      await loadNotes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected notes deleted'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteAll() async {
    if (notes.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All?'),
        content: Text(
          'Are you sure you want to delete all ${notes.length} note(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final note in notes) {
        await StorageService.deleteNote(note.id);
      }
      await loadNotes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notes deleted'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Note?"),
        content: Text("Are you sure you want to delete \"${note.title}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteNote(note.id);
      await loadNotes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _applyFilters() {
    final list = List<Note>.from(notes);
    list.sort(
      (a, b) => sortDescending
          ? b.timestamp.compareTo(a.timestamp)
          : a.timestamp.compareTo(b.timestamp),
    );

    if (query.isNotEmpty) {
      filtered = list
          .where(
            (n) =>
                n.title.toLowerCase().contains(query.toLowerCase()) ||
                n.text.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } else {
      filtered = list;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelecting ? '${_selectedIds.length} selected' : 'Saved Notes',
        ),
        actions: [
          if (_isSelecting) ...[
            if (_selectedIds.isNotEmpty)
              IconButton(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete),
                tooltip: 'Delete selected',
              ),
            IconButton(
              onPressed: _toggleSelectMode,
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
            ),
          ] else ...[
            if (notes.isNotEmpty)
              IconButton(
                onPressed: _toggleSelectMode,
                icon: const Icon(Icons.checklist),
                tooltip: 'Select items',
              ),
            IconButton(
              icon: Icon(sortDescending ? Icons.sort_by_alpha : Icons.sort),
              onPressed: () {
                setState(() {
                  sortDescending = !sortDescending;
                  _applyFilters();
                });
              },
              tooltip: 'Toggle sort by date',
            ),
            if (notes.isNotEmpty)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete_all') {
                    _deleteAll();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete All'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ],
        bottom: _isSelecting
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search notes',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      setState(() {
                        query = v;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ),
      ),
      body: filtered.isEmpty
          ? const Center(child: Text("No notes saved"))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final note = filtered[index];
                final isSelected = _selectedIds.contains(note.id);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: _isSelecting
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(note.id),
                          )
                        : null,
                    title: Text(note.title),
                    subtitle: Text(
                      note.text.length > 40
                          ? "${note.text.substring(0, 40)}..."
                          : note.text,
                    ),
                    onTap: _isSelecting
                        ? () => _toggleSelection(note.id)
                        : () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NoteDetailScreen(note: note),
                              ),
                            );
                            await loadNotes();
                          },
                    trailing: _isSelecting
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteNote(note),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
