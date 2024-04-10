import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:envied/envied.dart';
import 'env/env.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final Logger _logger_ = Logger('MyAppLogger');

void main() async {
  Logger.root.level = Level.ALL; // Set this level to control which log messages to show
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  var headers = {
    'Authorization': 'Bearer ${Env.apiKey}',
    'Content-Type': 'application/json',
  };
  var body = jsonEncode({
    'model': 'gpt-4',
    'messages': [
      {'role': 'system', 'content': 'You are a helpful assistant.'},
      {'role': 'user', 'content': 'Who won the world series in 2020?'},
    ],
  });

  var response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: headers,
    body: body,
  );

  var responseData = jsonDecode(response.body);
  if (responseData != null &&
    responseData['choices'] != null &&
    responseData['choices'].isNotEmpty &&
    responseData['choices'][0]['message'] != null &&
    responseData['choices'][0]['message']['content'] != null) {
  _logger_.info(responseData['choices'][0]['message']['content']);
  } else {
  _logger_.warning('Unexpected response format');
  _logger_.warning('Response data: $responseData');
  }   
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Demo Deescalate App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final TextEditingController _controller =
      TextEditingController(); // Controller for the TextField
  String _userInput = ""; // Variable to store the user's input
  String _response = ""; // Variable to store the response from the OpenAI API

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _updateUserInput() async {
    setState(() {
      _userInput = _controller
          .text; // Update _userInput with the text from the TextField
    });

    var headers = {
      'Authorization': 'Bearer ${Env.apiKey}',
      'Content-Type': 'application/json',
    };

    var body = jsonEncode({
      'model': 'gpt-3',
      'messages': [
        {'role': 'system', 'content': 'You are a helpful assistant.'},
        {'role': 'user', 'content': _userInput},
      ],
    });

    var response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: headers,
      body: body,
    );

    var responseData = jsonDecode(response.body);

    if (responseData != null &&
        responseData['choices'] != null &&
        responseData['choices'].isNotEmpty &&
        responseData['choices'][0]['message'] != null &&
        responseData['choices'][0]['message']['content'] != null) {
      setState(() {
        _response = responseData['choices'][0]['message']['content'];
      });
    } else {
      _logger_.log(Level.WARNING, 'Unexpected response format');    }
  }

  @overrider
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter your question',
              ),
            ),
            SizedBox(height: 16.0), // Add some spacing
            ElevatedButton(
              onPressed: _updateUserInput,
              child: Text('Rat'),
            ),
            SizedBox(height: 16.0), // Add some spacing
            if (_userInput
                .isNotEmpty) // Only display this Text widget if _userInput is not empty
              Text('Du sagtest: $_userInput'),
            if (_response
                .isNotEmpty) // Only display this Text widget if _response is not empty
              Text('Die Antwort ist: $_response'),
          ],
        ),
      ),
    );
  }
}
