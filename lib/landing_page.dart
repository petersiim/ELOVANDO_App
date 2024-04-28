import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chat_page.dart'; // Import the ChatPage widget
import 'love_session_page.dart';
import 'package:flutter/foundation.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool hasMicrophonePermission = false;

  Future<bool> _requestMicrophonePermission() async {
  PermissionStatus status = await Permission.microphone.request();
  if (!status.isGranted) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Microphone Permission Denied'),
          content: const Text('Some functionalities are not available without microphone access.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  return status.isGranted;
}

 @override
void initState() {
  super.initState();
  if (!kIsWeb) {
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      hasMicrophonePermission = await _requestMicrophonePermission();
      setState(() {});
    });
  }
}

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landing Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to the landing page!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatPage(title: 'Chat Page', hasMicrophonePermission: hasMicrophonePermission)),
                );
              },
              child: const Text('Go to Chat Page'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoveSessionPage()),
                );
              },
              child: const Text('Go to Love Session'),
            ),
          ],
        ),
      ),
    );
  }
}