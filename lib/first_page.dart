import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2), // Increase duration to 1.5 seconds
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.addListener(() {
      setState(() {
        _opacity = _controller.value;
      });
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: <Widget>[
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/graphics/bg_forest.jpg', // Ensure the image path is correct
                    fit: BoxFit.cover,
                  ),
                ),
                // Centered SVG logo with fade-in effect
                Positioned(
                  top: constraints.maxHeight * 0.31, // Adjust the top position as needed
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _opacity,
                    duration: Duration(seconds: 2), // Match the opacity animation duration
                    child: SvgPicture.asset(
                      'assets/graphics/logo_white.svg',
                      width: constraints.maxWidth * 0.4, // Adjust size as needed
                      height: constraints.maxHeight * 0.15, // Adjust size as needed
                    ),
                  ),
                ),
                // Bottom part with slide animation
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 70.0), // Add padding: left, top, right, bottom
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8), // Slightly transparent white
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(24.0),
                              topRight: Radius.circular(24.0),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Willkommen!',
                                style: TextStyle(
                                  fontFamily: 'Inter', // Specify the font family
                                  fontSize: 48.0, // Size 48
                                  fontWeight: FontWeight.bold, // Bold
                                  color: Color(0xFF414254), // Color #414254
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                'Wir freuen uns, dich auf deiner Reise zu einer stärkeren Beziehung zu begleiten.',
                                style: TextStyle(
                                  fontFamily: 'Inter', // Specify the font family
                                  fontSize: 17.0, // Size 17
                                  fontWeight: FontWeight.normal, // Regular weight
                                  color: Color(0xFF414254), // Color #414254
                                ),
                              ),
                              SizedBox(height: 32.0),
                              Row(
                                children: <Widget>[
                                  // Selected indicator
                                  Container(
                                    width: 30.0,
                                    height: 10.0,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF7D4666), // Selected color
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                  ),
                                  SizedBox(width: 4.0),
                                  // Non-selected indicators
                                  Row(
                                    children: List.generate(3, (index) {
                                      return Container(
                                        margin: EdgeInsets.symmetric(horizontal: 2.0),
                                        width: 10,
                                        height: 10.0,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF414254), // Non-selected color
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }),
                                  ),
                                  Spacer(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 38.0,
                          right: 52.0,
                          child: GestureDetector(
                            onTap: () {
                              // Handle navigation action
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF414254), // Correct color
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Gradient overlay with 20% opacity covering entire screen
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF22577A).withOpacity(0.2), // Top color with 20% opacity
                          Color(0xFFF9AC36).withOpacity(0.2), // Bottom color with 20% opacity
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
