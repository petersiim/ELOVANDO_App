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
            Text(therapistMessage),
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
    final systemMessage = openai.OpenAIChatCompletionChoiceMessageModel(
      content: [
        openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "Be a therapist with 40 years of expirience and up to date with modern research",
        ),
      ],
      role: openai.OpenAIChatMessageRole.assistant,
    );

    final userMessage = openai.OpenAIChatCompletionChoiceMessageModel(
      content: [
        openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(message),
      ],
      role: openai.OpenAIChatMessageRole.user,
    );

    final requestMessages = [
      systemMessage,
      userMessage,
    ];

    openai.OpenAIChatCompletionModel chatCompletion = await openai.OpenAI.instance.chat.create(
      model: "gpt-4",
      responseFormat: {"type": "text"},
      seed: 6,
      messages: requestMessages,
      temperature: 0.2,
      maxTokens: 100,
    );
    String responseText = chatCompletion.choices.first.message.content?.first.text ?? 'No response received';

    print(responseText);
    return 'Therapist: ${responseText}';
  }
}