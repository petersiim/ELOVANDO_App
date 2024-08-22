import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'elovando_love_session_service.dart';
import 'feedback_page.dart';
import 'env/env.dart';

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
  bool _isLoading = false;
  double _progressValue = 0.0;
  String _progressText = '';
  bool _isCancelled = false;
  bool _isInitialized = false;
  bool _isSessionStarted = false;

  @override
  void initState() {
    super.initState();
    _service = ElovandoLoveSessionService(Env.apiKey, "org-fZRna2F4kfSff4YTG4Lx15mM");
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
      _progressText = 'Initialisiere Love Session...';
    });
    await _service.initializeThread(widget.userId);
    setState(() {
      _isInitialized = true;
      _isLoading = false;
    });
  }

  Future<void> _createNewThread() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Neuen Thread erstellen'),
          content: Text('Wenn Sie einen neuen Thread erstellen, gehen alle vorherigen Informationen bezüglich der Eingaben und des Feedbacks verloren. Möchten Sie fortfahren?'),
          actions: <Widget>[
            TextButton(
              child: Text('Abbrechen'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Fortfahren'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm) {
      setState(() {
        _isLoading = true;
        _progressText = 'Erstelle neuen Thread...';
      });
      await _service.createNewThread(widget.userId);
      await _shareOnboardingInfo();
      setState(() {
        _isLoading = false;
        _isInitialized = true;
        _isSessionStarted = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Neuer Thread erstellt')),
      );
    }
  }

  Future<void> _startLoveSession() async {
    if (!_isInitialized || _isSessionStarted) return;

    bool canProceed = await _checkUserStatus();
    if (!canProceed) return;

    try {
      setState(() {
        _isLoading = true;
        _progressValue = 0.0;
        _progressText = 'Love Session wird gestartet...';
      });

      await _shareOnboardingInfo();

      final introResponse = await _service.startLoveSession(widget.userId, (message, progress) {
        if (_isCancelled) return;
        setState(() {
          _progressText = message;
          _progressValue = progress;
        });
      });

      if (_isCancelled) return;

      if (introResponse.containsKey('error')) {
        _handleError(introResponse['error']);
        return;
      }

      setState(() {
        _displayText = introResponse['intro'] ?? 'Keine Einführung vorhanden';
        _currentStep = introResponse['nextStep'] ?? 'error';
        _isLoading = false;
        _isSessionStarted = true;
      });
    } catch (e) {
      if (_isCancelled) return;
      print("Fehler beim Starten der Love Session: $e");
      _handleError("Fehler beim Starten der Love Session. Bitte versuchen Sie es erneut.");
    }
  }

  Future<bool> _checkUserStatus() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final partnerId = userDoc.data()?['partnerId'];
    final hasGivenInput = userDoc.data()?['hasGivenInput'] ?? false;

    if (partnerId == null) {
      return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Hinweis'),
            content: Text('Sie können die Love Session auch ohne Partner durchführen. Die Idee ist jedoch, dass Sie die Love Session gemeinsam mit Ihrem Partner nutzen, um Eingaben zu machen und Feedback zu geben.'),
            actions: <Widget>[
              TextButton(
                child: Text('Abbrechen'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text('Fortfahren'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );
    }

    if (!hasGivenInput) {
      return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Hinweis'),
            content: Text('Für eine personalisierte und effektive Love Session mit Ihrem Partner empfehlen wir, dass Sie beide zuvor Eingaben machen. Möchten Sie trotzdem fortfahren?'),
            actions: <Widget>[
              TextButton(
                child: Text('Abbrechen'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text('Fortfahren'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );
    }

    return true;
  }

  Future<void> _shareOnboardingInfo() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final userData = userDoc.data() ?? {};
    
    final onboardingInfo = {
      'name': userData['name'],
      'gender': userData['gender'],
      'birthdate': userData['birthdate'],
      'relationshipMovie': userData['question4'],
      'relationshipAnimal': userData['question5'],
      'cookingRoleUser': userData['question6'],
      'cookingRolePartner': userData['question7'],
      'partnerSupport': userData['question8'],
      'deadlySin': userData['question9'],
      'relationshipDetails': userData['question10'],
    };

    final onboardingQuestions = {
      'name': 'So möchtest du von deinem Partner / deiner Partnerin genannt werden:',
      'gender': 'Gender:',
      'birthdate': 'Geburtsdatum:',
      'relationshipMovie': 'Welche Art von Film repräsentiert am besten eure Beziehung?',
      'relationshipAnimal': 'Welches Tierduo beschreibt eure Partnerschaft am besten?',
      'cookingRoleUser': 'Wenn ihr zusammen kochen würdet, welche Rolle übernimmst du?',
      'cookingRolePartner': 'Welche Rolle würde dein Partner übernehmen?',
      'partnerSupport': 'Wie unterstützt du deinen Partner in einer schwierigen Situation?',
      'deadlySin': 'Für welche der sieben Todsünden bist du am ehesten empfänglich?',
      'relationshipDetails': 'Erzähle uns doch noch etwas mehr über eure Beziehung. Wie läuft es?',
    };

    final formattedOnboardingInfo = onboardingInfo.map((key, value) {
      final question = onboardingQuestions[key] ?? 'Unbekannte Frage';
      return MapEntry(key, {
        'Frage': question,
        'Antwort': value ?? 'Keine Angabe'
      });
    });

    await _service.shareOnboardingInfo(widget.userId, formattedOnboardingInfo);
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

      if (_isCancelled) return;

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
      if (_isCancelled) return;
      print("Fehler beim Verarbeiten des nächsten Schritts: $e");
      _handleError("Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.");
    }
  }

  void _handleError(String errorMessage) {
    if (_isCancelled) return;
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
    if (_isCancelled) return;
    print("Sitzung wird beendet. Navigation zur FeedbackPage");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackPage(userId: widget.userId, service: _service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _isCancelled = true;
        });
        return true;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF7F7F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF414254)),
            onPressed: () {
              setState(() {
                _isCancelled = true;
              });
              Navigator.of(context).pop();
            },
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 0),
            child: Text(
              'Love-Session',
              style: TextStyle(
                color: Color(0xFF414254),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Color(0xFF7FCCB1)),
              onPressed: _createNewThread,
              tooltip: 'Thread erneuern',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(0.2),
            child: Divider(
              color: Color(0xFFDEDEDE),
              thickness: 1,
              height: 1,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
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
                else if (!_isSessionStarted)
                  Expanded(
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _startLoveSession,
                        child: Text('Love Session starten'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color(0xFF7FCCB1),
                        ),
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
                if (_isSessionStarted && _currentStep != 'end' && !_isLoading)
                  ElevatedButton(
                    onPressed: _handleNextStep,
                    child: Text('Weiter'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF7FCCB1),
                    ),
                  )
                else if (_isSessionStarted && _currentStep == 'end' && !_isLoading)
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
        ),
      ),
    );
  }
}