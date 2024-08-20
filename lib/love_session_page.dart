import 'package:flutter/material.dart';
import 'elovando_love_session_service.dart';
import 'feedback_page.dart';
import 'env/env.dart'; // Import the environment variables

class LoveSessionPage extends StatefulWidget {
  final String userId;

  LoveSessionPage({required this.userId});

  @override
  _LoveSessionPageState createState() => _LoveSessionPageState();
}

class _LoveSessionPageState extends State<LoveSessionPage> {
  late final ElovandoLoveSessionService _service;
  String _currentStep = 'intro';
  String _displayText = '';
  String _partnerAStatement = '';
  String _partnerBStatement = '';

  @override
  void initState() {
    super.initState();
    _service = ElovandoLoveSessionService(Env.apiKey, "org-fZRna2F4kfSff4YTG4Lx15mM");
    _startSession();
  }

  void _startSession() async {
    try {
      print("Starting session...");
      final response = await _service.startLoveSession();
      print("Session started. Response: $response");
      setState(() {
        _displayText = response['intro'] ?? 'No introduction provided';
        _currentStep = response['nextStep'] ?? 'error';
      });
      print("Current step: $_currentStep");
      print("Display text: $_displayText");
    } catch (e) {
      print("Error starting session: $e");
      setState(() {
        _displayText = "Error starting session. Please try again.";
        _currentStep = 'error';
      });
    }
  }

  void _handleNextStep() async {
    print("Handling next step. Current step: $_currentStep");
    try {
      Map<String, dynamic> response;
      switch (_currentStep) {
        case 'partnerAStatement':
          response = await _service.getPartnerStatement('A');
          setState(() {
            _partnerAStatement = response['statement'] ?? 'No statement provided';
            _displayText = "Partner A, please read the following statement:\n\n$_partnerAStatement";
            _currentStep = response['nextStep'] ?? 'error';
          });
          break;
        case 'partnerBStatement':
          response = await _service.getPartnerStatement('B');
          setState(() {
            _partnerBStatement = response['statement'] ?? 'No statement provided';
            _displayText = "Partner B, please read the following statement:\n\n$_partnerBStatement";
            _currentStep = response['nextStep'] ?? 'error';
          });
          break;
        case 'outro':
          response = await _service.getOutro();
          setState(() {
            _displayText = response['outro'] ?? 'No outro provided';
            _currentStep = 'end';
          });
          break;
        case 'end':
          print("Session ended. Waiting for user to press 'Beenden'");
          break;
        default:
          print("Unknown step: $_currentStep");
          setState(() {
            _displayText = "An error occurred. Please try again.";
            _currentStep = 'error';
          });
      }
    } catch (e) {
      print("Error handling next step: $e");
      setState(() {
        _displayText = "An error occurred. Please try again.";
        _currentStep = 'error';
      });
    }
    print("After handling step. Current step: $_currentStep");
    print("Display text: $_displayText");
  }

  void _endSession() {
    print("Ending session. Navigating to FeedbackPage");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackPage(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Love Session'),
        backgroundColor: Color(0xFF7FCCB1),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _displayText,
                  style: TextStyle(fontSize: 18, color: Color(0xFF414254)),
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_currentStep != 'end')
              ElevatedButton(
                onPressed: _handleNextStep,
                child: Text('Next'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF7FCCB1),
                ),
              )
            else
              ElevatedButton(
                onPressed: _endSession,
                child: Text('Beenden'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF7D4666),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
