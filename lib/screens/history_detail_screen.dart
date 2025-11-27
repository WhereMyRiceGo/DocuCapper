import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scan_history_item.dart';

class HistoryDetailScreen extends StatelessWidget {
  final ScanHistoryItem item;

  const HistoryDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Details")),
      body: Column(
        children: [
          Expanded(flex: 2, child: Image.file(File(item.imagePath))),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(child: Text(item.extractedText)),
            ),
          ),
        ],
      ),
    );
  }
}
