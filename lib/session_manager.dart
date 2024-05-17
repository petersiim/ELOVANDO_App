import 'package:dart_openai/dart_openai.dart' as openai;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class SessionManager {
  static const int _maxContextLength =100; // Limit to the last 10 messages
  Map<String, List<openai.OpenAIChatCompletionChoiceMessageModel>> _sessions = {};

  Future<void> initializeSession(String sessionId, String contextFilePath) async {
    if (!_sessions.containsKey(sessionId)) {
      String contextForModelTxt = await _readFile(contextFilePath);
      _sessions[sessionId] = [
        openai.OpenAIChatCompletionChoiceMessageModel(
          content: [
            openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(
              contextForModelTxt,
            ),
          ],
          role: openai.OpenAIChatMessageRole.system,
        ),
        openai.OpenAIChatCompletionChoiceMessageModel(
          content: [
            openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(
              'How are you?',
            ),
          ],
          role: openai.OpenAIChatMessageRole.assistant,
        ),
      ];
    }
  }

  List<openai.OpenAIChatCompletionChoiceMessageModel> getSessionHistory(String sessionId) {
    return _sessions[sessionId] ?? [];
  }

  void addUserMessage(String sessionId, String message) {
    _addMessage(sessionId, message, openai.OpenAIChatMessageRole.user);
  }

  void addAssistantMessage(String sessionId, String message) {
    _addMessage(sessionId, message, openai.OpenAIChatMessageRole.assistant);
  }

  void _addMessage(String sessionId, String message, openai.OpenAIChatMessageRole role) {
    if (_sessions.containsKey(sessionId)) {
      _sessions[sessionId]?.add(openai.OpenAIChatCompletionChoiceMessageModel(
        content: [openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(message)],
        role: role,
      ));

      // Limit the context length
      if (_sessions[sessionId]!.length > _maxContextLength) {
        _sessions[sessionId] = _sessions[sessionId]!.sublist(
            _sessions[sessionId]!.length - _maxContextLength);
      }
    }
  }

  Future<String> _readFile(String filePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final fullPath = p.join(directory.path, filePath); // Use the new prefix
    final file = File(fullPath);
    return await file.readAsString();
  }
}
