import 'package:flutter/material.dart';
import 'screens/pick_image_screen.dart';

void main() {
  runApp(const DocuCapperApp());
}

class DocuCapperApp extends StatelessWidget {
  const DocuCapperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PickImageScreen(),
    );
  }
}
