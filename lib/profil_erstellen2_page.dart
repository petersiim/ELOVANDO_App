import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'partner_einladung_page.dart';
import 'firestore_service.dart';

class ProfilErstellen2Page extends StatefulWidget {
  @override
  _ProfilErstellen2PageState createState() => _ProfilErstellen2PageState();
}

class _ProfilErstellen2PageState extends State<ProfilErstellen2Page> {
  final FirestoreService _firestoreService = FirestoreService();

  PageController _pageController = PageController();
  int _currentPage = 0;
  List<int> selectedOptionIndexes = List<int>.generate(6, (index) => -1);
  bool showError = false;
  TextEditingController _lastQuestionController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      showError = false;
    });
  }

  bool _validateCurrentPage() {
    // Page 7 doesn't require option selection validation
    if (_currentPage == 6) {
      return true;
    }

    if (selectedOptionIndexes[_currentPage] == -1) {
      setState(() {
        showError = true;
      });
      return false;
    }
    return true;
  }

  void _nextPage() async {
    FocusScope.of(context).unfocus(); // This will dismiss the keyboard

    bool isValid = _validateCurrentPage();

    if (isValid) {
      if (_currentPage < 6) {
        // Store the selected option for the current page in Firestore
        await _firestoreService.updateUserProfile({
          'question${_currentPage + 1}': _getAnswerText(_currentPage, selectedOptionIndexes[_currentPage]),
        });

        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Store the answer for the last question
        await _firestoreService.updateUserProfile({
          'question7': _lastQuestionController.text,
        });

        // Mark profile step 2 completed
        await _firestoreService.markProfileStepCompleted('profileStep2Completed');
        // Navigate to PartnerEinladungPage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PartnerEinladungPage()),
        );
      }
    }
  }

  void _skipPage() async {
    // Mark profile step 2 completed
    await _firestoreService.markProfileStepCompleted('profileStep2Completed');
    // Navigate to PartnerEinladungPage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PartnerEinladungPage()),
    );
  }

  String _getAnswerText(int questionIndex, int answerIndex) {
    List<List<String>> options = [
      ['Romantische Komödie', 'Action-Abenteuer', 'Mystery-Thriller', 'Dokumentarfilm'],
      ['Löwen, die beschützend sind', 'Papageien, die kommunikativ sind', 'Füchse, die schlau und verspielt sind', 'Elefanten, die liebevoll und gedächtnisstark sind'],
      ['Der Chefkoch, der die Hauptgerichte zubereitet', 'Der Sous-Chef, der assistiert und experimentiert', 'Der Geschmackstester, der die Qualität sicherstellt', 'Der Organisator, der dafür sorgt, dass alles am richtigen Platz ist'],
      ['Der Chefkoch, der die Hauptgerichte zubereitet', 'Der Sous-Chef, der assistiert und experimentiert', 'Der Geschmackstester, der die Qualität sicherstellt', 'Der Organisator, der dafür sorgt, dass alles am richtigen Platz ist'],
      ['Wie ein Cheerleader, der anfeuert', 'Wie ein Coach, der Lösungen bietet', 'Wie ein stiller Unterstützer, der im Hintergrund hilft'],
      ['Hochmut, dem Anerkennung über alles wichtig in einer Beziehung', 'Habgier, dem ein schöner Lifestyle gefällt für dich zu einer erfüllten Beziehung', 'Wollust, denn Körperlichkeit spielt für dich eine große Rolle', 'Zorn, weil du mit vollem Herz dabei bist', 'Völlerei, weil deine Beziehung ohne Genuss für dich nicht geht', 'Neid, weil du dir nur das Beste für dich und deinen Partner / deine Partnerin wünschst', 'Trägheit, weil Gemütlichkeit und Liebe für dich zusammengehören']
    ];

    return options[questionIndex][answerIndex];
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
            'Profil erstellen',
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
        children: <Widget>[
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _buildPage1(),
              _buildPage2(),
              _buildPage3(),
              _buildPage4(),
              _buildPage5(),
              _buildPage6(),
              _buildPage7(),
            ],
          ),
          if (!isKeyboardVisible || _currentPage != 6) ...[
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildPageIndicators(),
              ),
            ),
            // Skip Button
            Positioned(
              bottom: 100,
              left: 32,
              child: GestureDetector(
                onTap: _skipPage,
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: Color(0xFF414254),
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Inter',
                    height: 1.41,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPage1() {
    List<String> options = [
      'Romantische Komödie',
      'Action-Abenteuer',
      'Mystery-Thriller',
      'Dokumentarfilm',
    ];

    return _buildOptionPage(
      'Welche Art von Film repräsentiert am besten eure Beziehung?',
      options,
      0,
    );
  }

  Widget _buildPage2() {
    List<String> options = [
      'Löwen, die beschützend sind',
      'Papageien, die kommunikativ sind',
      'Füchse, die schlau und verspielt sind',
      'Elefanten, die liebevoll und gedächtnisstark sind',
    ];

    return _buildOptionPage(
      'Welches Tierduo beschreibt eure Partnerschaft am besten?',
      options,
      1,
    );
  }

  Widget _buildPage3() {
    List<String> options = [
      'Der Chefkoch, der die Hauptgerichte zubereitet',
      'Der Sous-Chef, der assistiert und experimentiert',
      'Der Geschmackstester, der die Qualität sicherstellt',
      'Der Organisator, der dafür sorgt, dass alles am richtigen Platz ist',
    ];

    return _buildOptionPage(
      'Wenn ihr zusammen kochen würdet, welche Rolle übernimmst du?',
      options,
      2,
    );
  }

  Widget _buildPage4() {
    List<String> options = [
      'Der Chefkoch, der die Hauptgerichte zubereitet',
      'Der Sous-Chef, der assistiert und experimentiert',
      'Der Geschmackstester, der die Qualität sicherstellt',
      'Der Organisator, der dafür sorgt, dass alles am richtigen Platz ist',
    ];

    return _buildOptionPage(
      'Welche Rolle würde dein Partner übernehmen?',
      options,
      3,
    );
  }

  Widget _buildPage5() {
    List<String> options = [
      'Wie ein Cheerleader, der anfeuert',
      'Wie ein Coach, der Lösungen bietet',
      'Wie ein stiller Unterstützer, der im Hintergrund hilft',
    ];

    return _buildOptionPage(
      'Wie unterstützt du deinen Partner in einer schwierigen Situation?',
      options,
      4,
    );
  }

  Widget _buildPage6() {
    List<String> options = [
      'Hochmut, dem Anerkennung über alles wichtig in einer Beziehung',
      'Habgier, dem ein schöner Lifestyle gefällt für dich zu einer erfüllten Beziehung',
      'Wollust, denn Körperlichkeit spielt für dich eine große Rolle',
      'Zorn, weil du mit vollem Herz dabei bist',
      'Völlerei, weil deine Beziehung ohne Genuss für dich nicht geht',
      'Neid, weil du dir nur das Beste für dich und deinen Partner / deine Partnerin wünschst',
      'Trägheit, weil Gemütlichkeit und Liebe für dich zusammengehören',
    ];

    return _buildOptionPage(
      'Für welche der sieben Todsünden bist du am ehesten empfänglich?',
      options,
      5,
    );
  }

  Widget _buildPage7() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Erzähle uns doch noch etwas mehr über eure Beziehung. Wie läuft es?',
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
            height: 150, // Set a fixed height for the text field container
            decoration: BoxDecoration(
              color: Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Scrollbar(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: TextField(
                  controller: _lastQuestionController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Text eingeben...',
                    hintStyle: TextStyle(color: Color(0xFF979797)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: SvgPicture.asset('assets/graphics/voice_input_icon.svg'),
                onPressed: () {
                  // Handle voice input action
                },
              ),
              IconButton(
                icon: SvgPicture.asset('assets/graphics/send_message_icon.svg'),
                onPressed: () {
                  // Handle send message action
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionPage(String question, List<String> options, int pageIndex) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            question,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          Column(
            children: List.generate(options.length, (index) {
              bool isSelected = selectedOptionIndexes[pageIndex] == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedOptionIndexes[pageIndex] = index;
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
            }),
          ),
          if (showError && selectedOptionIndexes[pageIndex] == -1)
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

  List<Widget> _buildPageIndicators() {
    return List<Widget>.generate(7, (int index) {
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
