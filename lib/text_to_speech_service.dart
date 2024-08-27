import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TextToSpeechService {
  late final String apiKey;
  final String apiUrl = 'https://api.openai.com/v1/audio/speech';

  TextToSpeechService() {
    apiKey = dotenv.env['OPEN_AI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('OPEN_AI_API_KEY not found in .env file');
    }
  }

  Future<List<int>> generateSpeech(String text, {String voice = 'alloy', String language = 'de'}) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'tts-1',
        'input': text,
        'voice': voice,
      }),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to generate speech: ${response.body}');
    }
  }
}