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
  bool _isLoading = true;
  double _progressValue = 0.0;
  String _progressText = '';

  @override
  void initState() {
    super.initState();
    _service = ElovandoLoveSessionService(Env.apiKey, "org-fZRna2F4kfSff4YTG4Lx15mM");
    _startLoveSession();
  }

  Future<void> _startLoveSession() async {
    try {
      setState(() {
        _isLoading = true;
        _progressValue = 0.0;
        _progressText = 'Love Session wird initialisiert...';
      });

      final introResponse = await _service.startLoveSession((message, progress) {
        setState(() {
          _progressText = message;
          _progressValue = progress;
        });
      });

      if (introResponse.containsKey('error')) {
        _handleError(introResponse['error']);
        return;
      }

      setState(() {
        _displayText = introResponse['intro'] ?? 'Keine Einführung vorhanden';
        _currentStep = introResponse['nextStep'] ?? 'error';
        _isLoading = false;
      });
    } catch (e) {
      print("Fehler beim Starten der Love Session: $e");
      _handleError("Fehler beim Starten der Love Session. Bitte versuchen Sie es erneut.");
    }
  }

  void _handleNextStep() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> response;
      switch (_currentStep) {
        case 'partnerAToB':
          response = await _service.getPartnerStatement('A', 'B');
          break;
        case 'partnerBToA':
          response = await _service.getPartnerStatement('B', 'A');
          break;
        case 'outro':
          response = await _service.getOutro();
          break;
        case 'end':
          _endSession();
          return;
        default:
          _handleError("Ein Fehler ist aufgetreten. Unbekannter Schritt: $_currentStep");
          return;
      }

      if (response.containsKey('error')) {
        _handleError(response['error']);
      } else {
        setState(() {
          _displayText = response['statement'] ?? response['outro'] ?? 'Kein Inhalt vorhanden';
          _currentStep = response['nextStep'] ?? 'error';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Fehler beim Verarbeiten des nächsten Schritts: $e");
      _handleError("Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.");
    }
  }

  void _handleError(String errorMessage) {
    setState(() {
      _displayText = errorMessage;
      _currentStep = 'error';
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  }

  void _endSession() {
    print("Sitzung wird beendet. Navigation zur FeedbackPage");
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
            if (_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _progressValue,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7FCCB1)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        _progressText,
                        style: TextStyle(fontSize: 18, color: Color(0xFF414254)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _displayText,
                    style: TextStyle(fontSize: 18, color: Color(0xFF414254)),
                  ),
                ),
              ),
            SizedBox(height: 16),
            if (_currentStep != 'end' && !_isLoading)
              ElevatedButton(
                onPressed: _handleNextStep,
                child: Text('Weiter'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF7FCCB1),
                ),
              )
            else if (_currentStep == 'end' && !_isLoading)
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
