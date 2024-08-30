import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'bestaetigung_page.dart';
import 'speech_to_text_service.dart';
import 'elovando_love_session_service.dart';

class FeedbackPage extends StatefulWidget {
  final String userId;
  final ElovandoLoveSessionService service;

  FeedbackPage({required this.userId, required this.service});
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  double rating = 3.0;
  int selectedOption = 0;
  final TextEditingController _likedController = TextEditingController();
  final TextEditingController _dislikedController = TextEditingController();
  final SpeechToTextService _speechToTextService = SpeechToTextService();
  bool _isProcessingSpeech = false;
  bool _isSending = false;
  bool _isRecording = false;
  bool _hasRecordedAudio = false;
  TextEditingController? _currentRecordingController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF414254)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 0, bottom: 0),
          child: Text(
            'Feedback zur Love Session',
            style: TextStyle(
              color: Color(0xFF414254),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0.2),
          child: Divider(
            color: Color(0xFFDEDEDE),
            thickness: 1,
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Feedback zu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF414254),
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      'deiner letzten Love Session:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF414254),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      iconSize: 36,
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star,
                        color: index < rating
                            ? Color(0xFF7FCCB1)
                            : Color(0xFFDEDEDE),
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
              ),
              SizedBox(height: 16),
              _buildFeedbackInput('Das hat mir gefallen:', _likedController),
              SizedBox(height: 16),
              _buildFeedbackInput('Das war weniger gut:', _dislikedController),
              SizedBox(height: 20),
              Center(
                child: Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSending ? Colors.grey : Color(0xFF7D4666),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isSending ? null : () async {
                      setState(() {
                        _isSending = true;
                      });
                      try {
                        // Share feedback with the thread
                        String feedback = "Bewertung: $rating/5\n"
                            "Gefallen: ${_likedController.text}\n"
                            "Verbesserungswürdig: ${_dislikedController.text}";
                        await widget.service.shareFeedback(widget.userId, feedback);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BestaetigungPage(userId: widget.userId),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fehler beim Senden des Feedbacks: ${e.toString()}'),
                            duration: Duration(seconds: 10),
                            action: SnackBarAction(
                              label: 'OK',
                              onPressed: () {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );
                      } finally {
                        setState(() {
                          _isSending = false;
                        });
                      }
                    },
                    child: _isSending
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Senden',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Inter',
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackInput(String label, TextEditingController controller) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFDEDEDE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF414254),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 8),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: _isProcessingSpeech ? '' : 'Geben Sie Feedback ein',
                  hintStyle: TextStyle(color: Color(0xFF98999D)),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Color(0xFFF7F7F7),
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                ),
                maxLines: 3,
              ),
              if (_isProcessingSpeech && _currentRecordingController == controller)
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7D4666)),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/graphics/voice_input_icon.svg',
                  color: _isRecording && _currentRecordingController == controller ? Colors.red : null,
                ),
                onPressed: () => _toggleRecording(controller),
              ),
              if (_hasRecordedAudio && _currentRecordingController == controller)
                IconButton(
                  icon: Icon(Icons.play_arrow),
                  onPressed: _playRecordedAudio,
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleRecording(TextEditingController controller) {
    if (_isRecording && _currentRecordingController == controller) {
      _stopRecording(controller);
    } else {
      _startRecording(controller);
    }
  }

  void _startRecording(TextEditingController controller) async {
    try {
      await _speechToTextService.startRecording(controller);
      setState(() {
        _isRecording = true;
        _isProcessingSpeech = true;
        _hasRecordedAudio = false;
        _currentRecordingController = controller;
      });
      print("Recording started");
    } catch (e) {
      print("Error starting recording: $e");
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
      print("Recording stopped");
      String? transcription = await _speechToTextService.transcribeAudio();
      setState(() {
        _isRecording = false;
        _isProcessingSpeech = false;
        _hasRecordedAudio = true;
        if (transcription != null && transcription.isNotEmpty) {
          controller.text = transcription;
          print("Transcription successful: $transcription");
        } else {
          print("Transcription failed or returned empty");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to transcribe audio. Please try again.")),
          );
        }
      });
    } catch (e) {
      print("Error stopping recording or transcribing: $e");
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
      print("Error playing recorded audio: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to play recorded audio: ${e.toString()}")),
      );
    }
  }
}