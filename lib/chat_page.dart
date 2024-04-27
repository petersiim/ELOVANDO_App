import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'dart:developer';
import 'package:flutter/services.dart';
import 'dart:async';
import 'main.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<String> messages = ["Descalate: How are you?"];
  final TextEditingController clientController = TextEditingController();

  String contextForModelTxt = '';
  List<openai.OpenAIChatCompletionChoiceMessageModel> conversationHistory = [];

  @override
  void initState() {
    super.initState();
    initializeContextAndHistory();
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
            TextField(
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