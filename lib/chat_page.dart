import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'dart:async';
import 'package:record/record.dart';
import 'dart:io' as io;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import 'session_manager.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.title, required this.hasMicrophonePermission})
      : super(key: key);

  final String title;
  final bool hasMicrophonePermission;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<String> messages = ["Descalate: How are you?"];
  final TextEditingController clientController = TextEditingController();

  bool _isTranscribing = false;
  bool _isSpeechEnabled = false;
  late Timer _loadingTimer;
  String _loadingText = "";
  late Record _recorder;
  bool _isRecording = false;

  final _storage = FirebaseStorage.instance;

  final SessionManager _sessionManager = SessionManager();
  final String _sessionId = "1234";  // This can be dynamically generated for multiple users

  @override
  void initState() {
    super.initState();
    _recorder = Record();
    _initializeSession();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _loadingTimer.cancel();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    await _sessionManager.initializeSession(_sessionId);
  }

  Future<void> stopRecording() async {
    try {
      await _recorder.stop();

      setState(() {
        _isRecording = false;
      });

      // Save the recording locally
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/rec.mp3';

      print('Recording saved at: $path');

      // Transcribe the audio
      setState(() {
        _isTranscribing = true;
      });

      String transcription = await transcribeAudio(path);
      print('Transcription: $transcription');

      // End transcribing the audio
      setState(() {
        _isTranscribing = false;
        clientController.text = transcription;
      });

      // Play the recording
      AudioPlayer audioPlayer = AudioPlayer();
      await audioPlayer.setSource(DeviceFileSource(path));
      await audioPlayer.resume();
    } catch (e) {
      print('Error stopping the recording: $e');
    }
  }

  Future<String> transcribeAudio(String filePath) async {
    openai.OpenAIAudioModel transcription = await openai.OpenAI.instance.audio.createTranscription(
      file: io.File(filePath),
      model: "whisper-1",
      responseFormat: openai.OpenAIAudioResponseFormat.json,
    );

    return transcription.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          Text("TTS?"),
          Switch(
            value: _isSpeechEnabled,
            onChanged: (value) {
              setState(() {
                _isSpeechEnabled = value;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: messages[index].startsWith('You: ')
                            ? Colors.grey[200]
                            : Colors.white,
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text(messages[index]),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      TextField(
                        controller: clientController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: _isTranscribing ? '' : 'Your response',
                        ),
                        onSubmitted: (text) async {
                          messages.add('You: $text');
                          await sendMessageAndDisplay(text);
                        },
                      ),
                      if (_isTranscribing)
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 10,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                if (widget.hasMicrophonePermission)
                  FloatingActionButton(
                    onPressed: () async {
                      if (!_isRecording) {
                        final dir = await getApplicationDocumentsDirectory();
                        final path = '${dir.path}/rec.mp3';
                        await _recorder.start(path: path);
                        setState(() {
                          _isRecording = true;
                        });
                      } else {
                        await stopRecording();
                      }
                    },
                    child: Icon(_isRecording ? Icons.stop : Icons.mic),
                  ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                messages.add('You: ${clientController.text}');
                await sendMessageAndDisplay(clientController.text);
              },
              child: Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sendMessageAndDisplay(String message) async {
    clientController.clear();
    setState(() {
      messages.add('Descalate: ...'); // Add a loading message
    });

    _startLoadingIndicator();

    _sessionManager.addUserMessage(_sessionId, message);
    String response = await sendMessage(message);

    _stopLoadingIndicator();

    setState(() {
      messages.removeLast(); // Remove the loading message
      messages.add('Descalate: $response'); // Add the actual response
    });

    if (_isSpeechEnabled) {
      // Generate speech from the response text
      io.File speech = await openai.OpenAI.instance.audio.createSpeech(
        model: "tts-1",
        input: response,
        voice: "nova",
        responseFormat: openai.OpenAIAudioSpeechResponseFormat.mp3,
        outputDirectory: await getApplicationDocumentsDirectory(),
        outputFileName: "response",
      );

      // Play the speech
      AudioPlayer audioPlayer = AudioPlayer();
      await audioPlayer.setSource(DeviceFileSource(speech.path));
      await audioPlayer.resume();
    }
  }

  void _startLoadingIndicator() {
    _loadingText = "";
    _loadingTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        if (_loadingText.length == 3) {
          _loadingText = "";
        } else {
          _loadingText += ".";
        }
        messages[messages.length - 1] = 'Descalate: $_loadingText';
      });
    });
  }

  void _stopLoadingIndicator() {
    _loadingTimer.cancel();
  }

  Future<String> sendMessage(String message) async {
    List<openai.OpenAIChatCompletionChoiceMessageModel> sessionHistory = _sessionManager.getSessionHistory(_sessionId);
    print('Session History: $sessionHistory');
    
    if (sessionHistory.isEmpty) {
      print('Session history is empty, initializing session again.');
      await _initializeSession();
      sessionHistory = _sessionManager.getSessionHistory(_sessionId);
      print('Session History after initialization: $sessionHistory');
    }

    String modelInUse = "gpt-4-turbo";
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

    String responseText = chatCompletion.choices.first.message.content?.first.text ?? 'No response received';
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
