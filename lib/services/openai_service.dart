import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  // NOTE: Summarizer is temporarily disabled. To re-enable, set
  // `summarizerEnabled = true` and implement a secure way to provide an API key
  // (do NOT hardcode keys in source; use a backend proxy or `--dart-define` for dev).
  static const bool summarizerEnabled = false;

  // The API key used to be hardcoded here; it has been removed for safety.
  // Keep the placeholder for reference only.
  static const String apiKey = "";

  static Future<String> summarize(String text) async {
    if (!summarizerEnabled) {
      // Return the original extracted text while the summarizer is disabled.
      return Future.value(text);
    }

    // If re-enabled, implement the OpenAI call here using a secure key source.
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {"role": "system", "content": "Summarize this text."},
          {"role": "user", "content": text},
        ],
      }),
    );

    final data = jsonDecode(response.body);

    // Handle errors from OpenAI
    if (data["error"] != null) {
      return "Error from OpenAI: ${data["error"]["message"]}";
    }

    // Guard against null choices
    if (data["choices"] == null || data["choices"].isEmpty) {
      return "No response from OpenAI.";
    }

    return data["choices"][0]["message"]["content"];
  }
}
