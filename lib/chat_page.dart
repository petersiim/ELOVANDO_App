import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'dart:async';
import 'main.dart';
import 'package:record/record.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.title, required this.hasMicrophonePermission}) : super(key: key);

  final String title;
  final bool hasMicrophonePermission;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<String> messages = ["Descalate: How are you?"];
  final TextEditingController clientController = TextEditingController();

  late Record _recorder;
  bool _isRecording = false;

  final _storage = FirebaseStorage.instance;

  String contextForModelTxt = '';
  List<openai.OpenAIChatCompletionChoiceMessageModel> conversationHistory = [];

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

  Future<void> toggleRecording() async {
    if (!_isRecording) {
      bool isPermissionGranted = await _recorder.hasPermission();
      if (!isPermissionGranted) {
        // Handle permission denial
        print('Microphone permission not granted');
        return;
      }

      await _recorder.start();
      setState(() {
        _isRecording = true;
      });
    } else {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        Uri blobUri = Uri.parse(path);
        http.Response response = await http.get(blobUri);
        await _storage.ref('recordings/${DateTime.now().toIso8601String()}.mp3').putData(response.bodyBytes, SettableMetadata(contentType: 'audio/mp3'));
      }
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
                        color: messages[index].startsWith('You: ') ? Colors.grey[200] : Colors.white,
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
                  child: TextField(
                    controller: clientController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Your response',
                    ),
                    onSubmitted: (text) async {
                      messages.add('You: $text');
                      await sendMessageAndDisplay(text);
                    },
                  ),
                ),
                SizedBox(width: 10), // Add some space between the TextField and the FloatingActionButton
                if (widget.hasMicrophonePermission)
                  FloatingActionButton(
                    onPressed: toggleRecording,
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
    int counter = 0;
    Timer timer = Timer.periodic(Duration(milliseconds: 500), (Timer t) {
      setState(() {
        if (messages.length > 0 && messages.last.startsWith('Descalate: ')) {
          messages.removeLast();
        }
        messages.add('Descalate: ' + '.' * (counter % 4));
        counter++;
      });
    });
    String response = await sendMessage(message);
    timer.cancel();
    setState(() {
      messages.removeLast();
      messages.add('$response');
    });
  }

  Future<String> sendMessage(String message) async {
    conversationHistory.add(openai.OpenAIChatCompletionChoiceMessageModel(
      content: [openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(message)],
      role: openai.OpenAIChatMessageRole.user,
    ));

    String modelInUse = "gpt-4-turbo";
    openai.OpenAIChatCompletionModel chatCompletion = await openai.OpenAI.instance.chat.create(
      model: modelInUse,
      responseFormat: {"type": "text"},
      messages: conversationHistory,
      temperature: 0.3,
      maxTokens: 700,
    );

    String responseText = chatCompletion.choices.first.message.content?.first.text ?? 'No response received';
    conversationHistory.add(openai.OpenAIChatCompletionChoiceMessageModel(
      content: [openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(responseText)],
      role: openai.OpenAIChatMessageRole.assistant,
    ));

    return 'Descalate: $responseText';
  }
}
