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
  bool _isSelecting = false;
  Set<String> _selectedIds = {};

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
          'Are you sure you want to delete ${_selectedIds.length} scan(s)?',
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
        await StorageService.deleteHistoryItem(id);
      }
      _selectedIds.clear();
      _isSelecting = false;
      await loadHistory();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected scans deleted'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deleteAll() async {
    if (items.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All?'),
        content: Text(
          'Are you sure you want to delete all ${items.length} scan(s)?',
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
      for (final item in items) {
        await StorageService.deleteHistoryItem(item.id);
      }
      await loadHistory();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All scans deleted'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelecting ? '${_selectedIds.length} selected' : 'Scan History',
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
            if (items.isNotEmpty)
              IconButton(
                onPressed: _toggleSelectMode,
                icon: const Icon(Icons.checklist),
                tooltip: 'Select items',
              ),
            if (items.isNotEmpty)
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
      ),
      body: items.isEmpty
          ? const Center(child: Text('No scan history'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = _selectedIds.contains(item.id);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: _isSelecting
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(item.id),
                          )
                        : Image.file(
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
                    onTap: _isSelecting
                        ? () => _toggleSelection(item.id)
                        : () async {
                            final result = await Navigator.push<bool?>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    HistoryPreviewScreen(item: item),
                              ),
                            );

                            if (result == true) {
                              await loadHistory();
                            }
                          },
                    trailing: _isSelecting
                        ? null
                        : IconButton(
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
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
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

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Scan deleted'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                );
              },
            ),
    );
  }
}
