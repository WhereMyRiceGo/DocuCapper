import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';

class OcrScreen extends StatefulWidget {
  final String imagePath;
  const OcrScreen({super.key, required this.imagePath});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  String extractedText = "Processing...";
  TextEditingController? _textController;
  bool _isEditing = false;
  bool _showConfidence = false;
  bool _showImage = false;
  List<TextBlock> _textBlocks = [];
  double _averageConfidence = 0.0;
  int? _selectedLineIndex;
  ui.Image? _loadedImage;
  double _splitRatio = 0.6; // 60% for image, 40% for text by default
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    runOcr();
    _loadImage();
  }

  @override
  void dispose() {
    _textController?.dispose();
    _loadedImage?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final file = File(widget.imagePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _loadedImage = frame.image;
    });
  }

  Future<void> runOcr() async {
    // Use script detection for better handwriting recognition
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFilePath(widget.imagePath);

    final recognizedText = await recognizer.processImage(inputImage);

    if (!mounted) return;

    // Calculate average confidence from lines (blocks don't have confidence in ML Kit)
    double totalConfidence = 0.0;
    int lineCount = 0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        // Estimate confidence based on number of recognized elements
        // This is a workaround since ML Kit doesn't expose confidence directly
        totalConfidence += line.elements.isNotEmpty ? 0.85 : 0.5;
        lineCount++;
      }
    }

    final avgConfidence = lineCount > 0 ? totalConfidence / lineCount : 0.0;

    setState(() {
      extractedText = recognizedText.text;
      _textBlocks = recognizedText.blocks;
      _averageConfidence = avgConfidence;
      _textController = TextEditingController(text: extractedText);
    });

    // Automatically save to history (duplicates prevented by imagePath check)
    await StorageService.addToHistory(widget.imagePath, recognizedText.text);

    recognizer.close();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _textController?.text = extractedText;
      } else {
        extractedText = _textController?.text ?? extractedText;
      }
    });
  }

  String _getConfidenceLabel() {
    if (_averageConfidence >= 0.8) return 'High';
    if (_averageConfidence >= 0.6) return 'Medium';
    return 'Low';
  }

  Color _getConfidenceColor() {
    if (_averageConfidence >= 0.8) return Colors.green;
    if (_averageConfidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildHighlightedText() {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    if (_textBlocks.isEmpty) {
      return Text(
        extractedText,
        style: TextStyle(fontSize: 14, color: textColor),
      );
    }

    final spans = <TextSpan>[];
    int lineIndex = 0;

    for (final block in _textBlocks) {
      for (final line in block.lines) {
        final currentLineIndex = lineIndex;
        // Highlight lines with potentially low confidence (few elements)
        final isLowConfidence = line.elements.length < 3;
        final isSelected = _selectedLineIndex == currentLineIndex;

        spans.add(
          TextSpan(
            text: '${line.text}\n',
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              backgroundColor: isSelected
                  ? Colors.blue.withOpacity(0.3)
                  : (_showConfidence && isLowConfidence
                        ? Colors.orange.withOpacity(0.3)
                        : null),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                setState(() {
                  _selectedLineIndex = isSelected ? null : currentLineIndex;
                });
              },
          ),
        );
        lineIndex++;
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 14, color: textColor),
        children: spans,
      ),
    );
  }

  void _handleImageTap(Offset position, double currentScale) {
    if (_loadedImage == null || _textBlocks.isEmpty) return;

    int lineIndex = 0;
    for (final block in _textBlocks) {
      for (final line in block.lines) {
        final rect = line.boundingBox;

        // Check if tap is within this line's bounding box
        if (rect.contains(Offset(position.dx, position.dy))) {
          setState(() {
            _selectedLineIndex = _selectedLineIndex == lineIndex
                ? null
                : lineIndex;
          });
          return;
        }
        lineIndex++;
      }
    }

    // If no line was tapped, clear selection
    setState(() {
      _selectedLineIndex = null;
    });
  }

  Widget _buildImageWithHighlight() {
    if (_loadedImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      child: GestureDetector(
        onTapUp: (details) {
          // Get the current transformation matrix
          final matrix = _transformationController.value;
          final scale = matrix.getMaxScaleOnAxis();

          // Transform tap position to image coordinates
          final localPos = details.localPosition;
          final transformedPos = MatrixUtils.transformPoint(
            Matrix4.inverted(matrix),
            localPos,
          );

          _handleImageTap(transformedPos, scale);
        },
        child: CustomPaint(
          painter: _ImageHighlightPainter(
            image: _loadedImage!,
            textBlocks: _textBlocks,
            selectedLineIndex: _selectedLineIndex,
          ),
          child: Container(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Extracted Text"),
        actions: [
          if (_averageConfidence > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                avatar: Icon(
                  Icons.check_circle,
                  color: _getConfidenceColor(),
                  size: 16,
                ),
                label: Text(
                  '${(_averageConfidence * 100).toInt()}% ${_getConfidenceLabel()}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          IconButton(
            onPressed: () {
              setState(() {
                _showConfidence = !_showConfidence;
              });
            },
            icon: Icon(
              _showConfidence ? Icons.highlight : Icons.highlight_outlined,
            ),
            tooltip: _showConfidence ? 'Hide confidence' : 'Show confidence',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showImage = !_showImage;
                if (!_showImage) {
                  _selectedLineIndex =
                      null; // Clear selection when hiding image
                }
              });
            },
            icon: Icon(_showImage ? Icons.image : Icons.image_outlined),
            tooltip: _showImage ? 'Hide image' : 'Show image',
          ),
          IconButton(
            onPressed: _toggleEdit,
            icon: Icon(_isEditing ? Icons.visibility : Icons.edit),
            tooltip: _isEditing ? 'View mode' : 'Edit mode',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showConfidence &&
              _averageConfidence > 0 &&
              _averageConfidence < 0.7)
            Container(
              width: double.infinity,
              color: Colors.orange.withOpacity(0.2),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[800], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Low confidence detected. Please review and edit the text.',
                      style: TextStyle(color: Colors.orange[800], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _showImage
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        children: [
                          SizedBox(
                            height: constraints.maxHeight * _splitRatio,
                            child: Card(
                              margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildImageWithHighlight(),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onVerticalDragUpdate: (details) {
                              setState(() {
                                _splitRatio +=
                                    details.delta.dy / constraints.maxHeight;
                                _splitRatio = _splitRatio.clamp(0.2, 0.8);
                              });
                            },
                            child: Container(
                              height: 12,
                              color: Colors.transparent,
                              child: Center(
                                child: Container(
                                  height: 4,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height:
                                constraints.maxHeight * (1 - _splitRatio) - 12,
                            child: Card(
                              margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                              child: _isEditing
                                  ? TextField(
                                      controller: _textController,
                                      maxLines: null,
                                      expands: true,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(12),
                                        hintText: 'Edit extracted text...',
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.all(12),
                                      child: _buildHighlightedText(),
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : Card(
                    margin: const EdgeInsets.all(12),
                    child: _isEditing
                        ? TextField(
                            controller: _textController,
                            maxLines: null,
                            expands: true,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                              hintText: 'Edit extracted text...',
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: _buildHighlightedText(),
                          ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final textToCopy = _isEditing
                          ? (_textController?.text ?? extractedText)
                          : extractedText;

                      await Clipboard.setData(ClipboardData(text: textToCopy));

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text("Copy"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final textToShare = _isEditing
                          ? (_textController?.text ?? extractedText)
                          : extractedText;

                      await Share.share(textToShare);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text("Share"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final textToSave = _isEditing
                          ? (_textController?.text ?? extractedText)
                          : extractedText;

                      await StorageService.saveNote(
                        textToSave,
                        imagePath: widget.imagePath,
                      );

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saved as note'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("Save"),
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

class _ImageHighlightPainter extends CustomPainter {
  final ui.Image image;
  final List<TextBlock> textBlocks;
  final int? selectedLineIndex;

  _ImageHighlightPainter({
    required this.image,
    required this.textBlocks,
    this.selectedLineIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the image scaled to fit
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final imageAspect = imageWidth / imageHeight;
    final canvasAspect = size.width / size.height;

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    if (canvasAspect > imageAspect) {
      // Canvas is wider - fit to height
      scale = size.height / imageHeight;
      offsetX = (size.width - imageWidth * scale) / 2;
    } else {
      // Canvas is taller - fit to width
      scale = size.width / imageWidth;
      offsetY = (size.height - imageHeight * scale) / 2;
    }

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, imageWidth, imageHeight),
      Rect.fromLTWH(offsetX, offsetY, imageWidth * scale, imageHeight * scale),
      Paint(),
    );

    // Draw highlight if a line is selected
    if (selectedLineIndex != null) {
      int currentIndex = 0;
      for (final block in textBlocks) {
        for (final line in block.lines) {
          if (currentIndex == selectedLineIndex) {
            final rect = line.boundingBox;
            final scaledRect = Rect.fromLTRB(
              rect.left * scale + offsetX,
              rect.top * scale + offsetY,
              rect.right * scale + offsetX,
              rect.bottom * scale + offsetY,
            );

            final paint = Paint()
              ..color = Colors.blue.withOpacity(0.3)
              ..style = PaintingStyle.fill;

            final borderPaint = Paint()
              ..color = Colors.blue
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2;

            canvas.drawRect(scaledRect, paint);
            canvas.drawRect(scaledRect, borderPaint);
            return;
          }
          currentIndex++;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ImageHighlightPainter oldDelegate) {
    return oldDelegate.selectedLineIndex != selectedLineIndex ||
        oldDelegate.image != image;
  }
}
