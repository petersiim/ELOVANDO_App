import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:envied/envied.dart';
import 'env/env.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'dart:developer';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  openai.OpenAI.apiKey = Env.apiKey;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Demo Deescalate App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String therapistMessage = "Therapist: How are you?";
  final TextEditingController clientController = TextEditingController();


  // Add a list to store the conversation history
  List<openai.OpenAIChatCompletionChoiceMessageModel> conversationHistory = [
  openai.OpenAIChatCompletionChoiceMessageModel(
    content: [
      openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "Act as a virtual therapist with 40 years of experience and up to date with modern research",
      ),
    ],
    role: openai.OpenAIChatMessageRole.system,
  ),
  openai.OpenAIChatCompletionChoiceMessageModel(
    content: [
      openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "Who are you?",
      ),
    ],
    role: openai.OpenAIChatMessageRole.user,
  ),
  openai.OpenAIChatCompletionChoiceMessageModel(
    content: [
      openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(
        "I'm a virtual therapist, designed to help you :).",
      ),
    ],
    role: openai.OpenAIChatMessageRole.assistant,
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
            Expanded(  // Add this
              child: Scrollbar(
                child: Container(
                  // height: MediaQuery.of(context).size.height / 2,  // Remove this
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),  // Add a border
                    color: Colors.white,  // Add a background color
                  ),
                  padding: EdgeInsets.all(8.0),  // Add padding
                  child: SingleChildScrollView(
                    child: Text(therapistMessage),  // Replace this with your widget that displays the therapist's message
                  ),
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
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String clientMessage = clientController.text;
                setState(() {
                  therapistMessage = "Therapist: ...";
                });
                therapistMessage = await sendMessage(clientMessage);
                setState(() {});
              },
              child: Text('Send'),
            ),
          ],
        ),
      ),
    );
  }


  Future<String> sendMessage(String message) async {
    // Add the user's message to the conversation history
    conversationHistory.add(openai.OpenAIChatCompletionChoiceMessageModel(
      content: [openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(message)],
      role: openai.OpenAIChatMessageRole.user,
    ));

    // Generate the therapist's response
    openai.OpenAIChatCompletionModel chatCompletion = await openai.OpenAI.instance.chat.create(
      model: "gpt-4",
      responseFormat: {"type": "text"},
      seed: 6,
      messages: conversationHistory,
      temperature: 0.2,
      maxTokens: 500,
    );

    // Extract the therapist's message and add it to the conversation history
    String responseText = chatCompletion.choices.first.message.content?.first.text ?? 'No response received';
    conversationHistory.add(openai.OpenAIChatCompletionChoiceMessageModel(
      content: [openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(responseText)],
      role: openai.OpenAIChatMessageRole.assistant,
    ));

    return 'Therapist: $responseText';
  }
}