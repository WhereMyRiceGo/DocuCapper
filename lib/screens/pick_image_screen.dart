import 'package:docucapper/screens/history_screen.dart';
import 'package:docucapper/screens/notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'image_preview_screen.dart';

class PickImageScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  const PickImageScreen({super.key, this.onToggleTheme});

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
      appBar: AppBar(
        title: const Text("DocuCapper"),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Scan Document',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: pickImageFromGallery,
                        icon: const Icon(Icons.photo),
                        label: const Text("Choose from Gallery"),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: pickImageFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Use Camera"),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotesScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.note,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              const Text("Saved Notes"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              const Text("History"),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
