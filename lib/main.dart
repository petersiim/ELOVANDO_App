import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:envied/envied.dart';
import 'env/env.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'dart:developer';
import 'package:flutter/services.dart';
import 'splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'anmelden_page.dart';
import 'registration_page.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

late Logger logger;

Future<void> initLogger() async {
  final directory = await getApplicationDocumentsDirectory();
  final logFile = File('${directory.path}/app_logs.txt');
  logger = Logger(
    printer: PrettyPrinter(),
    output: FileOutput(file: logFile),
  );
}

Future<String> readFile(String path) async {
  String text = await rootBundle.loadString(path);
  return text;
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    await initLogger();
    logger.i('Starting app initialization');
    
    // Load .env file
    await dotenv.load(fileName: ".env");
    logger.i('.env file loaded');
    
    // Ensure the API key is loaded
    String? apiKey = dotenv.env['OPEN_AI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      logger.e('OPEN_AI_API_KEY not found in .env file');
      throw Exception('OPEN_AI_API_KEY not found in .env file');
    }
    
    openai.OpenAI.apiKey = apiKey;
    openai.OpenAI.organization = "org-fZRna2F4kfSff4YTG4Lx15mM";
    logger.i('OpenAI API key and organization set');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i('Firebase initialized');

    // Initialize Firebase Crashlytics
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    logger.i('Firebase Crashlytics initialized');

    // Pass all uncaught errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        logger.i('User is currently signed out!');
      } else {
        logger.i('User is signed in!');
      }
    });

    logger.i('App initialization completed successfully');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    logger.e('Error during initialization: $e\nStack trace: $stackTrace');
    // Report error to Crashlytics
    await FirebaseCrashlytics.instance.recordError(e, stackTrace);
    // You might want to show an error dialog or screen here
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELOVANDO - The Love App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
      routes: {
        '/login': (context) => AnmeldenPage(),
        '/register': (context) => RegistrationPage(),
      },
    );
  }
}