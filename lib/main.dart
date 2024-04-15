import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:envied/envied.dart';
import 'env/env.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'dart:developer';
import 'package:flutter/services.dart';

//READ the context stored in file 
Future<String> readFile() async {
  String text = await rootBundle.loadString('assets/ContextForModel.txt');
  return text;
}

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
      title: 'Deescalate App',
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
    String modelInUse = "gpt-4-turbo";
    openai.OpenAIChatCompletionModel chatCompletion = await openai.OpenAI.instance.chat.create(
      model: modelInUse,
      responseFormat: {"type": "text"},
      messages: conversationHistory,
      temperature: 0.3,
      maxTokens: 500,
    );

    // Extract the therapist's message and add it to the conversation history
    String responseText = chatCompletion.choices.first.message.content?.first.text ?? 'No response received';
    conversationHistory.add(openai.OpenAIChatCompletionChoiceMessageModel(
      content: [openai.OpenAIChatCompletionChoiceMessageContentItemModel.text(responseText)],
      role: openai.OpenAIChatMessageRole.assistant,
    ));

    for (var message in conversationHistory) {
      print('Role: ${message.role}, Message: ${message.content?.first.text}');
  }
    print('Model used: $modelInUse');
    return 'Therapist: $responseText';
  }
}