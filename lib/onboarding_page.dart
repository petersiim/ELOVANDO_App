import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingPage extends StatelessWidget {
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
          // Birds Icon
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3, // Adjust as needed
            left: MediaQuery.of(context).size.width * 0.5 - 100, // Adjust as needed
            child: Image.asset(
              'assets/graphics/birds_icon.png',
              width: 200, // Adjust width as needed
              height: 200, // Adjust height as needed
            ),
          ),
          // Text Field
          Positioned(
            top: MediaQuery.of(context).size.height * 0.5 + 25, // Adjust as needed
            width: 316, // specified width
            left: MediaQuery.of(context).size.width * 0.5 - 158, // Adjust as needed
            child: Text(
              'Mehr Zeit und\nRaum für eure Beziehung',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF414254),
              ),
            ),
          ),
          // Additional Text Field
          Positioned(
            top: MediaQuery.of(context).size.height * 0.6 + 25, // Adjust as needed
            width: 313.3, // specified width
            left: MediaQuery.of(context).size.width * 0.5 - 156.65, // Adjust as needed
            child: Text(
              'Schafft euch ein fixes, aber flexibles Format für eure Beziehungspflege',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: Color(0xFF414254),
              ),
            ),
          ),
          // Navigation Indicator
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.2 + 20, // Adjust as needed
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Navigation indicators with the second one selected
                Row(
                  children: [
                    Container(
                      width: 10.0,
                      height: 10.0,
                      decoration: BoxDecoration(
                        color: Color(0xFFDEDEDE), // Non-selected color
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.0),
                    Container(
                      width: 30.0,
                      height: 10.0,
                      decoration: BoxDecoration(
                        color: Color(0xFF7D4666), // Selected color
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    SizedBox(width: 4.0),
                    Row(
                      children: List.generate(5, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 2.0),
                          width: 10,
                          height: 10.0,
                          decoration: BoxDecoration(
                            color: Color(0xFFDEDEDE), // Non-selected color
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Button
          Positioned(
            bottom: 100, // Adjust position as needed
            left: 23,
            right: 23,
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
        ],
      ),
    );
  }
}
