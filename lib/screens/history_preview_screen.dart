import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_history_item.dart';
import '../services/storage_service.dart';
import 'ocr_screen.dart';

class HistoryPreviewScreen extends StatelessWidget {
  final ScanHistoryItem item;
  const HistoryPreviewScreen({super.key, required this.item});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan?'),
        content: const Text('Are you sure you want to delete this scan?'),
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
      await StorageService.deleteHistoryItem(item.id);
      if (context.mounted) {
        Navigator.pop(context, true); // indicate deleted
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Preview')),
      body: Column(
        children: [
          Expanded(child: Center(child: Image.file(File(item.imagePath)))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (item.extractedText.isNotEmpty) ...[
                  Text(
                    'Existing extracted text:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: SingleChildScrollView(
                      child: Text(item.extractedText),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OcrScreen(imagePath: item.imagePath),
                      ),
                    );
                  },
                  icon: const Icon(Icons.text_fields),
                  label: const Text('Extract Text'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Delete Scan',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
