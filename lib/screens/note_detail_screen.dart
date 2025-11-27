import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import '../services/storage_service.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late Note note;

  @override
  void initState() {
    super.initState();
    note = widget.note;
  }

  Future<void> _renameNote() async {
    final controller = TextEditingController(text: note.title);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newTitle = controller.text.trim();
      if (newTitle.isNotEmpty) {
        await StorageService.updateNote(note.id, title: newTitle);
        setState(() => note.title = newTitle);
      }
    }
  }

  Future<void> _exportToFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final safeTitle = note.title.replaceAll(RegExp(r"[^A-Za-z0-9_\- ]"), '_');
    final file = File(
      '${dir.path}/$safeTitle-${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await file.writeAsString(note.text);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exported'),
        content: Text('Saved to: ${file.path}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareNote() async {
    // ignore: deprecated_member_use
    await Share.share(note.text, subject: note.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
        actions: [
          IconButton(
            onPressed: _renameNote,
            icon: const Icon(Icons.edit),
            tooltip: 'Rename',
          ),
          IconButton(
            onPressed: _exportToFile,
            icon: const Icon(Icons.download),
            tooltip: 'Export to file',
          ),
          IconButton(
            onPressed: _shareNote,
            icon: const Icon(Icons.share),
            tooltip: 'Share',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(child: Text(note.text)),
      ),
    );
  }
}
