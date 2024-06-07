import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'profil_erstellen_page.dart'; // Import the new ProfilErstellenPage

class BezProfErstellen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Background image
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/graphics/onboarding_bg.svg',
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25 + 50,
            left: MediaQuery.of(context).size.width * 0.5 - 50,
            child: Image.asset(
              'assets/graphics/bez_prof_erstellen_icon.png',
              width: 100,
              height: 100,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Beziehungsprofil erstellen',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF414254),
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Hallo und schön, dass du hier bist! '
                    'Beantworte bitte einige Fragen, damit wir die '
                    'Love-Sessions perfekt auf euch abstimmen können. '
                    '\nDein Partner / deine Partnerin wird später dasselbe tun.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: Color(0xFF414254),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Button
          Positioned(
            bottom: 100,
            left: 23,
            right: 23,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilErstellenPage()),
                );
              },
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
                      "Jetzt Profil erstellen!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        height: 1.41,
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
