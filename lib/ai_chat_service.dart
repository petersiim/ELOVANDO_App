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

  Future<String> createThread(String userId, String userInfo) async {
  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/threads'),
    headers: _getHeaders(),
  );

  if (response.statusCode == 200) {
    final threadId = jsonDecode(response.body)['id'];
    
    // Send user information as the first message in the thread
    await sendMessage(userId, threadId, "User Information:\n$userInfo");
    print(userInfo);
    return threadId;
  } else {
    throw Exception('Failed to create thread');
  }
}

  Future<String> sendMessage(String userId, String threadId, String message) async {
    var userDoc = await _firestore.collection('users').doc(userId).get();
    var messagesRemaining = userDoc.data()!['messagesRemaining'] as int;
    var nextResetTime = userDoc.data()!['nextResetTime'] as Timestamp;

    if (DateTime.now().isAfter(nextResetTime.toDate())) {
      // Reset the message count and update the next reset time
      await _firestore.collection('users').doc(userId).update({
        'messagesRemaining': 6,
        'nextResetTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 24))),
      });
      messagesRemaining = 6;
    }

    if (messagesRemaining <= 0) {
      throw Exception('Message limit reached. Please wait until ${nextResetTime.toDate()} before sending more messages.');
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
      'messagesRemaining': FieldValue.increment(-1),
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });

    // Decode and re-encode the response to handle potential encoding issues
    return utf8.decode(aiResponse.runes.toList()).replaceAll('**', '');
  }

  Future<List<Map<String, dynamic>>> getThreadMessages(String threadId) async {
    final response = await _listMessages(threadId);
    final messages = jsonDecode(response.body)['data'];
    return messages.map<Map<String, dynamic>>((m) => {
      'content': utf8.decode(utf8.encode(m['content'][0]['text']['value'])),
      'role': m['role'],
    }).toList();
  }

  Future<void> resetThread(String userId) async {
  DocumentSnapshot userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();

  Map<String, dynamic> userInfo = userDoc.data() as Map<String, dynamic>? ?? {};
  userInfo.remove('password');
  String userInfoString = userInfo.entries.map((e) => "${e.key}: ${e.value}").join("\n");

  var newThreadId = await createThread(userId, userInfoString);
  print("New thread created with ID: $newThreadId");
  print("Reset Thread - User Information:\n$userInfoString");

  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .update({
    'threadId': newThreadId,
    'messagesRemaining': 6,
    'nextResetTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 24))),
  });
}

  Future<int> getRemainingMessages(String userId) async {
    var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    var messagesRemaining = userDoc.data()?['messagesRemaining'] as int?;
    var nextResetTime = userDoc.data()?['nextResetTime'] as Timestamp?;

    if (messagesRemaining == null || nextResetTime == null) {
      // If the values are null, set default values
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'messagesRemaining': 6,
        'nextResetTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 24))),
      });
      return 6;
    }

    if (DateTime.now().isAfter(nextResetTime.toDate())) {
      // Reset the message count and update the next reset time
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'messagesRemaining': 6,
        'nextResetTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: 24))),
      });
      return 6;
    }

    return messagesRemaining;
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