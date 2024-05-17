import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'session_manager.dart';
import 'package:path/path.dart' as p;


class LoveSessionPage extends StatefulWidget {
  const LoveSessionPage({Key? key}) : super(key: key);

  @override
  _LoveSessionPageState createState() => _LoveSessionPageState();
}

class _LoveSessionPageState extends State<LoveSessionPage> {
  final TextEditingController controllerA = TextEditingController();
  final TextEditingController controllerB = TextEditingController();
  final TextEditingController feedbackControllerA = TextEditingController();
  final TextEditingController feedbackControllerB = TextEditingController();
  late Record _recorder;
  bool _isRecording = false;
  String _activeRecorder = '';
  bool _isTranscribing = false;
  String _loadingText = '';
  late Timer _loadingTimer;

  final SessionManager _sessionManager = SessionManager();
  final String _sessionId =
      "loveSession"; // Use a single session ID for the whole love session

  @override
  void initState() {
    super.initState();
    _recorder = Record();
    initializeSession();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _loadingTimer.cancel();
    super.dispose();
  }

  Future<void> initializeSession() async {
    await _sessionManager.initializeSession(
        _sessionId, 'assets/ContextForLoveSessionModel.txt');
  }

  Future<void> startStopRecording(String person) async {
    if (!_isRecording) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${person}_rec.mp3';
      await _recorder.start(path: path);
      setState(() {
        _isRecording = true;
        _activeRecorder = person;
      });
    } else {
      String? filePath = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _activeRecorder = '';
      });

      // Transcribe audio
      String transcription = await transcribeAudio(filePath ?? '');
      print(transcription);
      if (person == 'Person A') {
        controllerA.text = transcription;
      } else if (person == 'Person B') {
        controllerB.text = transcription;
      } else if (person == 'Feedback A') {
        feedbackControllerA.text = transcription;
      } else if (person == 'Feedback B') {
        feedbackControllerB.text = transcription;
      }
    }
  }

  Future<String> transcribeAudio(String filePath) async {
    openai.OpenAIAudioModel transcription =
        await openai.OpenAI.instance.audio.createTranscription(
      file: io.File(filePath),
      model: "whisper-1",
      responseFormat: openai.OpenAIAudioResponseFormat.json,
    );

    return transcription.text;
  }

  Widget buildTextInput(
      String label, TextEditingController controller, String person) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: label,
          ),
        ),
        IconButton(
          icon: Icon(_isRecording && _activeRecorder == person
              ? Icons.stop
              : Icons.mic),
          onPressed: () => startStopRecording(person),
        ),
        ElevatedButton(
          onPressed: () async {
            print('$label: ${controller.text}');
            String response = await sendMessage(controller.text);
            print('Response: $response');
          },
          child: const Text('Send'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Love Session Page'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buildTextInput('Input (Person A)', controllerA, 'Person A'),
              buildTextInput('Input (Person B)', controllerB, 'Person B'),
              const SizedBox(height: 20),
              // Add the new button here
              ElevatedButton(
                onPressed: () {
                  // Logic to handle start love session
                },
                child: const Text('Start Love Session'),
              ),
              const SizedBox(height: 20),
              buildTextInput(
                  'Feedback (Person A)', feedbackControllerA, 'Feedback A'),
              buildTextInput(
                  'Feedback (Person B)', feedbackControllerB, 'Feedback B'),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> sendMessage(String message) async {
    _sessionManager.addUserMessage(_sessionId, message);
    List<openai.OpenAIChatCompletionChoiceMessageModel> sessionHistory =
        _sessionManager.getSessionHistory(_sessionId);

    print('Session History: $sessionHistory');

    if (sessionHistory.isEmpty) {
      print('Session history is empty, initializing session again.');
      await _sessionManager.initializeSession(
          _sessionId, 'assets/ContextForLoveSessionModel.txt');
      sessionHistory = _sessionManager.getSessionHistory(_sessionId);
      print('Session History after initialization: $sessionHistory');
    }

    String modelInUse = "gpt-4o";
    openai.OpenAIChatCompletionModel chatCompletion;

    try {
      chatCompletion = await openai.OpenAI.instance.chat.create(
        model: modelInUse,
        responseFormat: {"type": "text"},
        messages: sessionHistory,
        temperature: 0.3,
        maxTokens: 400,
      );
    } catch (error) {
      print('Error creating chat completion: $error');
      return 'Error: $error';
    }

    String responseText =
        chatCompletion.choices.first.message.content?.first.text ??
            'No response received';
    print('Response: $responseText');
    _sessionManager.addAssistantMessage(_sessionId, responseText);

    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, 'history_chat.txt');
    final file = io.File(filePath);

    try {
      await file.writeAsString(sessionHistory.toString());
    } catch (error) {
      print('Error writing session history to file: $error');
    }

    return responseText;
  }
}
