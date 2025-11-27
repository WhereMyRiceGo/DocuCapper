import 'dart:io';
import 'package:flutter/material.dart';
import 'ocr_screen.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview Image")),
      body: Column(
        children: [
          Expanded(child: Center(child: Image.file(File(imagePath)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OcrScreen(imagePath: imagePath),
                      ),
                    );
                  },
                  icon: const Icon(Icons.text_fields),
                  label: const Text("Extract Text"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
