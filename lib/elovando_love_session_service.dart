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
  late String _userAName;
  late String _userBName;

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

  Future<void> initializeThread(String userId) async {
    if (userId.isEmpty) {
      throw Exception('Invalid user ID');
    }

    await logToFile("Initializing thread for user: $userId");

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final partnerUserId = userDoc.data()?['partnerId'];
    _threadId = userDoc.data()?['loveSessionThreadId'];

    if (_threadId != null) {
      try {
        // Verify if the thread still exists
        await http.get(
          Uri.parse('$baseUrl/threads/$_threadId'),
          headers: _getHeaders(),
        );
        await logToFile("Existing thread found: $_threadId");
      } catch (e) {
        // If the thread doesn't exist, create a new one
        await logToFile("Existing thread not found. Creating a new one.");
        _threadId = await createThread();
      }
    } else {
      // If no thread ID is found, create a new one
      _threadId = await createThread();
      await logToFile("New thread created: $_threadId");
    }

    // Update or create the thread document in Firestore
    await FirebaseFirestore.instance.collection('loveSessionThreads').doc(_threadId).set({
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'participants': [
        userId,
        if (partnerUserId != null) partnerUserId,
      ],
    }, SetOptions(merge: true));

    // Update the thread ID for both users
    await _updateUserThreadId(userId, _threadId!);
    if (partnerUserId != null) {
      await _updateUserThreadId(partnerUserId, _threadId!);
    }

    _userAName = userDoc.data()?['name'] as String? ?? 'Partner A';
    if (partnerUserId != null) {
      final partnerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(partnerUserId)
          .get();
      _userBName = partnerDoc.data()?['name'] as String? ?? 'Partner B';
    } else {
      _userBName = 'Partner B';
    }

    await logToFile("Thread initialized: $_threadId for user: $userId");
    await logToFile("User A: $_userAName, User B: $_userBName");
  }

  Future<void> renewThread(String userId) async {
    await initializeThread(userId);
    await logToFile("Thread renewed: $_threadId for user: $userId");
  }

  Future<void> _updateUserThreadId(String userId, String threadId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'loveSessionThreadId': threadId,
    });
    await logToFile("Updated thread ID for user $userId: $threadId");
  }

  Future<Map<String, dynamic>> getPartnerStatement(
      String from, String to) async {
    try {
      print("Hole Aussage von Partner $from für Partner $to");
      final key = 'partner${from}To${to}Statement';
      String response = _preloadedMessages[key]!;
      String fromName = from == 'A' ? _userAName : _userBName;
      String toName = to == 'A' ? _userAName : _userBName;
      response = "$fromName, bitte lies das folgende Statement $toName vor:\n\n$response";
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
          "Generiere eine Aussage, die $_userAName in der Love Session laut an $_userBName vorlesen soll.");

      progressCallback("Aussage für Partner B wird vorbereitet...", 0.7);
      _preloadedMessages['partnerBToAStatement'] = await sendMessage(
          "Generiere eine Aussage, die $_userBName in der Love Session laut an $_userAName vorlesen soll.");

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
        final threadId = jsonDecode(response.body)['id'];
        await logToFile("Thread created successfully: $threadId");
        return threadId;
      } else {
        await logToFile("Error creating thread. Status code: ${response.statusCode}, Response: ${response.body}");
        throw Exception(
            'Fehler beim Erstellen des Threads: ${response.statusCode}');
      }
    } catch (e) {
      await logToFile("Exception while creating thread: $e");
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
        if (response.statusCode != 200) {
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
      'OpenAI-Beta': 'assistants=v2',
      'OpenAI-Organization': organizationId,
    };
  }

  dynamic _convertTimestamps(dynamic data) {
    if (data is Timestamp) {
      return data.toDate().toIso8601String();
    } else if (data is Map) {
      return data.map((key, value) => MapEntry(key, _convertTimestamps(value)));
    } else if (data is List) {
      return data.map(_convertTimestamps).toList();
    }
    return data;
  }

  Future<Map<String, dynamic>> _getUserOnboardingInfo(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    final convertedData = _convertTimestamps(userData);
    await logToFile("DEBUG: Raw user data for $userId: ${jsonEncode(convertedData)}");
    
    // Extract relevant onboarding information
    final onboardingInfo = {
      'name': convertedData['name'],
      'gender': convertedData['gender'],
      'birthdate': convertedData['birthdate'],
      'relationshipMovie': convertedData['question1'],
      'relationshipAnimal': convertedData['question2'],
      'cookingRoleUser': convertedData['question6'],
      'cookingRolePartner': convertedData['question7'],
      'partnerSupport': convertedData['question8'],
      'deadlySin': convertedData['question9'],
      'relationshipDetails': convertedData['question10'],
    };
    
    return onboardingInfo;
  }

  Future<void> shareOnboardingInfo(String userId, Map<String, dynamic> onboardingInfo) async {
    await initializeThread(userId);
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] ?? 'Unbekannt';
    final partnerUserId = userDoc.data()?['partnerId'];

    final userOnboardingInfo = await _getUserOnboardingInfo(userId);
    await logToFile("DEBUG: User onboarding info for $userName: ${jsonEncode(userOnboardingInfo)}");

    String message = "Onboarding-Informationen für Benutzer $userName:\n" +
        _formatOnboardingInfo(userOnboardingInfo);

    if (partnerUserId != null) {
      await logToFile("DEBUG: Partner found with ID: $partnerUserId");
      final partnerDoc = await FirebaseFirestore.instance.collection('users').doc(partnerUserId).get();
      final partnerName = partnerDoc.data()?['name'] ?? 'Unbekannt';
      final partnerOnboardingInfo = await _getUserOnboardingInfo(partnerUserId);

      await logToFile("DEBUG: Partner onboarding info for $partnerName: ${jsonEncode(partnerOnboardingInfo)}");

      message += "\n\nOnboarding-Informationen für Partner $partnerName:\n" +
          _formatOnboardingInfo(partnerOnboardingInfo);
    } else {
      await logToFile("DEBUG: No partner found for user $userName");
    }

    await logToFile("DEBUG: Final message to be sent: $message");
    await sendMessage(message, isForDisplay: false);
  }

  String _formatOnboardingInfo(Map<String, dynamic> info) {
    if (info.isEmpty) {
      return "Keine Onboarding-Informationen verfügbar.";
    }
    return info.entries.map((e) {
      var value = e.value;
      if (value == null) {
        return "${e.key}: Keine Antwort";
      }
      if (value is Timestamp) {
        value = value.toDate().toIso8601String();
      }
      return "${e.key}: $value";
    }).join("\n");
  }

  Future<void> updateOnboardingInfo(String userId, Map<String, dynamic> newInfo) async {
    await initializeThread(userId);
    if (newInfo.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] ?? 'Unbekannt';
    final partnerUserId = userDoc.data()?['partnerId'];

    String formattedInfo = _formatOnboardingInfo(newInfo);
    String message = "Aktualisierte Benutzerinformationen für $userName:\n$formattedInfo";

    if (partnerUserId != null) {
      final partnerDoc = await FirebaseFirestore.instance.collection('users').doc(partnerUserId).get();
      final partnerName = partnerDoc.data()?['name'] ?? 'Unbekannt';
      message += "\n\nDiese Informationen beziehen sich auf $userName, den Partner von $partnerName.";
    }

    await logToFile("ONBOARDING UPDATE for $userName: $formattedInfo");
    await sendMessage(message, isForDisplay: false);
  }

  Future<void> shareUserInput(String userId, String input) async {
    await initializeThread(userId);
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] ?? 'Unbekannt';
    final message = "Input von Benutzer $userName:\n$input";
    await sendMessage(message, isForDisplay: false);
  }

  Future<void> shareFeedback(String userId, String feedback) async {
    await initializeThread(userId);
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userName = userDoc.data()?['name'] ?? 'Unbekannt';
    final message = "Feedback von Benutzer $userName:\n$feedback";
    await sendMessage(message, isForDisplay: false);
  }

  Future<bool> canStartLoveSession(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final partnerUserId = userDoc.data()?['partnerId'];
    if (partnerUserId == null) {
      return true; // User has no partner, can start session
    }
    
    final partnerDoc = await FirebaseFirestore.instance.collection('users').doc(partnerUserId).get();
    final partnerInSession = partnerDoc.data()?['inLoveSession'] ?? false;
    
    return !partnerInSession;
  }

  Future<void> setLoveSessionStatus(String userId, bool inSession) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'inLoveSession': inSession,
    });
  }
}
