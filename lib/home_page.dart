import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'custom_app_bar.dart';

class HomePage extends StatefulWidget {
  final String userId;

  HomePage({required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late Future<DocumentSnapshot> userFuture;

  final List<AnimationController> _leavesControllers = [];
  final List<Animation<Offset>> _leavesAnimations = [];
  final List<bool> _flipHorizontally = [];
  final List<double> _rotationAngles = [];
  final List<double> _scaleFactors = [];
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    userFuture = FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    _initializeLeavesControllers();
    _startLeavesAnimations();
  }

  void _initializeLeavesControllers() {
    for (int i = 0; i < 3; i++) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: CustomAppBar(userId: widget.userId),
      body: FutureBuilder<DocumentSnapshot>(
        future: userFuture,
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
                        child: Stack(
                          children: List.generate(_leavesControllers.length, (index) {
                            return AnimatedBuilder(
                              animation: _leavesControllers[index],
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: _leavesAnimations[index].value * MediaQuery.of(context).size.width,
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..scale(
                                        _flipHorizontally[index] ? -_scaleFactors[index] : _scaleFactors[index],
                                        _scaleFactors[index],
                                      )
                                      ..rotateZ(_rotationAngles[index]),
                                    child: SvgPicture.asset(
                                      'assets/graphics/home_love_session_starten_animation_graphic.svg',
                                      width: MediaQuery.of(context).size.width * 0.6,
                                      height: MediaQuery.of(context).size.height * 0.3,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
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
