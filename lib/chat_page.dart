import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_chat_service.dart';
import 'main.dart';
import 'speech_to_text_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:envied/envied.dart';
import 'env/env.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'dart:developer';
import 'package:flutter/services.dart';
import 'dart:async';
import 'splash_screen.dart'; // Import the SplashScreen widget

class ChatPage extends StatefulWidget {
  final String userId;

  const ChatPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _showIntroBox = true;
  String? _userProfileImageUrl;
  final SpeechToTextService _speechToTextService = SpeechToTextService();
  bool _isRecording = false;
  late AIChatService _aiChatService;
  String? _threadId;
  int _remainingMessages = 6;

  @override
  void initState() {
    super.initState();
    _fetchUserProfileImage();
    _initializeAIChatService();
  }

  Future<void> _initializeAIChatService() async {
    _aiChatService = AIChatService(Env.apiKey, "org-fZRna2F4kfSff4YTG4Lx15mM");
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    _threadId = userDoc.data()!['threadId'] as String?;
    if (_threadId == null) {
      _threadId = await _aiChatService.createThread(widget.userId);
    }
    _updateRemainingMessages();
  }

  Future<void> _fetchUserProfileImage() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    setState(() {
      _userProfileImageUrl = userDoc.data()?['profileImageUrl'];
    });
  }

  Future<void> _updateRemainingMessages() async {
    int remaining = await _aiChatService.getRemainingMessages(widget.userId);
    setState(() {
      _remainingMessages = remaining;
    });
  }

  Future<void> _loadMessages() async {
    if (_threadId != null) {
      var messages = await _aiChatService.getThreadMessages(_threadId!);
      setState(() {
        _messages.clear();
        _messages.addAll(messages.map((m) => ChatMessage(
              text: m['content'],
              isUser: m['role'] == 'user',
              userIcon: m['role'] == 'user'
                  ? (_userProfileImageUrl != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(_userProfileImageUrl!))
                      : CircleAvatar(child: Icon(Icons.person)))
                  : CircleAvatar(
                      child: Padding(
                        padding: EdgeInsets.all(3.0),
                        child: Image.asset('assets/graphics/logo_black.png'),
                      ),
                      backgroundColor: Color(0xFF414254),
                    ),
            )));
        _showIntroBox = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF414254)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Therapeuten-Chat',
          style: TextStyle(
            color: Color(0xFF414254),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF414254)),
            onPressed: _resetThread,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0.2),
          child: Divider(color: Color(0xFFDEDEDE), thickness: 1, height: 1),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Verbleibende Nachrichten: $_remainingMessages',
              style: TextStyle(
                color: Color(0xFF414254),
                fontSize: 14,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: _showIntroBox ? _buildIntroBox() : _buildChatList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildIntroBox() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 120),
            Container(
              padding: EdgeInsets.all(50),
              margin: EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/graphics/therapeuten_chat_icon.svg',
                    width: 60,
                    height: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Therapeuten-Chat',
                    style: TextStyle(
                      color: Color(0xFF414254),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hast du Fragen zu Liebe, Beziehung oder Sexualität? Unser kostenloser, anonymer Deescalate Therapeuten-Chat bietet dir jederzeit Unterstützung und hilfreiche Ratschläge.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF98999D),
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _messages[index];
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Nachricht eingeben...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onLongPressStart: (_) =>
                        _startRecording(_messageController),
                    onLongPressEnd: (_) => _stopRecording(_messageController),
                    child: IconButton(
                      icon: SvgPicture.asset(
                        'assets/graphics/voice_input_icon.svg',
                        color: _isRecording ? Colors.red : null,
                      ),
                      onPressed: () {}, // Disable normal press
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: SvgPicture.asset('assets/graphics/send_message_icon.svg'),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _startRecording(TextEditingController controller) async {
    await _speechToTextService.startRecording(controller);
    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecording(TextEditingController controller) async {
    await _speechToTextService.stopRecording();
    String? transcription = await _speechToTextService.transcribeAudio();
    if (transcription != null) {
      setState(() {
        controller.text = transcription;
        _isRecording = false;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String message = _messageController.text;
      setState(() {
        _messages.add(ChatMessage(
          text: message,
          isUser: true,
          userIcon: _userProfileImageUrl != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(_userProfileImageUrl!))
              : CircleAvatar(child: Icon(Icons.person)),
        ));
        _messageController.clear();
        _showIntroBox = false;
      });

      try {
        String aiResponse = await _aiChatService.sendMessage(
            widget.userId, _threadId!, message);
        setState(() {
          _messages.add(ChatMessage(
            text: aiResponse,
            isUser: false,
            userIcon: CircleAvatar(
              child: Padding(
                padding: EdgeInsets.all(3.0),
                child: Image.asset('assets/graphics/logo_black.png'),
              ),
              backgroundColor: Color(0xFF414254),
            ),
          ));
        });
        _updateRemainingMessages();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _resetThread() async {
    await _aiChatService.resetThread(widget.userId);
    setState(() {
      _messages.clear();
      _showIntroBox = true;
    });
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final Widget userIcon;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUser,
    required this.userIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            SizedBox(
              width: 30,
              height: 30,
              child: userIcon,
            ),
          SizedBox(width: 8.0),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF7D4666) : Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.0),
          if (isUser)
            SizedBox(
              width: 30,
              height: 30,
              child: userIcon,
            ),
        ],
      ),
    );
  }
}
