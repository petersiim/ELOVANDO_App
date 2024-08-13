// ai_chat_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIChatService {
  final String apiKey;
  final String organizationId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AIChatService(this.apiKey, this.organizationId);

  Future<String> createThread(String userId) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/threads'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final threadId = jsonDecode(response.body)['id'];
      await _firestore.collection('users').doc(userId).update({
        'threadId': threadId,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'messageCount': 0,
      });
      return threadId;
    } else {
      throw Exception('Failed to create thread');
    }
  }

  Future<String> sendMessage(String userId, String threadId, String message) async {
    var userDoc = await _firestore.collection('users').doc(userId).get();
    var messageCount = userDoc.data()!['messageCount'] as int;
    var lastMessageTimestamp = userDoc.data()!['lastMessageTimestamp'] as Timestamp;

    if (messageCount >= 6 && DateTime.now().difference(lastMessageTimestamp.toDate()).inHours < 24) {
      throw Exception('Message limit reached. Please wait before sending more messages.');
    }

    await _addMessage(threadId, message);
    
    final runResponse = await _createRun(threadId);
    final runId = jsonDecode(runResponse.body)['id'];

    String status = 'in_progress';
    while (status != 'completed') {
      await Future.delayed(Duration(seconds: 1));
      final statusResponse = await _checkRunStatus(threadId, runId);
      status = jsonDecode(statusResponse.body)['status'];
    }

    final messagesResponse = await _listMessages(threadId);
    final messages = jsonDecode(messagesResponse.body)['data'];
    final aiResponse = messages[0]['content'][0]['text']['value'];

    await _firestore.collection('users').doc(userId).update({
      'messageCount': FieldValue.increment(1),
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });

    return aiResponse;
  }

  Future<List<Map<String, dynamic>>> getThreadMessages(String threadId) async {
    final response = await _listMessages(threadId);
    final messages = jsonDecode(response.body)['data'];
    return messages.map<Map<String, dynamic>>((m) => {
      'content': m['content'][0]['text']['value'],
      'role': m['role'],
    }).toList();
  }

  Future<void> resetThread(String userId) async {
    var newThreadId = await createThread(userId);
    await _firestore.collection('users').doc(userId).update({
      'threadId': newThreadId,
      'messageCount': 0,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<http.Response> _addMessage(String threadId, String message) async {
    return await http.post(
      Uri.parse('https://api.openai.com/v1/threads/$threadId/messages'),
      headers: _getHeaders(),
      body: jsonEncode({
        'role': 'user',
        'content': message,
      }),
    );
  }

  Future<http.Response> _createRun(String threadId) async {
    return await http.post(
      Uri.parse('https://api.openai.com/v1/threads/$threadId/runs'),
      headers: _getHeaders(),
      body: jsonEncode({
        'assistant_id': 'asst_NGkGIycW4Fu0P7FsygARNzkH',
      }),
    );
  }

  Future<http.Response> _checkRunStatus(String threadId, String runId) async {
    return await http.get(
      Uri.parse('https://api.openai.com/v1/threads/$threadId/runs/$runId'),
      headers: _getHeaders(),
    );
  }

  Future<http.Response> _listMessages(String threadId) async {
    return await http.get(
      Uri.parse('https://api.openai.com/v1/threads/$threadId/messages'),
      headers: _getHeaders(),
    );
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