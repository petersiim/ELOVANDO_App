import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'custom_app_bar.dart';

class HomePage extends StatelessWidget {
  final String userId;

  HomePage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: CustomAppBar(userId: userId),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: SvgPicture.asset(
                      'assets/graphics/home_screen_background_for_names_inkl_logo.svg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daniela', // Replace with actual user name
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF414254),
                            fontFamily: 'Inter',
                          ),
                        ),
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/graphics/home_screen_love_session_starten_background_without_animation.svg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                    ListTile(
                      title: Text(
                        'Love Session starten',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF414254),
                          fontFamily: 'Inter',
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward, color: Color(0xFF414254)),
                      onTap: () {
                        // Handle onTap
                      },
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
        ),
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
            SizedBox(height: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                fontWeight: FontWeight.bold,
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
