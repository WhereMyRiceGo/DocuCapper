import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../models/scan_history_item.dart';

class StorageService {
  static const notesKey = "docucapper_notes_list";
  static const historyKey = "docucapper_history_list";

  static final uuid = Uuid();

  // ---------------- NOTES ----------------

  static Future<List<Note>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(notesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Note.fromJson(e)).toList();
  }

  static Future<void> saveNote(String text, {String? imagePath}) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getNotes();

    final now = DateTime.now();
    final title =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final newNote = Note(
      id: uuid.v4(),
      title: title,
      text: text,
      timestamp: now.toString(),
      imagePath: imagePath,
    );

    notes.add(newNote);

    await prefs.setString(
      notesKey,
      jsonEncode(notes.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> deleteNote(String noteId) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getNotes();

    notes.removeWhere((note) => note.id == noteId);

    await prefs.setString(
      notesKey,
      jsonEncode(notes.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> updateNote(
    String noteId, {
    String? title,
    String? text,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getNotes();

    final idx = notes.indexWhere((n) => n.id == noteId);
    if (idx < 0) return;

    final existing = notes[idx];
    if (title != null) existing.title = title;
    if (text != null) existing.text = text;
    existing.timestamp = DateTime.now().toString();

    await prefs.setString(
      notesKey,
      jsonEncode(notes.map((e) => e.toJson()).toList()),
    );
  }

  // ---------------- HISTORY ----------------

  static Future<List<ScanHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(historyKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => ScanHistoryItem.fromJson(e)).toList();
  }

  static Future<void> addToHistory(
    String imagePath,
    String extractedText,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    // Avoid adding empty OCR results
    if (extractedText.trim().isEmpty) return;

    // Check for an existing entry with the same imagePath
    final existingIndex = history.indexWhere((h) => h.imagePath == imagePath);

    if (existingIndex >= 0) {
      // Update existing entry's extracted text and timestamp instead of duplicating
      history[existingIndex].extractedText = extractedText;
      history[existingIndex].timestamp = DateTime.now().toString();
    } else {
      final newItem = ScanHistoryItem(
        id: uuid.v4(),
        imagePath: imagePath,
        extractedText: extractedText,
        timestamp: DateTime.now().toString(),
      );

      history.add(newItem);
    }

    await prefs.setString(
      historyKey,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> deleteHistoryItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    history.removeWhere((item) => item.id == id);

    await prefs.setString(
      historyKey,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }
}
