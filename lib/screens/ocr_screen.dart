import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/storage_service.dart';
import 'summary_screen.dart';

class OcrScreen extends StatefulWidget {
  final String imagePath;
  const OcrScreen({super.key, required this.imagePath});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  String extractedText = "Processing...";

  @override
  void initState() {
    super.initState();
    runOcr();
  }

  Future<void> runOcr() async {
    final recognizer = TextRecognizer();
    final inputImage = InputImage.fromFilePath(widget.imagePath);

    final recognizedText = await recognizer.processImage(inputImage);

    if (!mounted) return; // Safe because using the State.context

    setState(() {
      extractedText = recognizedText.text;
    });

    // Do not automatically save to history here. Saving is now explicit via
    // the "Save to History" button to avoid duplicate / unwanted entries.
    recognizer.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Extracted Text")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Text(extractedText),
            ),
          ),

          // Save as note
          ElevatedButton(
            onPressed: () async {
              await StorageService.saveNote(extractedText);

              if (!context.mounted) return; // Correct: button callback context

              // Intentionally no popup on save to follow project UX preferences
            },
            child: const Text("Save as Note"),
          ),

          const SizedBox(height: 8),
          // Save to history (explicit)
          ElevatedButton(
            onPressed: () async {
              await StorageService.addToHistory(
                widget.imagePath,
                extractedText,
              );
              // No popup on save by default
            },
            child: const Text('Save to History'),
          ),

          // Summarize
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SummaryScreen(fullText: extractedText),
                ),
              );
            },
            child: const Text("Summarize"),
          ),
        ],
      ),
    );
  }
}
