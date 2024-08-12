import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'speech_to_text_service.dart';

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
  late SpeechToTextService _speechToTextService = SpeechToTextService();

  @override
  void initState() {
    super.initState();
    _fetchUserProfileImage();
    _speechToTextService = SpeechToTextService();

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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0.2),
          child: Divider(color: Color(0xFFDEDEDE), thickness: 1, height: 1),
        ),
      ),
      body: Column(
        children: [
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
                borderRadius: BorderRadius.circular(20),
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
                  IconButton(
                    icon: SvgPicture.asset(
                        'assets/graphics/voice_input_icon.svg'),
                    onPressed: () async {
                      final text =
                          await _speechToTextService.recordAndTranscribe();
                      if (text != null) {
                        setState(() {
                          _messageController.text = text;
                        });
                      }
                    },
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

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          text: _messageController.text,
          isUser: true,
          userIcon: _userProfileImageUrl != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(_userProfileImageUrl!))
              : CircleAvatar(child: Icon(Icons.person)),
        ));
        _showIntroBox = false;
        _messageController.clear();
      });

      // Simulate therapist response
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          _messages.add(ChatMessage(
            text: 'This is a simulated therapist response.',
            isUser: false,
            userIcon: CircleAvatar(
              child: Padding(
                padding:
                    EdgeInsets.all(3.0), // Adjust padding to change image size
                child: Image.asset('assets/graphics/logo_black.png'),
              ),
              backgroundColor: Color(0xFF414254),
            ),
          ));
        });
      });
    }
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
              width: 30, // Adjust size as needed
              height: 30, // Adjust size as needed
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
              width: 30, // Adjust size as needed
              height: 30, // Adjust size as needed
              child: userIcon,
            ),
        ],
      ),
    );
  }
}
