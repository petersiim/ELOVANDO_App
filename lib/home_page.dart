import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'custom_app_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  final String userId;

  HomePage({required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _leavesController;
  late Animation<Offset> _leavesAnimation;
  late bool _flipHorizontally;
  late double _rotationAngle;
  late double _scaleFactor;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _initializeLeavesController();
    _setRandomTransformations();
    _leavesController.forward();
  }

  void _initializeLeavesController() {
    _leavesController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    );

    _leavesAnimation = Tween<Offset>(
      begin: Offset(0.1, 0), // Start just off the left side
      end: Offset(-0.1, 0), // End just off the right side
    ).animate(CurvedAnimation(
      parent: _leavesController,
      curve: Curves.linear,
    ));

    _leavesController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _setRandomTransformations();
          Future.delayed(Duration(seconds: random.nextInt(2)), () {
            _leavesController.forward(from: 0);
          });
        });
      }
    });
  }

  void _setRandomTransformations() {
    _flipHorizontally = random.nextBool();
    _rotationAngle = (random.nextDouble() - 0.5) * pi / 3; // Rotate between -60 to 60 degrees
    _scaleFactor = 0.8 + random.nextDouble() * 0.4; // Scale between 0.8 and 1.2
  }

  @override
  void dispose() {
    _leavesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: CustomAppBar(userId: widget.userId),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.hasError) {
            return Center(child: Text('Error loading user data'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String userName = userData['name'] ?? 'User';

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/graphics/home_screen_background_for_names_inkl_logo.png',
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName, // Use the user's name
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF414254),
                              fontFamily: 'Inter',
                            ),
                          ),
                          SizedBox(width: 140), // Adjust the width as needed
                          Text(
                            'Markus', // Placeholder name
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF414254),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/graphics/home_screen_love_session_starten_background_without_animation.png',
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        left: 30,
                        child: Text(
                          'Love Session starten',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF414254),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _leavesController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: _leavesAnimation.value * MediaQuery.of(context).size.width,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..scale(
                                    _flipHorizontally ? -_scaleFactor : _scaleFactor,
                                    _scaleFactor,
                                  )
                                  ..rotateZ(_rotationAngle),
                                child: SvgPicture.asset(
                                  'assets/graphics/home_love_session_starten_animation_graphic.svg',
                                  width: MediaQuery.of(context).size.width * 0.6,
                                  height: MediaQuery.of(context).size.height * 0.3,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOptionCard(
                      'Beziehungs-Input geben',
                      'assets/graphics/home_screen_white_heart.svg',
                      Color(0xFF7D4666),
                      Colors.white,
                    ),
                    _buildOptionCard(
                      'Love Session-Feedback geben',
                      'assets/graphics/home_screen_mint_star.svg',
                      Colors.white,
                      Color(0xFF414254),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/graphics/home_screen_heart_dialoge.svg',
                        width: 40,
                        height: 40,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Ihr habt bisher 5h in eure Beziehung investiert!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF414254),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionCard(String text, String iconPath, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 40,
              height: 40,
            ),
            SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
