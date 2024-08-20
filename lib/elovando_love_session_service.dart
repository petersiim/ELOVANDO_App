import 'dart:convert';
import 'package:http/http.dart' as http;

class ElovandoLoveSessionService {
  final String apiKey;
  final String organizationId;
  final String assistantId = 'asst_t1AFNgjmMn7tHbHvqmFMb3G6';
  final String baseUrl = 'https://api.openai.com/v1';
  String? _threadId;

  ElovandoLoveSessionService(this.apiKey, this.organizationId);

  Future<Map<String, dynamic>> startLoveSession() async {
    try {
      print("Starting love session...");
      _threadId = await createThread();
      print("Thread created: $_threadId");
      final response = await sendMessage("Start a new love session. Provide an introduction for the AI therapist.");
      print("Love session started. Response: $response");
      return {
        'intro': response,
        'nextStep': 'partnerAStatement',
      };
    } catch (e) {
      print("Error starting love session: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPartnerStatement(String partner) async {
    try {
      print("Getting statement for partner $partner");
      final prompt = "Generate a statement for partner $partner to read aloud in the love session.";
      final response = await sendMessage(prompt);
      print("Partner $partner statement response: $response");
      return {
        'statement': response,
        'nextStep': partner == 'A' ? 'partnerBStatement' : 'outro',
      };
    } catch (e) {
      print("Error getting partner statement: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOutro() async {
    try {
      print("Getting outro...");
      final response = await sendMessage("Provide a concluding statement for the love session.");
      print("Outro response: $response");
      return {
        'outro': response,
        'nextStep': 'end',
      };
    } catch (e) {
      print("Error getting outro: $e");
      rethrow;
    }
  }

  Future<String> createThread() async {
    final response = await http.post(
      Uri.parse('$baseUrl/threads'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['id'];
    } else {
      throw Exception('Failed to create thread');
    }
  }

  Future<String> sendMessage(String message) async {
    if (_threadId == null) {
      throw Exception('Thread not initialized. Call startLoveSession first.');
    }
      String modifiedMessage = "$message\n\nNote: Your response will be directly shown to the user without further processing. Please ensure your output is complete, well-formatted, and ready for immediate display.";

    await http.post(
      Uri.parse('$baseUrl/threads/$_threadId/messages'),
      headers: _getHeaders(),
      body: jsonEncode({
        'role': 'user',
        'content': modifiedMessage,
      }),
    );

    final runResponse = await http.post(
      Uri.parse('$baseUrl/threads/$_threadId/runs'),
      headers: _getHeaders(),
      body: jsonEncode({
        'assistant_id': assistantId,
      }),
    );

    final runId = jsonDecode(runResponse.body)['id'];

    while (true) {
      final statusResponse = await http.get(
        Uri.parse('$baseUrl/threads/$_threadId/runs/$runId'),
        headers: _getHeaders(),
      );
      final status = jsonDecode(statusResponse.body)['status'];

      if (status == 'completed') {
        break;
      }
      await Future.delayed(Duration(seconds: 1));
    }

    final messagesResponse = await http.get(
      Uri.parse('$baseUrl/threads/$_threadId/messages'),
      headers: _getHeaders(),
    );

    final messages = jsonDecode(messagesResponse.body)['data'];
    return messages[0]['content'][0]['text']['value'];
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'OpenAI-Beta': 'assistants=v2',
      'OpenAI-Organization': organizationId,
    };
  }
}