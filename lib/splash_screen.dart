import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart'; // Import HomePage
import 'first_page.dart'; // Import FirstPage
import 'package:flutter_svg/flutter_svg.dart'; // Import for SVG support

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Minimum duration for the splash screen
    await Future.delayed(Duration(seconds: 1));

    // Check login status from Firebase Auth
    User? user = FirebaseAuth.instance.currentUser;

    // Additional delay to ensure the home screen is ready
    Future.delayed(Duration(seconds: 1), () {
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(userId: user.uid)), // Navigate to HomePage with user ID
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FirstPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF414143), // Set background color
      body: Center(
        child: SvgPicture.asset(
          'assets/graphics/logo_white_with_text.svg', // Path to your logo
          width: 200, // Adjust size as needed
          height: 200, // Adjust size as needed
        ),
      ),
    );
  }
}
