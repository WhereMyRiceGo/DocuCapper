import 'package:flutter/material.dart';
import '../services/openai_service.dart';

class SummaryScreen extends StatefulWidget {
  final String fullText;
  const SummaryScreen({super.key, required this.fullText});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String summary = "Summarizing...";

  @override
  void initState() {
    super.initState();
    summarizeText();
  }

  Future<void> summarizeText() async {
    final result = await OpenAIService.summarize(widget.fullText);
    setState(() {
      summary = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Summary")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(child: Text(summary)),
        ),
      ),
    );
  }
}
