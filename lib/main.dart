import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:envied/envied.dart';
import 'env/env.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'dart:developer';
import 'package:flutter/services.dart';
import 'dart:async';
import 'splash_screen.dart';
import 'package:uni_links/uni_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'anmelden_page.dart';
import 'registration_page.dart';

Future<String> readFile(String path) async {
  String text = await rootBundle.loadString(path);
  return text;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load(fileName: ".env");
  
  // Ensure the API key is loaded
  String? apiKey = dotenv.env['OPEN_AI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('OPEN_AI_API_KEY not found in .env file');
  }
  
  openai.OpenAI.apiKey = apiKey;
  openai.OpenAI.organization = "org-fZRna2F4kfSff4YTG4Lx15mM";

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
    _handleInitialUri();
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } on PlatformException {
      print('Failed to get initial uri');
    }
  }

  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      print('Error handling incoming links: $err');
    });
  }

  void _handleDeepLink(Uri uri) async {
    if (uri.path == '/invite' && uri.queryParameters.containsKey('code')) {
      String invitationCode = uri.queryParameters['code']!;
      
      // Check if the user is already logged in
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // User is logged in, process the invitation code
        await _processInvitationCode(currentUser, invitationCode);
      } else {
        // User is not logged in, store the invitation code
        await _storeInvitationCode(invitationCode);
        // Navigate to login or registration page
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _storeInvitationCode(String invitationCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_invitation_code', invitationCode);
  }

  Future<void> _processInvitationCode(User user, String invitationCode) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('invitationCode', isEqualTo: invitationCode)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        String inviterId = query.docs.first.id;
        
        // Link the current user to the inviter
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'invitedBy': inviterId,
        });

        // Update the inviter's document
        await FirebaseFirestore.instance.collection('users').doc(inviterId).update({
          'invitedUsers': FieldValue.arrayUnion([user.uid]),
        });

        print('User successfully linked with inviter');
        // Show success message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully connected with your partner!')),
        );
      } else {
        print('Invalid invitation code');
        // Show error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid invitation code. Please try again.')),
        );
      }
    } catch (e) {
      print('Error processing invitation code: $e');
      // Show error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

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