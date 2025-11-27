import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_history_item.dart';
import '../services/storage_service.dart';
import 'history_preview_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanHistoryItem> items = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final result = await StorageService.getHistory();
    if (!mounted) return;
    setState(() => items = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan History")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return ListTile(
            leading: Image.file(
              File(item.imagePath),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(
              item.extractedText.length > 30
                  ? "${item.extractedText.substring(0, 30)}..."
                  : item.extractedText,
            ),
            onTap: () async {
              final result = await Navigator.push<bool?>(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryPreviewScreen(item: item),
                ),
              );

              // If the preview signalled a deletion, refresh the list
              if (result == true) {
                await loadHistory();
              }
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Scan?'),
                    content: const Text(
                      'Are you sure you want to delete this scan?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await StorageService.deleteHistoryItem(item.id);
                  await loadHistory();
                  // No popup on delete by default
                }
              },
            ),
          );
        },
      ),
    );
  }
}
