import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  TextEditingController? _titleController;
  TextEditingController? _textController;
  bool _isEditing = false;
  bool _showImage = false;
  ui.Image? _loadedImage;

  @override
  void initState() {
    super.initState();
    note = widget.note;
    _titleController = TextEditingController(text: note.title);
    _textController = TextEditingController(text: note.text);
    if (note.imagePath != null) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _titleController?.dispose();
    _textController?.dispose();
    _loadedImage?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    if (note.imagePath == null) return;
    try {
      final file = File(note.imagePath!);
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _loadedImage = frame.image;
        });
      }
    } catch (e) {
      // Image loading failed, continue without image
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveNote() async {
    final newTitle = _titleController?.text.trim() ?? '';
    final newText = _textController?.text.trim() ?? '';

    if (newTitle.isNotEmpty && newText.isNotEmpty) {
      await StorageService.updateNote(note.id, title: newTitle, text: newText);
      setState(() {
        note.title = newTitle;
        note.text = newText;
        _isEditing = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: note.text));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.black, fontSize: 18),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Title',
                ),
              )
            : Text(note.title),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _saveNote,
              icon: const Icon(Icons.check),
              tooltip: 'Save',
            )
          else
            IconButton(
              onPressed: _toggleEdit,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          if (_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _titleController?.text = note.title;
                  _textController?.text = note.text;
                  _isEditing = false;
                });
              },
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
            ),
          if (!_isEditing && note.imagePath != null && _loadedImage != null)
            IconButton(
              onPressed: () {
                setState(() {
                  _showImage = !_showImage;
                });
              },
              icon: Icon(_showImage ? Icons.image : Icons.image_outlined),
              tooltip: _showImage ? 'Hide image' : 'Show image',
            ),
          if (!_isEditing)
            IconButton(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy),
              tooltip: 'Copy to clipboard',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _showImage && note.imagePath != null && _loadedImage != null
            ? Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(note.imagePath!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 1,
                    child: _isEditing
                        ? TextField(
                            controller: _textController,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Note content',
                            ),
                          )
                        : SingleChildScrollView(child: Text(note.text)),
                  ),
                ],
              )
            : (_isEditing
                  ? TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Note content',
                      ),
                    )
                  : SingleChildScrollView(child: Text(note.text))),
      ),
    );
  }
}
