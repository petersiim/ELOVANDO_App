// ai_chat_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIChatService {
  final String apiKey;
  final String organizationId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String assistantId = 'asst_NGkGIycW4Fu0P7FsygARNzkH'; // Your assistant ID

  AIChatService(this.apiKey, this.organizationId);

  Future<String> createThread() async {
    print("DEBUG: Creating new thread");
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/threads'),
        headers: _getHeaders(),
      );

      print("DEBUG: Thread creation response status: ${response.statusCode}");
      print("DEBUG: Thread creation response body: ${response.body}");

      if (response.statusCode == 200) {
        final threadId = jsonDecode(response.body)['id'] as String?;
        if (threadId == null) {
          throw Exception('Failed to create thread: Thread ID is null');
        }
        print("DEBUG: Thread created successfully with ID: $threadId");
        return threadId;
      } else {
        throw Exception('Failed to create thread: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("ERROR: Exception in createThread: $e");
      rethrow;
    }
  }

  Future<void> addMessageToThread(String threadId, String content) async {
    print("DEBUG: Adding message to thread $threadId");
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/threads/$threadId/messages'),
        headers: _getHeaders(),
        body: jsonEncode({
          'role': 'user',
          'content': content,
        }),
      );

      print("DEBUG: Add message response status: ${response.statusCode}");
      print("DEBUG: Add message response body: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception('Failed to add message: ${response.statusCode} - ${response.body}');
      }
      print("DEBUG: Message added successfully to thread $threadId");
    } catch (e) {
      print("ERROR: Exception in addMessageToThread: $e");
      rethrow;
    }
  }

  Future<String> runAssistant(String threadId, String userId) async {
    print("DEBUG: Running assistant for thread $threadId and user $userId");
    try {
      var userDoc = await _firestore.collection('users').doc(userId).get();
      var messagesRemaining = userDoc.data()?['messagesRemaining'] as int? ?? 0;
      var nextResetTime = userDoc.data()?['nextResetTime'] as Timestamp?;

      print("DEBUG: Messages remaining: $messagesRemaining, Next reset time: $nextResetTime");

      if (nextResetTime != null && DateTime.now().isAfter(nextResetTime.toDate())) {
        print("DEBUG: Resetting message count and update time");
        await _firestore.collection('users').doc(userId).update({
          'messagesRemaining': 6,
          'nextResetTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 24))),
        });
        messagesRemaining = 6;
      }

      if (messagesRemaining <= 0) {
        throw Exception('Message limit reached. Please wait until ${nextResetTime?.toDate()} before sending more messages.');
      }

      print("DEBUG: Creating run for thread $threadId");
      final runResponse = await http.post(
        Uri.parse('https://api.openai.com/v1/threads/$threadId/runs'),
        headers: _getHeaders(),
        body: jsonEncode({
          'assistant_id': assistantId,
        }),
      );

      print("DEBUG: Run creation response status: ${runResponse.statusCode}");
      print("DEBUG: Run creation response body: ${runResponse.body}");

      if (runResponse.statusCode != 200) {
        throw Exception('Failed to create run: ${runResponse.statusCode} - ${runResponse.body}');
      }

      final runData = jsonDecode(runResponse.body);
      final runId = runData['id'] as String?;
      if (runId == null) {
        throw Exception('Failed to create run: Run ID is null. Response: ${runResponse.body}');
      }

      print("DEBUG: Run created with ID: $runId");

      String status = 'in_progress';
      int attempts = 0;
      while (status != 'completed' && attempts < 30) {
        await Future.delayed(Duration(seconds: 1));
        print("DEBUG: Checking run status (Attempt ${attempts + 1})");
        final statusResponse = await http.get(
          Uri.parse('https://api.openai.com/v1/threads/$threadId/runs/$runId'),
          headers: _getHeaders(),
        );
        final statusData = jsonDecode(statusResponse.body);
        status = statusData['status'] as String? ?? '';
        print("DEBUG: Current run status: $status");
        if (status == 'failed') {
          throw Exception('Run failed: ${statusData['error']}');
        }
        attempts++;
      }

      if (status != 'completed') {
        throw Exception('Run timed out after 30 attempts');
      }

      print("DEBUG: Run completed, retrieving messages");
      final messagesResponse = await http.get(
        Uri.parse('https://api.openai.com/v1/threads/$threadId/messages'),
        headers: _getHeaders(),
      );

      print("DEBUG: Messages response status: ${messagesResponse.statusCode}");
      print("DEBUG: Messages response body: ${messagesResponse.body}");

      final messages = jsonDecode(messagesResponse.body)['data'] as List<dynamic>?;
      if (messages == null || messages.isEmpty) {
        throw Exception('No messages found in the thread');
      }
      final aiResponse = messages[0]['content'][0]['text']['value'] as String? ?? 'No response';

      print("DEBUG: AI response: $aiResponse");

      await _firestore.collection('users').doc(userId).update({
        'messagesRemaining': FieldValue.increment(-1),
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      print("DEBUG: User document updated, returning AI response");
      return aiResponse;
    } catch (e) {
      print("ERROR: Exception in runAssistant: $e");
      rethrow;
    }
  }

  Future<int> getRemainingMessages(String userId) async {
    print("DEBUG: Getting remaining messages for user $userId");
    try {
      var userDoc = await _firestore.collection('users').doc(userId).get();
      var messagesRemaining = userDoc.data()?['messagesRemaining'] as int? ?? 0;
      var nextResetTime = userDoc.data()?['nextResetTime'] as Timestamp?;

      print("DEBUG: Current messages remaining: $messagesRemaining, Next reset time: $nextResetTime");

      if (messagesRemaining == 0 || nextResetTime == null) {
        print("DEBUG: Resetting message count and update time (case 1)");
        await _firestore.collection('users').doc(userId).update({
          'messagesRemaining': 6,
          'nextResetTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 24))),
        });
        return 6;
      }

      if (DateTime.now().isAfter(nextResetTime.toDate())) {
        print("DEBUG: Resetting message count and update time (case 2)");
        await _firestore.collection('users').doc(userId).update({
          'messagesRemaining': 6,
          'nextResetTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 24))),
        });
        return 6;
      }

      print("DEBUG: Returning current messages remaining: $messagesRemaining");
      return messagesRemaining;
    } catch (e) {
      print("ERROR: Exception in getRemainingMessages: $e");
      rethrow;
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
}