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
      // No popup on delete by default
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
        title: const Text("Saved Notes"),
        actions: [
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final note = filtered[index];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Text(
                    note.text.length > 40
                        ? "${note.text.substring(0, 40)}..."
                        : note.text,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoteDetailScreen(note: note),
                      ),
                    );
                    await loadNotes();
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteNote(note),
                  ),
                );
              },
            ),
    );
  }
}
