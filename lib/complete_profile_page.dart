import 'package:ELOVANDO_App/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'speech_to_text_service.dart';
import 'data_input_formatter.dart';
import 'elovando_love_session_service.dart';
import 'env/env.dart';

class CompleteProfilePage extends StatefulWidget {
  final String userId;
  final Map<String, bool> completedQuestions;

  CompleteProfilePage({required this.userId, required this.completedQuestions}){
    print("CompleteProfilePage initialized with userId: $userId");}

  @override
  _CompleteProfilePageState createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final SpeechToTextService _speechToTextService = SpeechToTextService();
  int _currentPage = 0;
  PageController _pageController = PageController();
  List<int> selectedOptionIndexes = List<int>.generate(11, (index) => -1);
  bool showError = false;
  bool _isProcessingSpeech = false;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _lastQuestionController = TextEditingController();

  final List<String> questions = [
    'So möchtest du von deinem Partner / deiner Partnerin genannt werden:',
    'Gender:',
    'Geburtsdatum:',
    'Welche Art von Film repräsentiert am besten eure Beziehung?',
    'Welches Tierduo beschreibt eure Partnerschaft am besten?',
    'Wenn ihr zusammen kochen würdet, welche Rolle übernimmst du?',
    'Welche Rolle würde dein Partner übernehmen?',
    'Wie unterstützt du deinen Partner in einer schwierigen Situation?',
    'Für welche der sieben Todsünden bist du am ehesten empfänglich?',
    'Erzähle uns doch noch etwas mehr über eure Beziehung. Wie läuft es?',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _currentPage = widget.completedQuestions.values.toList().indexOf(false);
    if (_currentPage == -1) _currentPage = 0;
    _pageController = PageController(initialPage: _currentPage);
  }

  Future<void> _loadUserData() async {
    var userData = await _firestoreService.getUserProfile(widget.userId);
    _nameController.text = userData['name'] ?? '';
    _dateController.text = userData['birthdate'] ?? '';
    setState(() {
      selectedOptionIndexes[1] = userData['gender'] ?? -1;
      for (int i = 3; i < 9; i++) {
        selectedOptionIndexes[i] = userData['question${i + 1}'] ?? -1;
      }
      _lastQuestionController.text = userData['question10'] ?? '';
    });
  }

  void _nextPage() async {
    if (_validateCurrentPage()) {
      if (_currentPage < questions.length - 1) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        await _finishProfileCompletion();
      }
    }
  }

  bool _validateCurrentPage() {
    showError = false;
    switch (_currentPage) {
      case 0:
        if (_nameController.text.isEmpty) {
          showError = true;
        }
        break;
      case 1:
        if (selectedOptionIndexes[_currentPage] == -1) {
          showError = true;
        }
        break;
      case 2:
        String input = _dateController.text;
        RegExp regExp =
            RegExp(r"^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/([0-9]{4})$");
        if (!regExp.hasMatch(input)) {
          showError = true;
        }
        break;
      case 9:
        if (_lastQuestionController.text.isEmpty) {
          showError = true;
        }
        break;
      default:
        if (selectedOptionIndexes[_currentPage] == -1) {
          showError = true;
        }
    }
    setState(() {});
    return !showError;
  }

  Future<void> _finishProfileCompletion() async {
  if (widget.userId.isEmpty) {
    print('Error: Invalid user ID');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred. Please try again later.')),
    );
    return;
  }

  try {
    // Update all questions as completed
    Map<String, bool> updatedCompletion = {};
    for (String question in questions) {
      updatedCompletion[question] = true;
    }

    await _firestoreService.updateUserProfileCompletion(
        widget.userId, updatedCompletion);

    Map<String, dynamic> updatedUserData = {
      'name': _nameController.text,
      'gender': selectedOptionIndexes[1],
      'birthdate': _dateController.text,
    };
    for (int i = 3; i < 9; i++) {
      updatedUserData['question${i + 1}'] = selectedOptionIndexes[i];
    }
    updatedUserData['question10'] = _lastQuestionController.text;

    // Add a new field to indicate profile completion
    updatedUserData['isProfileCompleted'] = true;

    await _firestoreService.updateUserProfile(widget.userId, updatedUserData);

    // Update Love Session info
    await _updateLoveSessionInfo();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          userId: widget.userId,
        ),
      ),
    );
  } catch (e) {
    print('Error updating profile: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update profile. Please try again.')),
    );
  }
}

  Future<void> _updateLoveSessionInfo() async {
    final service =
        ElovandoLoveSessionService(Env.apiKey, "org-fZRna2F4kfSff4YTG4Lx15mM");
    await service.initializeThread(widget.userId);

    Map<String, dynamic> updatedInfo = await _gatherNewInfo();
    if (updatedInfo.isNotEmpty) {
      await service.updateOnboardingInfo(widget.userId, updatedInfo);
    }
  }

  Future<Map<String, dynamic>> _gatherNewInfo() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final oldData = userDoc.data() ?? {};

    Map<String, dynamic> newInfo = {};

    void addIfChanged(String key, dynamic newValue) {
      if (newValue != null && newValue != oldData[key]) {
        newInfo[key] = newValue;
      }
    }

    addIfChanged('name', _nameController.text);
    addIfChanged('gender', selectedOptionIndexes[1]);
    addIfChanged('birthdate', _dateController.text);
    addIfChanged('question4', selectedOptionIndexes[3]);
    addIfChanged('question5', selectedOptionIndexes[4]);
    addIfChanged('question6', selectedOptionIndexes[5]);
    addIfChanged('question7', selectedOptionIndexes[6]);
    addIfChanged('question8', selectedOptionIndexes[7]);
    addIfChanged('question9', selectedOptionIndexes[8]);
    addIfChanged('question10', _lastQuestionController.text);

    return newInfo;
  }

  @override
  Widget build(BuildContext context) {
    bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(top: 16.0, left: 24.0),
          child: GestureDetector(
            onTap: () {
              if (_currentPage == 0) {
                Navigator.pop(context);
              } else {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: Container(
              width: 60,
              height: 60,
              child: SvgPicture.asset(
                'assets/graphics/prof_erstellen_back_button.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            'Profil vervollständigen',
            style: TextStyle(
              color: Color(0xFF414254),
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
                showError = false;
              });
            },
            children: [
              _buildNameInputPage(),
              _buildGenderSelectionPage(),
              _buildDateInputPage(),
              _buildOptionPage(3),
              _buildOptionPage(4),
              _buildOptionPage(5),
              _buildOptionPage(6),
              _buildOptionPage(7),
              _buildOptionPage(8),
              _buildLastQuestionPage(),
            ],
          ),
          if (!isKeyboardVisible || _currentPage != 0) ...[
            Positioned(
              bottom: 80,
              right: 32,
              child: GestureDetector(
                onTap: _nextPage,
                child: Container(
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/graphics/prof_erstellen_weiter_button.svg',
                      width: 45,
                      height: 45,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _buildPageIndicators(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNameInputPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            questions[0],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Name eingeben',
              hintStyle: TextStyle(color: Color(0xFF979797)),
              border: InputBorder.none,
              filled: true,
              fillColor: Color(0xFFF7F7F7),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
          ),
          if (showError)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Hinweis: Bitte alle Felder ausfüllen',
                style: TextStyle(
                  color: Color(0xFF7D4666),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderSelectionPage() {
    List<Map<String, String>> genderOptions = [
      {
        'label': 'Männlich',
        'icon': 'assets/graphics/männlich_icon.svg',
      },
      {
        'label': 'Weiblich',
        'icon': 'assets/graphics/weiblich_icon.svg',
      },
      {
        'label': 'Weiteres',
        'icon': 'assets/graphics/weiteres_icon.svg',
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            questions[1],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20.0,
                mainAxisSpacing: 20.0,
                childAspectRatio: 1.2,
              ),
              itemCount: genderOptions.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedOptionIndexes[1] == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedOptionIndexes[1] = index;
                      showError = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFFDDF1EA) : Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(0),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black26,
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SvgPicture.asset(
                          genderOptions[index]['icon']!,
                          color: isSelected
                              ? Color(0xFF7D4666)
                              : Color(0xFF979797),
                          width: 50,
                          height: 50,
                        ),
                        SizedBox(height: 8),
                        Text(
                          genderOptions[index]['label']!,
                          style: TextStyle(
                            color: Color(0xFF414254),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (showError)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Hinweis: Bitte eine Option auswählen',
                style: TextStyle(
                  color: Color(0xFF7D4666),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateInputPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            questions[2],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          TextField(
            controller: _dateController,
            inputFormatters: [DateInputFormatter()],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'DD/MM/YYYY',
              hintStyle: TextStyle(color: Color(0xFF979797)),
              prefixIcon: Icon(
                Icons.calendar_today,
                color: Color(0xFF979797),
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Color(0xFFF7F7F7),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
          ),
          if (showError)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Hinweis: Bitte ein gültiges Datum eingeben',
                style: TextStyle(
                  color: Color(0xFF7D4666),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionPage(int questionIndex) {
    List<String> options = _getOptionsForQuestion(questionIndex);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            questions[questionIndex],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedOptionIndexes[questionIndex] == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedOptionIndexes[questionIndex] = index;
                      showError = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          isSelected
                              ? 'assets/graphics/profil_erstellen_MC_item_selected.svg'
                              : 'assets/graphics/profil_erstellen_MC_item_not_selected.svg',
                          width: 24,
                          height: 24,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            options[index],
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? Color(0xFF414254)
                                  : Color(0xFF98999D),
                              fontWeight: FontWeight.normal,
                              fontFamily: 'Inter',
                              height: 1.41,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (showError)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Hinweis: Bitte eine Option auswählen',
                style: TextStyle(
                  color: Color(0xFF7D4666),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLastQuestionPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            questions[9],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Was begeistert dich immer wieder an deinem Partner / deiner Partnerin?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Was stört dich vielleicht aktuell ein wenig?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Scrollbar(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: TextField(
                      controller: _lastQuestionController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: _isProcessingSpeech ? '' : 'Text eingeben...',
                        hintStyle: TextStyle(color: Color(0xFF979797)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                if (_isProcessingSpeech)
                  Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF7D4666)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onLongPressStart: (_) =>
                    _startRecording(_lastQuestionController),
                onLongPressEnd: (_) => _stopRecording(_lastQuestionController),
                child: IconButton(
                  icon: SvgPicture.asset(
                    'assets/graphics/voice_input_icon.svg',
                    color: _speechToTextService.isRecording &&
                            _speechToTextService.currentController ==
                                _lastQuestionController
                        ? Colors.red
                        : null,
                  ),
                  onPressed: () {}, // Disable normal press
                ),
              ),
              IconButton(
                icon: SvgPicture.asset('assets/graphics/send_message_icon.svg'),
                onPressed: () {
                  // Handle send message action
                },
              ),
            ],
          ),
          if (showError)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Hinweis: Bitte geben Sie eine Antwort ein',
                style: TextStyle(
                  color: Color(0xFF7D4666),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _startRecording(TextEditingController controller) async {
    await _speechToTextService.startRecording(controller);
    setState(() {
      _isProcessingSpeech = true;
    });
  }

  void _stopRecording(TextEditingController controller) async {
    await _speechToTextService.stopRecording();
    String? transcription = await _speechToTextService.transcribeAudio();
    if (transcription != null) {
      setState(() {
        controller.text = transcription;
      });
    }
    setState(() {
      _isProcessingSpeech = false;
    });
  }

  List<String> _getOptionsForQuestion(int questionIndex) {
    switch (questionIndex) {
      case 3:
        return [
          'Romantische Komödie',
          'Action-Abenteuer',
          'Mystery-Thriller',
          'Dokumentarfilm'
        ];
      case 4:
        return [
          'Löwen, die beschützend sind',
          'Papageien, die kommunikativ sind',
          'Füchse, die schlau und verspielt sind',
          'Elefanten, die liebevoll und gedächtnisstark sind'
        ];
      case 5:
      case 6:
        return [
          'Der Chefkoch, der die Hauptgerichte zubereitet',
          'Der Sous-Chef, der assistiert und experimentiert',
          'Der Geschmackstester, der die Qualität sicherstellt',
          'Der Organisator, der dafür sorgt, dass alles am richtigen Platz ist'
        ];
      case 7:
        return [
          'Wie ein Cheerleader, der anfeuert',
          'Wie ein Coach, der Lösungen bietet',
          'Wie ein stiller Unterstützer, der im Hintergrund hilft'
        ];
      case 8:
        return [
          'Hochmut, dem Anerkennung über alles wichtig in einer Beziehung',
          'Habgier, dem ein schöner Lifestyle gefällt für dich zu einer erfüllten Beziehung',
          'Wollust, denn Körperlichkeit spielt für dich eine große Rolle',
          'Zorn, weil du mit vollem Herz dabei bist',
          'Völlerei, weil deine Beziehung ohne Genuss für dich nicht geht',
          'Neid, weil du dir nur das Beste für dich und deinen Partner / deine Partnerin wünschst',
          'Trägheit, weil Gemütlichkeit und Liebe für dich zusammengehören'
        ];
      default:
        return [];
    }
  }

  List<Widget> _buildPageIndicators() {
    return List<Widget>.generate(questions.length, (int index) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 6.0),
        width: 40.0,
        height: 40.0,
        child: SvgPicture.asset(
          index <= _currentPage
              ? 'assets/graphics/leave_icon.svg'
              : 'assets/graphics/leave_icon_blass.svg',
        ),
      );
    });
  }
}
