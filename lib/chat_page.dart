import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'dart:developer';
import 'package:flutter/services.dart';
import 'dart:async';
import 'main.dart';
import 'package:record/record.dart';
import 'dart:io' as io;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class ChatPage extends StatefulWidget {
  const ChatPage(
      {Key? key, required this.title, required this.hasMicrophonePermission})
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

  late Record _recorder;
  bool _isRecording = false;

  final _storage = FirebaseStorage.instance;

  String contextForModelTxt = '';
  List<openai.OpenAIChatCompletionChoiceMessageModel> conversationHistory = [];

  Future<String> transcribeAudio(String filePath) async {
    openai.OpenAIAudioModel transcription =
        await openai.OpenAI.instance.audio.createTranscription(
      file: io.File(filePath),
      model: "whisper-1",
      responseFormat: openai.OpenAIAudioResponseFormat.json,
    );

    return transcription.text;
  }

  @override
  void initState() {
    super.initState();
    _recorder = Record();
    initializeContextAndHistory();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
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
        _isTranscribing = true; // Set the flag to true
      });

      String transcription = await transcribeAudio(path);
      print('Transcription: $transcription');

      // End transcribing the audio
      setState(() {
        _isTranscribing = false; // Set the flag back to false
        clientController.text =
            transcription; // Set the transcribed text to the TextField
      });

      // Play the recording
      AudioPlayer audioPlayer = AudioPlayer();
      await audioPlayer.setSource(DeviceFileSource(path));
      await audioPlayer.resume();
    } catch (e) {
      print('Error stopping the recording: $e');
    }
  }

  Future<void> initializeContextAndHistory() async {
    contextForModelTxt = await readFile();
    conversationHistory = [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                          left:
                              10, // Adjust this value to move the CircularProgressIndicator horizontally
                          child: Center(
                            child: SizedBox(
                              width:
                                  20, // Adjust this value to change the width of the CircularProgressIndicator
                              height:
                                  20, // Adjust this value to change the height of the CircularProgressIndicator
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                    width:
                        10), // Add some space between the TextField and the FloatingActionButton
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
    String response = await sendMessage(message);
    setState(() {
      messages.removeLast(); // Remove the loading message
      messages.add(response); // Add the actual response
    });
  }

  Future<String> sendMessage(String message) async {
    conversationHistory.add(openai.OpenAIChatCompletionChoiceMessageModel(
      content: [
        openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(message)
      ],
      role: openai.OpenAIChatMessageRole.user,
    ));

    String modelInUse = "gpt-4-turbo";
    openai.OpenAIChatCompletionModel chatCompletion =
        await openai.OpenAI.instance.chat.create(
      model: modelInUse,
      responseFormat: {"type": "text"},
      messages: conversationHistory,
      temperature: 0.3,
      maxTokens: 700,
    );

    String responseText =
        chatCompletion.choices.first.message.content?.first.text ??
            'No response received';
    conversationHistory.add(openai.OpenAIChatCompletionChoiceMessageModel(
      content: [
        openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(
            responseText)
      ],
      role: openai.OpenAIChatMessageRole.assistant,
    ));

    return 'Descalate: $responseText';
  }
}
