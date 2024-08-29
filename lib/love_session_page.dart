import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';
import 'elovando_love_session_service.dart';
import 'text_to_speech_service.dart';
import 'feedback_page.dart';
import 'env/env.dart';

class LoveSessionPage extends StatefulWidget {
  final String userId;

  LoveSessionPage({required this.userId});

  @override
  _LoveSessionPageState createState() => _LoveSessionPageState();
}

class _LoveSessionPageState extends State<LoveSessionPage> with SingleTickerProviderStateMixin {
  late final ElovandoLoveSessionService _service;
  late final TextToSpeechService _ttsService;
  late final AudioPlayer _audioPlayer;
  late AnimationController _animationController;
  String _currentStep = 'intro';
  String _displayText = '';
  bool _isLoading = false;
  bool _isTtsLoading = false;
  double _progressValue = 0.0;
  String _progressText = '';
  bool _isCancelled = false;
  bool _isInitialized = false;
  bool _isSessionStarted = false;
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  String? _audioFilePath;
  List<double> _waveformData = [];
  bool _isIntroComplete = false;
  bool _isOutroPhase = false;
  bool _partnerAStarts = true;
  int _statementCount = 0;
  Map<String, String> _preloadedAudioPaths = {};

  @override
  void initState() {
    super.initState();
    _service = ElovandoLoveSessionService(Env.apiKey, "org-fZRna2F4kfSff4YTG4Lx15mM");
    _ttsService = TextToSpeechService();
    _audioPlayer = AudioPlayer();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
    _initializeService();
    _setupAudioPlayerListeners();
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _audioPosition = position;
      });
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });

    _audioPlayer.playerStateStream.listen((playerState) {
      setState(() {
        _isPlaying = playerState.playing;
      });
    });
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
      _resetSessionState();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Neuer Thread erstellt')),
      );
    }
  }

  void _resetSessionState() {
    setState(() {
      _isLoading = false;
      _isInitialized = true;
      _isSessionStarted = false;
      _isIntroComplete = false;
      _isOutroPhase = false;
      _statementCount = 0;
      _currentStep = 'intro';
    });
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

      // Ensure thread is initialized before starting the session
      await _service.initializeThread(widget.userId);

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

      // Preload intro and outro audio
      await _preloadAudio(introResponse['intro'], 'intro');
      final outroResponse = await _service.getOutro();
      await _preloadAudio(outroResponse['outro'], 'outro');

      setState(() {
        _displayText = introResponse['intro'] ?? 'Keine Einführung vorhanden';
        _currentStep = 'intro';
        _isLoading = false;
        _isSessionStarted = true;
        _isIntroComplete = false;
        _isOutroPhase = false;
        _partnerAStarts = introResponse['nextStep'] == 'partnerAToB';
        _statementCount = 0;
      });

      await _playPreloadedAudio('intro');
    } catch (e) {
      if (_isCancelled) return;
      print("Fehler beim Starten der Love Session: $e");
      _handleError("Fehler beim Starten der Love Session. Bitte versuchen Sie es erneut.");
    }
  }

  Future<void> _preloadAudio(String text, String key) async {
    try {
      final audioData = await _ttsService.generateSpeech(text);
      final tempDir = await getApplicationDocumentsDirectory();
      final tempFile = File('${tempDir.path}/temp_audio_$key.mp3');
      await tempFile.writeAsBytes(audioData);
      _preloadedAudioPaths[key] = tempFile.path;
      print("Audio preloaded for $key");
    } catch (e) {
      print("Error preloading audio for $key: $e");
    }
  }

  Future<void> _playPreloadedAudio(String key) async {
    if (_preloadedAudioPaths.containsKey(key)) {
      await _audioPlayer.setFilePath(_preloadedAudioPaths[key]!);
      final audioFile = File(_preloadedAudioPaths[key]!);
      final audioData = await audioFile.readAsBytes();
      _generateWaveformData(audioData);
      _audioPlayer.play();
    } else {
      print("Preloaded audio not found for $key");
    }
  }

  Future<void> _generateAndPlayAudio(String text, {String? key}) async {
    try {
      setState(() {
        _isTtsLoading = true;
      });

      if (key != null && _preloadedAudioPaths.containsKey(key)) {
        await _playPreloadedAudio(key);
      } else {
        final audioData = await _ttsService.generateSpeech(text);
        final tempDir = await getApplicationDocumentsDirectory();
        final tempFile = File('${tempDir.path}/temp_audio.mp3');
        await tempFile.writeAsBytes(audioData);

        _audioFilePath = tempFile.path;
        await _audioPlayer.setFilePath(_audioFilePath!);
        _generateWaveformData(audioData);
        _audioPlayer.play();
      }

      setState(() {
        _isTtsLoading = false;
      });
    } catch (e) {
      print("Fehler bei der Audiogenerierung: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Audiowiedergabe')),
      );
      setState(() {
        _isTtsLoading = false;
      });
    }
  }

  void _generateWaveformData(List<int> audioData) {
    const int samplesPerPoint = 200;
    List<double> waveform = [];
    for (int i = 0; i < audioData.length; i += samplesPerPoint) {
      int end = i + samplesPerPoint;
      if (end > audioData.length) end = audioData.length;
      List<int> chunk = audioData.sublist(i, end);
      double average = chunk.reduce((a, b) => a + b) / chunk.length;
      waveform.add(average.abs() / 128); // Normalize to 0-1 range
    }
    setState(() {
      _waveformData = waveform;
    });
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
    print("Handling next step. Current step: $_currentStep, Statement count: $_statementCount");
    _stopAudio(); // Stop audio immediately when "Weiter" is pressed
    setState(() {
      _isLoading = true;
    });

    try {
      if (!_isIntroComplete) {
        print("Intro not complete. Moving to first statement.");
        _isIntroComplete = true;
        await _getNextStatement();
      } else if (_isOutroPhase) {
        print("In outro phase. Ending session.");
        _endSession();
        return;
      } else if (_statementCount < 2) {
        print("Getting next statement. Current count: $_statementCount");
        await _getNextStatement();
      } else {
        print("All statements complete. Moving to outro.");
        _isOutroPhase = true;
        if (_preloadedAudioPaths.containsKey('outro')) {
          final outroResponse = await _service.getOutro();
          _displayText = outroResponse['outro'];
          await _playPreloadedAudio('outro');
        } else {
          final outroResponse = await _service.getOutro();
          _displayText = outroResponse['outro'];
          await _generateAndPlayAudio(_displayText, key: 'outro');
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (_isCancelled) return;
      print("Fehler beim Verarbeiten des nächsten Schritts: $e");
      _handleError("Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.");
    }
  }

  Future<void> _getNextStatement() async {
    final response = await _service.getPartnerStatement(
      _partnerAStarts ? 'A' : 'B',
      _partnerAStarts ? 'B' : 'A'
    );
    _displayText = response['statement'];
    _statementCount++;
    _partnerAStarts = !_partnerAStarts; // Switch for next time
    print("Statement received. New count: $_statementCount, Next starter: ${_partnerAStarts ? 'A' : 'B'}");
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
    _stopAudio();
    if (_isCancelled) return;
    print("Sitzung wird beendet. Navigation zur FeedbackPage");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackPage(userId: widget.userId, service: _service),
      ),
    );
  }

  void _stopAudio() {
    _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _audioPosition = Duration.zero;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _isCancelled = true;
        });
        _stopAudio();
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
              _stopAudio();
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
                      child: Column(
                        children: [
                          Text(
                            _displayText,
                            style: TextStyle(fontSize: 18, color: Color(0xFF414254)),
                          ),
                          SizedBox(height: 16),
                          if (_isTtsLoading)
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7FCCB1)),
                            )
                          else if ((!_isIntroComplete || _isOutroPhase) && _waveformData.isNotEmpty)
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: CircularWaveformPainter(
                                    _waveformData,
                                    _animationController.value,
                                  ),
                                  size: Size(200, 200),
                                );
                              },
                            ),
                          SizedBox(height: 16),
                          if (!_isIntroComplete || _isOutroPhase)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                                  onPressed: () {
                                    if (_isPlaying) {
                                      _audioPlayer.pause();
                                    } else {
                                      _audioPlayer.play();
                                    }
                                  },
                                ),
                                Text(
                                  '${_audioPosition.inMinutes}:${(_audioPosition.inSeconds % 60).toString().padLeft(2, '0')} / ${_audioDuration.inMinutes}:${(_audioDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                if (_isSessionStarted && !_isLoading)
                  ElevatedButton(
                    onPressed: _handleNextStep,
                    child: Text(_isOutroPhase ? 'Beenden' : 'Weiter'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _isOutroPhase ? Color(0xFF7D4666) : Color(0xFF7FCCB1),
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

class CircularWaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double animationValue;

  CircularWaveformPainter(this.waveformData, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF7FCCB1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < waveformData.length; i++) {
      final angle = 2 * pi * i / waveformData.length - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      final waveHeight = waveformData[i] * radius * 0.3;
      final animatedWaveHeight = waveHeight * animationValue;
      
      final innerX = center.dx + (radius - animatedWaveHeight) * cos(angle);
      final innerY = center.dy + (radius - animatedWaveHeight) * sin(angle);

      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(x, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}