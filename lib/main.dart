import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'env/env.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'package:flutter/services.dart';
import 'dart:async';
import 'splash_screen.dart';
import 'package:uni_links/uni_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'anmelden_page.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:io';

import 'registration_page.dart';

String errorLog = '';

void addToErrorLog(String message) {
  errorLog += '$message\n';
  print(message); // Also print to console for debugging
}

Future<void> initializeSqflite() async {
  try {
    final databasesPath = await getDatabasesPath();
    addToErrorLog('Sqflite initialized successfully. Path: $databasesPath');
  } catch (e) {
    addToErrorLog('Error initializing Sqflite: $e');
  }
}

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}

Future<void> initializeApp() async {
  addToErrorLog('Initializing app...');

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
    addToErrorLog('JustAudioBackground initialized');
  } catch (e) {
    addToErrorLog('Error initializing JustAudioBackground: $e');
  }

  try {
    await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      ),
    );
    addToErrorLog('AudioService initialized');
  } catch (e) {
    addToErrorLog('Error initializing AudioService: $e');
  }

  try {
    await initializeSqflite();
  } catch (e) {
    addToErrorLog('Error in initializeSqflite: $e');
  }

  try {
    final envFile = File('.env');
    if (await envFile.exists()) {
      addToErrorLog('.env file exists');
      await dotenv.load(fileName: ".env");
      addToErrorLog('.env file loaded');
    } else {
      addToErrorLog('.env file does not exist');
    }
  } catch (e) {
    addToErrorLog('Error loading .env file: $e');
  }

  try {
    openai.OpenAI.apiKey = Env.apiKey;
    openai.OpenAI.organization = "org-fZRna2F4kfSff4YTG4Lx15mM";
    addToErrorLog('OpenAI configuration set');
  } catch (e) {
    addToErrorLog('Error setting OpenAI configuration: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    addToErrorLog('Firebase initialized');
  } catch (e) {
    addToErrorLog('Error initializing Firebase: $e');
  }

  addToErrorLog('App initialization completed');
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    addToErrorLog('WidgetsFlutterBinding initialized');

    await initializeApp();

    runApp(const MyApp());
    addToErrorLog('App started');
  }, (error, stackTrace) {
    addToErrorLog('Unhandled error: $error');
    addToErrorLog('Stack trace: $stackTrace');
  });

  // Set error handler for Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    addToErrorLog('Flutter error: ${details.exception}');
    addToErrorLog('Stack trace: ${details.stack}');
  };
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
      addToErrorLog('Failed to get initial uri');
    }
  }

  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      addToErrorLog('Error handling incoming links: $err');
    });
  }

  void _handleDeepLink(Uri uri) async {
    if (uri.path == '/invite' && uri.queryParameters.containsKey('code')) {
      String invitationCode = uri.queryParameters['code']!;

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _processInvitationCode(currentUser, invitationCode);
      } else {
        await _storeInvitationCode(invitationCode);
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

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'invitedBy': inviterId});

        await FirebaseFirestore.instance
            .collection('users')
            .doc(inviterId)
            .update({
          'invitedUsers': FieldValue.arrayUnion([user.uid]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully connected with your partner!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid invitation code. Please try again.')),
        );
      }
    } catch (e) {
      addToErrorLog('Error processing invitation code: $e');
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
      home: errorLog.isEmpty ? SplashScreen() : ErrorScreen(errorLog: errorLog),
      routes: {
        '/login': (context) => AnmeldenPage(),
        '/register': (context) => RegistrationPage(),
      },
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String errorLog;

  const ErrorScreen({Key? key, required this.errorLog}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Error Log'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(errorLog),
      ),
    );
  }
}
