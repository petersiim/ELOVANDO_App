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

import 'registration_page.dart';

Future<void> initializeSqflite() async {
  try {
    // This will trigger sqflite initialization
    final databasesPath = await getDatabasesPath();
    print('Sqflite initialized successfully. Path: $databasesPath');
  } catch (e) {
    print('Error initializing Sqflite: $e');
    // Handle the error as needed
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
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    print('Error initializing JustAudioBackground: $e');
    // Continue with app initialization even if JustAudioBackground fails
  }

  await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );
  await initializeSqflite();

  // Load .env file
  await dotenv.load(fileName: ".env");

  openai.OpenAI.apiKey = Env.apiKey;
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
      print('Error processing invitation code: $e');
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
