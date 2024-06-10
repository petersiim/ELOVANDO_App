import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfilErstellen2Page extends StatefulWidget {
  @override
  _ProfilErstellen2PageState createState() => _ProfilErstellen2PageState();
}

class _ProfilErstellen2PageState extends State<ProfilErstellen2Page> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildPage1(),
      _buildPage2(),
      _buildPage3(),
      _buildPage4(),
      _buildPage5(),
      _buildPage6(),
      _buildPage7(),
    ];
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  bool _validateCurrentPage() {
    // Add validation logic for each page if needed
    return true;
  }

  Widget _buildPage1() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Welche Art von Film repräsentiert am besten eure Beziehung?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          // Add your radio buttons or selection options here
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Welches Tierduo beschreibt eure Partnerschaft am besten?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          // Add your radio buttons or selection options here
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Wenn ihr zusammen kochen würdet, welche Rolle übernimmst du?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          // Add your radio buttons or selection options here
        ],
      ),
    );
  }

  Widget _buildPage4() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Welche Rolle würde dein Partner übernehmen?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          // Add your radio buttons or selection options here
        ],
      ),
    );
  }

  Widget _buildPage5() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Wie unterstützt du deinen Partner in einer schwierigen Situation?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          // Add your radio buttons or selection options here
        ],
      ),
    );
  }

  Widget _buildPage6() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 34.0, vertical: 52.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Für welche der sieben Todsünden bist du am ehesten empfänglich?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          SizedBox(height: 44),
          // Add your radio buttons or selection options here
        ],
      ),
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
          SizedBox(height: 44),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter text',
              hintStyle: TextStyle(color: Color(0xFF979797)),
              border: InputBorder.none,
              filled: true,
              fillColor: Color(0xFFF7F7F7),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
          ),
          // Add more fields or options as needed
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

  void _nextPage() {
    FocusScope.of(context).unfocus(); // This will dismiss the keyboard

    bool isValid = _validateCurrentPage();

    if (isValid) {
      if (_currentPage < 6) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Handle profile creation or navigation to the next page
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            children: _pages,
          ),
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
// Skip Button
          Positioned(
            bottom: 100,
            left: 32,
            child: GestureDetector(
              onTap: _nextPage,
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
      ),
    );
  }
}
