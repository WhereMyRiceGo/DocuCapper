import 'package:docucapper/screens/history_screen.dart';
import 'package:docucapper/screens/notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'image_preview_screen.dart';

class PickImageScreen extends StatefulWidget {
  const PickImageScreen({super.key});

  @override
  State<PickImageScreen> createState() => _PickImageScreenState();
}

class _PickImageScreenState extends State<PickImageScreen> {
  final ImagePicker picker = ImagePicker();

  Future<void> pickImageFromGallery() async {
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return; // Safe because we use this.context below

    if (file == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No image selected")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewScreen(imagePath: file.path),
      ),
    );
  }

  Future<void> pickImageFromCamera() async {
    final XFile? file = await picker.pickImage(source: ImageSource.camera);

    if (!mounted) return; // Safe

    if (file == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No image captured")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewScreen(imagePath: file.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DocuCapper")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await pickImageFromGallery();
              },
              icon: const Icon(Icons.photo),
              label: const Text("Choose from Gallery"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await pickImageFromCamera();
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text("Use Camera"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotesScreen()),
                );
              },
              child: const Text("View Notes"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
              child: const Text("View Scan History"),
            ),
          ],
        ),
      ),
    );
  }
}
