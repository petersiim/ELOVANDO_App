import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ai_chat_service.dart';
import 'speech_to_text_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:envied/envied.dart';
import 'env/env.dart';
import 'package:dart_openai/dart_openai.dart' as openai;
import 'dart:developer';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'home_page.dart';

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
  int _remainingMessages = 100;
  bool _isLoading = false;
  String _loadingText = "";
  late Timer _loadingTimer;
  bool _isProcessingSpeech = false;
  List<Map<String, String>> _recommendations = [];
  bool _hasRecordedAudio = false;

  final List<Map<String, String>> allRecommendations = [
    {"text": "Kannst du unsere Beziehungsdynamik analysieren und uns deine Beobachtungen mitteilen?", "emoji": "🔍"},
    {"text": "Welche psychologischen Theorien zur Paarbeziehung wären für uns hilfreich zu verstehen?", "emoji": "🧠"},
    {"text": "Hast du einen praktischen Tipp, der uns helfen könnte, unsere Beziehung zu verbessern?", "emoji": "💡"},
    {"text": "Welche Strategien können wir anwenden, um unsere Kommunikation effektiver zu gestalten?", "emoji": "🗣️"},
    {"text": "Welche Techniken empfiehlst du uns, um Konflikte konstruktiv zu lösen?", "emoji": "🤝"},
    {"text": "Was können wir tun, um das Vertrauen in unserer Beziehung zu stärken?", "emoji": "🔒"},
    {"text": "Welche Schritte können wir unternehmen, um mehr Intimität und Nähe in unserer Beziehung zu schaffen?", "emoji": "❤️"},
    {"text": "Wie können wir effektiver an unseren gemeinsamen Zielen arbeiten und sie erreichen?", "emoji": "🎯"},
    {"text": "Welche Tipps hast du, um ein besseres Gleichgewicht zwischen unserem individuellen und gemeinsamen Leben zu finden?", "emoji": "⚖️"},
    {"text": "Welche Strategien können uns helfen, Stress und Belastungen in unserer Beziehung zu bewältigen?", "emoji": "🧘"},
    {"text": "Hast du Ideen, wie wir mehr Freude und Leichtigkeit in unserer Beziehung erleben können?", "emoji": "😊"},
    {"text": "Welche Schritte sollten wir unternehmen, um alte Konflikte und Verletzungen zu heilen und loszulassen?", "emoji": "🌱"}
  ];

  @override
  void initState() {
    super.initState();
    print("DEBUG: ChatPage initState called");
    _fetchUserProfileImage();
    _initializeAIChatService();
    _loadingTimer = Timer(Duration.zero, () {});
    _getRandomRecommendations();
  }

  @override
  void dispose() {
    _loadingTimer.cancel();
    super.dispose();
  }

  void _getRandomRecommendations() {
    final random = Random();
    _recommendations = List.generate(
      3,
      (_) => allRecommendations[random.nextInt(allRecommendations.length)]
    ).toSet().toList();
    if (_recommendations.length < 3) {
      _getRandomRecommendations();
    }
  }

  Future<void> _initializeAIChatService() async {
    print("DEBUG: Initializing AIChatService");
    _aiChatService = AIChatService(Env.apiKey, "org-fZRna2F4kfSff4YTG4Lx15mM");
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      _threadId = userDoc.data()?['loveSessionThreadId'] as String?;
      print("DEBUG: Existing threadId: $_threadId");
      if (_threadId == null) {
        await _createNewThread(userDoc);
      }
      await _updateRemainingMessages();
    } catch (e) {
      print("ERROR: Exception in _initializeAIChatService: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to initialize chat. Please try again later.")),
      );
    }
  }

  Future<void> _createNewThread(DocumentSnapshot userDoc) async {
    print("DEBUG: Creating new thread");
    _threadId = await _aiChatService.createThread();
    print("DEBUG: New threadId: $_threadId");
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'loveSessionThreadId': _threadId});
    
    // Send initial user information
    Map<String, dynamic> userInfo = userDoc.data() as Map<String, dynamic>? ?? {};
    userInfo.remove('password');
    String userInfoString = userInfo.entries.map((e) => "${e.key}: ${e.value}").join("\n");
    print("DEBUG: Sending initial user information");
    await _aiChatService.addMessageToThread(_threadId!, "User Information:\n$userInfoString");
  }

  Future<void> _fetchUserProfileImage() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      setState(() {
        _userProfileImageUrl = userDoc.data()?['profileImageUrl'];
      });
      print("DEBUG: User profile image URL: $_userProfileImageUrl");
    } catch (e) {
      print("ERROR: Exception in _fetchUserProfileImage: $e");
    }
  }

  Future<void> _updateRemainingMessages() async {
    try {
      int remaining = await _aiChatService.getRemainingMessages(widget.userId);
      setState(() {
        _remainingMessages = remaining;
      });
      print("DEBUG: Updated remaining messages: $_remainingMessages");
    } catch (e) {
      print("ERROR: Exception in _updateRemainingMessages: $e");
      setState(() {
        _remainingMessages = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) =>
                  HomePage(userId: widget.userId, initialIndex: 0)),
          (Route<dynamic> route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF7F7F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF414254)),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) =>
                        HomePage(userId: widget.userId, initialIndex: 0)),
                (Route<dynamic> route) => false,
              );
            },
          ),
          title: Text(
            'Paar-Chat',
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
            if (_showIntroBox) _buildRecommendations(),
            Expanded(
              child: _showIntroBox ? _buildIntroBox() : _buildChatList(),
            ),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Loading: $_loadingText",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF414254),
                  ),
                ),
              ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      height: 200,
      child: ListView.builder(
        itemCount: _recommendations.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () {
                _messageController.text = _recommendations[index]['text']!;
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_recommendations[index]['emoji']!,
                      style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _recommendations[index]['text']!,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFF7D4666),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Color(0xFF7D4666)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntroBox() {
    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                      'Paar-Chat',
                      style: TextStyle(
                        color: Color(0xFF414254),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Hast du Fragen zu Liebe, Beziehung oder Sexualität? Unser kostenloser, anonymer ELOVANDO Paar-Chat bietet dir jederzeit Unterstützung und hilfreiche Ratschläge.',
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
                        hintText: _isProcessingSpeech ? 'Transkribiere...' : 'Nachricht eingeben...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/graphics/voice_input_icon.svg',
                      color: _isRecording ? Colors.red : null,
                    ),
                    onPressed: _toggleRecording,
                  ),
                  if (_hasRecordedAudio)
                    IconButton(
                      icon: Icon(Icons.play_arrow),
                      onPressed: _playRecordedAudio,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: SvgPicture.asset('assets/graphics/send_message_icon.svg'),
            onPressed: () => _sendMessage(_messageController.text),
          ),
        ],
      ),
    );
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording(_messageController);
    } else {
      _startRecording(_messageController);
    }
  }

  void _startRecording(TextEditingController controller) async {
    try {
      await _speechToTextService.startRecording(controller);
      setState(() {
        _isRecording = true;
        _isProcessingSpeech = true;
        _hasRecordedAudio = false;
      });
      print("DEBUG: Recording started");
    } catch (e) {
      print("ERROR: Exception in _startRecording: $e");
      setState(() {
        _isRecording = false;
        _isProcessingSpeech = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start recording: ${e.toString()}")),
      );
    }
  }

  void _stopRecording(TextEditingController controller) async {
    try {
      await _speechToTextService.stopRecording();
      print("DEBUG: Recording stopped");
      String? transcription = await _speechToTextService.transcribeAudio();
      setState(() {
        _isRecording = false;
        _isProcessingSpeech = false;
        _hasRecordedAudio = true;
        if (transcription != null && transcription.isNotEmpty) {
          controller.text = transcription;
          print("DEBUG: Transcription successful: $transcription");
        } else {
          print("DEBUG: Transcription failed or returned empty");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to transcribe audio. Please try again.")),
          );
        }
      });
    } catch (e) {
      print("ERROR: Exception in _stopRecording: $e");
      setState(() {
        _isRecording = false;
        _isProcessingSpeech = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing speech: ${e.toString()}")),
      );
    }
  }

  void _playRecordedAudio() async {
    try {
      await _speechToTextService.playRecordedAudio();
    } catch (e) {
      print("ERROR: Exception in _playRecordedAudio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to play recorded audio: ${e.toString()}")),
      );
    }
  }

  Future<void> _sendMessage(String message) async {
    print("DEBUG: Sending message: $message");
    if (message.isEmpty || _threadId == null) {
      print("DEBUG: Message is empty or threadId is null. Not sending.");
      return;
    }

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        userIcon: _userProfileImageUrl != null
            ? CircleAvatar(backgroundImage: NetworkImage(_userProfileImageUrl!))
            : CircleAvatar(child: Icon(Icons.person)),
      ));
      _messageController.clear();
      _showIntroBox = false;

      _messages.add(ChatMessage(
        text: '',
        isUser: false,
        userIcon: CircleAvatar(
          child: Padding(
            padding: EdgeInsets.all(3.0),
            child: Image.asset('assets/graphics/logo_black.png'),
          ),
          backgroundColor: Color(0xFF414254),
        ),
        isLoading: true,
      ));
    });

    try {
      print("DEBUG: Adding message to thread");
      await _aiChatService.addMessageToThread(_threadId!, message);
      print("DEBUG: Running assistant");
      String aiResponse = await _aiChatService.runAssistant(_threadId!, widget.userId);
      print("DEBUG: AI Response received: $aiResponse");

      // Decode the UTF-8 encoded response
      String decodedResponse = utf8.decode(aiResponse.runes.toList());

      setState(() {
        // Remove the last two messages (user message and loading message)
        _messages.removeLast();
        _messages.removeLast();

        // Add the user message back
        _messages.add(ChatMessage(
          text: message,
          isUser: true,
          userIcon: _userProfileImageUrl != null
              ? CircleAvatar(backgroundImage: NetworkImage(_userProfileImageUrl!))
              : CircleAvatar(child: Icon(Icons.person)),
        ));

        // Add the AI response
        _messages.add(ChatMessage(
          text: decodedResponse,
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
      await _updateRemainingMessages();
    } catch (e) {
      print("ERROR: Exception in _sendMessage: $e");
      if (e.toString().contains("No thread found with id")) {
        print("DEBUG: Thread not found. Creating a new thread.");
        await _createNewThread(await FirebaseFirestore.instance.collection('users').doc(widget.userId).get());
        // Retry sending the message with the new thread
        return _sendMessage(message);
      } else {
        setState(() {
          // Remove the loading message
          _messages.removeLast();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending message: ${e.toString()}")),
        );
      }
    }
  }

  void _resetThread() async {
    print("DEBUG: Resetting thread");
    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Text(
            'Chat zurücksetzen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
              fontFamily: 'Inter',
            ),
          ),
          content: Text(
            'Der Chat wird neu erstellt. Dies kann einige Minuten dauern. Möchten Sie fortfahren?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF414254),
              fontFamily: 'Inter',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Nein',
                style: TextStyle(
                  color: Color(0xFF7D4666),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(
                'Ja, fortfahren',
                style: TextStyle(
                  color: Color(0xFF7FCCB1),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _loadingText = 'Erstelle neuen Thread...';
      });

      try {
        await _createNewThread(await FirebaseFirestore.instance.collection('users').doc(widget.userId).get());
        setState(() {
          _messages.clear();
          _showIntroBox = true;
        });
        await _updateRemainingMessages();
      } catch (e) {
        print("ERROR: Exception in _resetThread: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Fehler beim Zurücksetzen des Chats. Bitte versuchen Sie es erneut.")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final Widget userIcon;
  final bool isLoading;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUser,
    required this.userIcon,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) SizedBox(width: 30, height: 30, child: userIcon),
          SizedBox(width: 8.0),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF7D4666) : Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: isLoading
                  ? _buildLoadingIndicator()
                  : Text(
                      text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 8.0),
          if (isUser) SizedBox(width: 30, height: 30, child: userIcon),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        ),
      ],
    );
  }
}
