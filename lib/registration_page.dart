import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bez_prof_erstellen.dart'; // Import the BezProfErstellen page

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String _errorMessage = '';

  void _register() async {
    setState(() {
      _errorMessage = '';
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Store user information in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        // Add more fields if needed
      });

      // Show the verification dialog
      _showVerificationDialog(userCredential.user!);

      // Start checking for email verification in the background
      _checkEmailVerified(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      // Handle registration error
      print("Error: $e");
      setState(() {
        _errorMessage = 'Registrierung fehlgeschlagen: ${e.message}';
      });
    }
  }

  void _checkEmailVerified(User user) async {
    Future.doWhile(() async {
      await Future.delayed(Duration(seconds: 2));
      await user.reload();
      if (user.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BezProfErstellen()),
        );
        return false; // Stop the loop
      }
      return true; // Continue the loop
    });
  }

  void _showVerificationDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Überprüfe deine E-Mail'),
          content: Text('Bitte überprüfe deine E-Mail und bestätige dein Konto.'),
          actions: <Widget>[
            TextButton(
              child: Text('Erneut senden'),
              onPressed: () async {
                try {
                  await user.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Die Bestätigungs-E-Mail wurde erneut gesendet.'),
                    ),
                  );
                } catch (e) {
                  print("Error: $e");
                }
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 80), // Add some space at the top
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Registrieren',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF414254), // Color from the image
                    ),
                  ),
                ),
                SizedBox(height: 40), // Add space before the text fields
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(0xFFF7F7F7), // Background color from the image
                    hintText: 'yourusername@domain.com',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      color: Color(0xFFB2B2B2), // Text color from the image
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    border: InputBorder.none, // No border
                    filled: true,
                    fillColor: Color(0xFFF7F7F7), // Background color
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      color: Color(0xFFB2B2B2), // Text color from the image
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      child: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Color(0xFFB2B2B2), // Icon color matching text color
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7D4666),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: _register,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Registrieren',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Handle Google sign-in
                      },
                      child: Image.asset(
                        'assets/graphics/google_icon.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                    SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        // Handle Facebook sign-in
                      },
                      child: Image.asset(
                        'assets/graphics/facebook_icon.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                    SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        // Handle Apple sign-in
                      },
                      child: Image.asset(
                        'assets/graphics/apple_icon.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Sie haben ein Konto? ',
                      style: TextStyle(
                        color: Color(0xFF757575), // The grey color for the first part
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                      ),
                      children: [
                        TextSpan(
                          text: 'Anmelden',
                          style: TextStyle(
                            color: Color(0xFF7FCCB1), // The green color for the clickable part
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // Handle navigation to login
                            },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
