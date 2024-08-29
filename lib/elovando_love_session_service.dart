import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> logToFile(String message) async {
  print(message);
}

class ElovandoLoveSessionService {
  final String apiKey;
  final String organizationId;
  final String assistantId = 'asst_t1AFNgjmMn7tHbHvqmFMb3G6';
  final String baseUrl = 'https://api.openai.com/v1';
  String? _threadId;
  Map<String, String> _preloadedMessages = {};
  bool _isPreloaded = false;
  late bool _partnerAStarts;

  ElovandoLoveSessionService(this.apiKey, this.organizationId) {
    _partnerAStarts = Random().nextBool();
  }

  Future<Map<String, dynamic>> startLoveSession(
      String userId, Function(String, double) progressCallback) async {
    try {
      progressCallback("Love Session wird erstellt...", 0.1);
      await initializeThread(userId);
      progressCallback("Love Session erstellt", 0.2);
      await preloadMessages(progressCallback);
      final response = _preloadedMessages['intro']!;
      progressCallback("Love Session bereit", 1.0);
      return {
        'intro': response,
        'nextStep': _partnerAStarts ? 'partnerAToB' : 'partnerBToA',
      };
    } catch (e) {
      print("Fehler beim Starten der Love Session: $e");
      return {
        'error':
            'Beim Starten der Love Session ist ein Fehler aufgetreten. Bitte versuchen Sie es erneut.'
      };
    }
  }

  Future<void> createNewThread(String userId) async {
    _threadId = await createThread();
    await _updateUserThreadId(userId, _threadId!);
    _isPreloaded = false;
  }

  Future<void> initializeThread(String userId) async {
    if (userId.isEmpty) {
      throw Exception('Invalid user ID');
    }

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final partnerUserId = userDoc.data()?['partnerId'];
    _threadId = userDoc.data()?['loveSessionThreadId'];

    if (_threadId == null || _threadId!.isEmpty) {
      _threadId = await createThread();
      await _updateUserThreadId(userId, _threadId!);
      if (partnerUserId != null) {
        await _updateUserThreadId(partnerUserId, _threadId!);
      }
    } else {
      // Verify if the thread still exists
      try {
        await http.get(
          Uri.parse('$baseUrl/threads/$_threadId'),
          headers: _getHeaders(),
        );
      } catch (e) {
        // If the thread doesn't exist, create a new one
        print("Existing thread not found. Creating a new one.");
        _threadId = await createThread();
        await _updateUserThreadId(userId, _threadId!);
        if (partnerUserId != null) {
          await _updateUserThreadId(partnerUserId, _threadId!);
        }
      }
    }

    if (partnerUserId != null) {
      final partnerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(partnerUserId)
          .get();
      final partnerThreadId = partnerDoc.data()?['loveSessionThreadId'];
      if (partnerThreadId != null && partnerThreadId != _threadId) {
        _threadId = partnerThreadId;
        await _updateUserThreadId(userId, _threadId!);
      }
    }

    await logToFile("Thread initialized: $_threadId for user: $userId");
  }

  Future<void> _updateUserThreadId(String userId, String threadId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'loveSessionThreadId': threadId,
    });
  }

  Future<Map<String, dynamic>> getPartnerStatement(
      String from, String to) async {
    try {
      print("Hole Aussage von Partner $from für Partner $to");
      final key = 'partner${from}To${to}Statement';
      final response = _preloadedMessages[key]!;
      print("Aussage von Partner $from für Partner $to: $response");
      String nextStep;
      if (_partnerAStarts) {
        nextStep = from == 'A' ? 'partnerBToA' : 'outro';
      } else {
        nextStep = from == 'B' ? 'partnerAToB' : 'outro';
      }
      return {
        'statement': response,
        'nextStep': nextStep,
      };
    } catch (e) {
      print("Fehler beim Abrufen der Partneraussage: $e");
      return {
        'error':
            'Beim Abrufen der Partneraussage ist ein Fehler aufgetreten. Bitte versuchen Sie es erneut.'
      };
    }
  }

  Future<Map<String, dynamic>> getOutro() async {
    try {
      print("Hole Outro...");
      final response = _preloadedMessages['outro']!;
      print("Outro-Antwort: $response");
      return {
        'outro': response,
        'nextStep': 'end',
      };
    } catch (e) {
      print("Fehler beim Abrufen des Outros: $e");
      return {
        'error':
            'Beim Abrufen des Outros ist ein Fehler aufgetreten. Bitte versuchen Sie es erneut.'
      };
    }
  }

  Future<void> preloadMessages(
      Function(String, double) progressCallback) async {
    if (_isPreloaded) return;
    if (_threadId == null) {
      throw Exception(
          'Thread nicht initialisiert. Rufen Sie zuerst startLoveSession auf.');
    }
    try {
      progressCallback("Intro wird vorbereitet...", 0.3);
      _preloadedMessages['intro'] =
          await sendMessage("Erstelle ein Intro für die Love Session. Diese Antwort wird sofort in gesprochenen Text umgewandelt und dem Benutzer vorgelesen.");

      progressCallback("Aussage für Partner A wird vorbereitet...", 0.5);
      _preloadedMessages['partnerAToBStatement'] = await sendMessage(
          "Generiere eine Aussage, die Partner A in der Love Session laut an Partner B vorlesen soll.");

      progressCallback("Aussage für Partner B wird vorbereitet...", 0.7);
      _preloadedMessages['partnerBToAStatement'] = await sendMessage(
          "Generiere eine Aussage, die Partner B in der Love Session laut an Partner A vorlesen soll.");

      progressCallback("Outro wird vorbereitet...", 0.9);
      _preloadedMessages['outro'] =
          await sendMessage("Erstelle ein Outro für die Love Session. Diese Antwort wird sofort in gesprochenen Text umgewandelt und dem Benutzer vorgelesen.");

      _isPreloaded = true;
    } catch (e) {
      print("Fehler beim Vorladen der Nachrichten: $e");
      throw Exception('Fehler beim Vorladen der Nachrichten: $e');
    }
  }

  bool get isPreloaded => _isPreloaded;

  Future<String> createThread() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/threads'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['id'];
      } else {
        print(
            "Fehler beim Erstellen des Threads. Statuscode: ${response.statusCode}, Antwort: ${response.body}");
        throw Exception(
            'Fehler beim Erstellen des Threads: ${response.statusCode}');
      }
    } catch (e) {
      print("Ausnahme beim Erstellen des Threads: $e");
      throw Exception('Fehler beim Erstellen des Threads: $e');
    }
  }

  Future<String> sendMessage(String message, {bool isForDisplay = true}) async {
    if (_threadId == null) {
      throw Exception('Thread nicht initialisiert. Rufen Sie zuerst initializeThread auf.');
    }
    
    String modifiedMessage = message;
    if (isForDisplay) {
      modifiedMessage += "\n\nHinweis: Deine Antwort wird direkt dem Benutzer angezeigt, ohne weitere Verarbeitung. Bitte stelle sicher, dass deine Ausgabe vollständig, gut formatiert und für die sofortige Anzeige bereit ist. Die Antwort sollte auf Deutsch sein.";
    } else {
      modifiedMessage += "\n\nHinweis: Diese Information ist nur für deine interne Verarbeitung bestimmt. Sie wird nicht direkt angezeigt oder gelesen. Bitte verwende diese Information, um den Kontext der Konversation zu verbessern und passendere Antworten zu generieren.";
    }

    await logToFile("Sending message. Thread ID: $_threadId, Message: $modifiedMessage");

    try {
      await _retryOperation(() async {
        final response = await http.post(
          Uri.parse('$baseUrl/threads/$_threadId/messages'),
          headers: _getHeaders(),
          body: jsonEncode({
            'role': 'user',
            'content': modifiedMessage,
          }),
        );
        if (response.statusCode == 404) {
          // Thread not found, create a new one
          await logToFile("Thread not found. Creating a new one.");
          _threadId = await createThread();
          // Retry sending the message with the new thread
          final retryResponse = await http.post(
            Uri.parse('$baseUrl/threads/$_threadId/messages'),
            headers: _getHeaders(),
            body: jsonEncode({
              'role': 'user',
              'content': modifiedMessage,
            }),
          );
          if (retryResponse.statusCode != 200) {
            throw Exception('Fehler beim Senden der Nachricht: ${retryResponse.statusCode}. Body: ${retryResponse.body}');
          }
        } else if (response.statusCode != 200) {
          await logToFile("Error sending message. Status code: ${response.statusCode}, Body: ${response.body}");
          throw Exception('Fehler beim Senden der Nachricht: ${response.statusCode}. Body: ${response.body}');
        }
      });

      final runResponse = await _retryOperation(() async {
        final response = await http.post(
          Uri.parse('$baseUrl/threads/$_threadId/runs'),
          headers: _getHeaders(),
          body: jsonEncode({
            'assistant_id': assistantId,
          }),
        );
        if (response.statusCode != 200) {
          await logToFile("Error creating run. Status code: ${response.statusCode}, Body: ${response.body}");
          throw Exception(
              'Fehler beim Starten des Runs: ${response.statusCode}. Body: ${response.body}');
        }
        return response;
      });

      final runId = jsonDecode(runResponse.body)['id'];

      await _waitForRunCompletion(runId);

      final messagesResponse = await _retryOperation(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/threads/$_threadId/messages'),
          headers: _getHeaders(),
        );
        if (response.statusCode != 200) {
          await logToFile("Error retrieving messages. Status code: ${response.statusCode}, Body: ${response.body}");
          throw Exception(
              'Fehler beim Abrufen der Nachrichten: ${response.statusCode}. Body: ${response.body}');
        }
        return response;
      });

      final messages = jsonDecode(messagesResponse.body)['data'];
      String response = messages[0]['content'][0]['text']['value'];
      
      await logToFile("Received response: $response");
      return utf8.decode(response.runes.toList()).replaceAll('**', '');

    } catch (e) {
      await logToFile("Error in sendMessage: ${e.toString()}");
      print("Fehler beim Senden der Nachricht: $e");
      throw Exception('Fehler beim Senden der Nachricht: $e');
    }
  }

  Future<void> _waitForRunCompletion(String runId) async {
    int retries = 0;
    const maxRetries = 60; // 5 minutes max wait time
    while (retries < maxRetries) {
      try {
        final statusResponse = await http.get(
          Uri.parse('$baseUrl/threads/$_threadId/runs/$runId'),
          headers: _getHeaders(),
        );
        final status = jsonDecode(statusResponse.body)['status'];

        if (status == 'completed') {
          return;
        } else if (status == 'failed') {
          await logToFile("Run failed. Status: $status, Response: ${statusResponse.body}");
          print(
              "Run failed. Status: $status, Response: ${statusResponse.body}");
          throw Exception('Run failed: $status');
        }
      } catch (e) {
        await logToFile("Error checking run status: $e");
        print("Fehler beim Abrufen des Run-Status: $e");
      }
      await Future.delayed(Duration(seconds: 5));
      retries++;
    }
    throw Exception('Timeout beim Warten auf Run-Abschluss');
  }

  Future<T> _retryOperation<T>(Future<T> Function() operation,
      {int maxRetries = 3}) async {
    int retries = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        if (retries >= maxRetries) {
          rethrow;
        }
        retries++;
        await Future.delayed(Duration(seconds: 1 * retries));
      }
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'OpenAI-Beta': 'assistants=v2', // Updated to v1 as v2 is deprecated
      'OpenAI-Organization': organizationId,
    };
  }

  Future<void> shareOnboardingInfo(String userId, Map<String, dynamic> onboardingInfo) async {
    await initializeThread(userId);
    final message = "Onboarding-Informationen für Benutzer $userId:\n" +
        onboardingInfo.entries.map((e) => "${e.key}: ${e.value}").join("\n");
    await logToFile("INITIAL ONBOARDING for $userId: $message");

    await sendMessage(message, isForDisplay: false);
  }

  Future<void> updateOnboardingInfo(String userId, Map<String, dynamic> newInfo) async {
    await initializeThread(userId);
    if (newInfo.isEmpty) return; // No new info to update

    String formattedInfo = newInfo.entries.map((e) => "${e.key}: ${e.value}").join("\n");
    String message = "Updated user information for $userId:\n$formattedInfo";
    await logToFile("ONBOARDING UPDATE for $userId: $formattedInfo");

    await sendMessage(message, isForDisplay: false);
  }

  Future<void> shareUserInput(String userId, String input) async {
    await initializeThread(userId);
    final message = "Input von Benutzer $userId:\n$input";
    await sendMessage(message, isForDisplay: false);
  }

  Future<void> shareFeedback(String userId, String feedback) async {
    await initializeThread(userId);
    final message = "Feedback von Benutzer $userId:\n$feedback";
    await sendMessage(message, isForDisplay: false);
  }
}
