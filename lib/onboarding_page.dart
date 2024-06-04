import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  int currentIndex = 1; // Start at the second page
  final List<String> icons = [
    'assets/graphics/birds_icon.png',
    'assets/graphics/holding-hands_icon.png',
    'assets/graphics/ideas_wiss_an_icon.png',
    'assets/graphics/therapy-chat-icon.png',
    'assets/graphics/daten-shield-icon.png',
    'assets/graphics/love-session-forest-icon.png',
  ];

  final List<String> bigTexts = [
    'Mehr Zeit und\nRaum für eure Beziehung',
    'Mehr Empathie\nund Wertschätzung',
    'Wissenschaftlicher Ansatz',
    'Kostenloser Therapeuten-Chat',
    'Deine Daten\nin sicheren Händen',
    'Fünf kostenlose\nLove-Sessions',
  ];

  final List<String> smallTexts = [
    'Schafft euch ein fixes, aber flexibles Format für eure Beziehungspflege',
    'Schafft ein neues Verständnis mit den personalsierten Descalate Love Sessions',
    'Weniger Streit und eine glücklichere Beziehung durch die smarte, wissenschaftsbasierte Descalate-Methode.',
    'Chatte mit unserem kostenlosen AI Paar-Therapeuten.',
    'Wir stellen sicher, dass eure Beziehungsdaten sicher und verschlüsselt sind, sodass niemand darauf zugreifen kann.',
    'Testet die Descalate Love-Sessions unverbindlich fünfmal und entscheidet euch erst dann für eines unserer Abo-Modelle.',
  ];

  final List<AnimationController> _leavesControllers = [];
  final List<Animation<Offset>> _leavesAnimations = [];
  final List<bool> _flipHorizontally = [];
  final List<double> _rotationAngles = [];
  final List<double> _scaleFactors = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _initializeLeavesControllers();
    _startLeavesAnimations();
  }

  void _initializeLeavesControllers() {
    for (int i = 0; i < 2; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 5),
      );

      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _setRandomTransformations(i);
            Future.delayed(Duration(seconds: random.nextInt(2)), () {
              controller.forward(from: 0);
            });
          });
        }
      });

      _leavesControllers.add(controller);
      _leavesAnimations.add(Tween<Offset>(
        begin: Offset(1, 0),
        end: Offset(-1, 0),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      )));

      _setRandomTransformations(i);
    }
  }

  void _setRandomTransformations(int index) {
    if (_flipHorizontally.length <= index) {
      _flipHorizontally.add(random.nextBool());
      _rotationAngles.add((random.nextDouble() - 0.5) * pi / 3); // Rotate between -60 to 60 degrees
      _scaleFactors.add(0.8 + random.nextDouble() * 0.4); // Scale between 0.8 and 1.2
    } else {
      _flipHorizontally[index] = random.nextBool();
      _rotationAngles[index] = (random.nextDouble() - 0.5) * pi / 3;
      _scaleFactors[index] = 0.9 + random.nextDouble() * 0.5;
    }
  }

  void _startLeavesAnimations() {
    for (int i = 0; i < _leavesControllers.length; i++) {
      Future.delayed(Duration(milliseconds: random.nextInt(1000)), () {
        _leavesControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _leavesControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void nextSet() {
    setState(() {
      currentIndex = (currentIndex + 1) % icons.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Background image
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/graphics/onboarding_bg.svg',
              fit: BoxFit.cover,
            ),
          ),
          // Bottom SVG
          Positioned(
            bottom: -18,
            left: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/graphics/onboarding_bg_bottom.svg',
              fit: BoxFit.contain,
            ),
          ),
          // Animated SVG leaves
          for (int i = 0; i < _leavesControllers.length; i++)
            Positioned(
              top: MediaQuery.of(context).size.height * (0.05 + i * 0.1) - 40, // Different positions for different sets of leaves
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _leavesControllers[i],
                builder: (context, child) {
                  return Transform.translate(
                    offset: _leavesAnimations[i].value * MediaQuery.of(context).size.width,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..scale(_flipHorizontally[i] ? -_scaleFactors[i] : _scaleFactors[i], _scaleFactors[i])
                        ..rotateZ(_rotationAngles[i]),
                      child: SvgPicture.asset(
                        'assets/graphics/onboarding_leaves.svg',
                        width: MediaQuery.of(context).size.width * 2, // Adjust size as needed
                        height: MediaQuery.of(context).size.height * 0.4, // Adjust size as needed
                      ),
                    ),
                  );
                },
              ),
            ),
          // Icon
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25, // Adjusted up
            left: MediaQuery.of(context).size.width * 0.5 - 100, // Adjust as needed
            child: Image.asset(
              icons[currentIndex],
              width: 200, // Adjust width as needed
              height: 200, // Adjust height as needed
            ),
          ),
          // Big Text
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45 + 30, // Adjusted up
            width: 316, // specified width
            left: MediaQuery.of(context).size.width * 0.5 - 158, // Adjust as needed
            child: Text(
              bigTexts[currentIndex],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF414254),
              ),
            ),
          ),
          // Small Text
          Positioned(
            top: MediaQuery.of(context).size.height * 0.55 + 30, // Adjusted up
            width: 313.3, // specified width
            left: MediaQuery.of(context).size.width * 0.5 - 156.65, // Adjust as needed
            child: Text(
              smallTexts[currentIndex],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: Color(0xFF414254),
              ),
            ),
          ),
          // Navigation Indicator
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.25 - 20, // Adjusted up
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    for (int i = 0; i < icons.length; i++)
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 2.0),
                        width: i == currentIndex ? 30.0 : 10.0,
                        height: 10.0,
                        decoration: BoxDecoration(
                          color: i == currentIndex ? Color(0xFF7D4666) : Color(0xFFDEDEDE), // Selected and non-selected color
                          borderRadius: i == currentIndex ? BorderRadius.circular(6.0) : BorderRadius.circular(5.0),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Button
          Positioned(
            bottom: 100, // Position remains the same
            left: 23,
            right: 23,
            child: GestureDetector(
              onTap: nextSet,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Color(0xFF7D4666), // Primary color
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Weiter",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        height: 1.41, // 24px line height / 17px font size
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}