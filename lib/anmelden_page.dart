import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bez_prof_erstellen.dart'; // Import the BezProfErstellen page
import 'registration_page.dart'; // Import the RegistrationPage

class AnmeldenPage extends StatefulWidget {
  @override
  _AnmeldenPageState createState() => _AnmeldenPageState();
}

class _AnmeldenPageState extends State<AnmeldenPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String _errorMessage = '';

  void _login() async {
    setState(() {
      _errorMessage = '';
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user!.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BezProfErstellen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Bitte überprüfe deine E-Mail-Adresse, um fortzufahren.';
        });
        _showVerificationDialog(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Anmeldung fehlgeschlagen: ${e.message}';
      });
    }
  }

  void _showVerificationDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Überprüfe deine E-Mail',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bitte überprüfe deine E-Mail und bestätige dein Konto.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF414254),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7D4666),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Erneut senden',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
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
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7D4666),
                ),
              ),
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
                    'Anmelden',
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
                    onPressed: _login,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Anmelden',
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
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Noch keinen Account? ',
                      style: TextStyle(
                        color: Color(0xFF757575), // The grey color for the first part
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                      ),
                      children: [
                        TextSpan(
                          text: 'Registrieren',
                          style: TextStyle(
                            color: Color(0xFF7FCCB1), // The green color for the clickable part
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RegistrationPage()),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
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
