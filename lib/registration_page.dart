import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'bez_prof_erstellen.dart';
import 'anmelden_page.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _invitationCodeController =
      TextEditingController();
  bool _isPasswordVisible = false;
  String _errorMessage = '';

  Future<void> _register() async {
    setState(() {
      _errorMessage = '';
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _checkAndProcessInvitationCode(userCredential.user!);

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Process invitation code
      await _processInvitationCode(
          userCredential.user!, _invitationCodeController.text.trim());
      // Show the verification dialog
      _showVerificationDialog(userCredential.user!);

      // Start checking for email verification in the background
      _checkEmailVerified(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Registrierung fehlgeschlagen: ${e.message}';
      });
    }
  }

  Future<void> _checkAndProcessInvitationCode(User user) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedInvitationCode = prefs.getString('pending_invitation_code');

    if (storedInvitationCode != null) {
      await _processInvitationCode(user, storedInvitationCode);
      // Clear the stored invitation code
      await prefs.remove('pending_invitation_code');
    }

    // Process the manually entered invitation code if it exists
    String manualInvitationCode = _invitationCodeController.text.trim();
    if (manualInvitationCode.isNotEmpty) {
      await _processInvitationCode(user, manualInvitationCode);
    }
  }

  Future<void> _processInvitationCode(User user, String invitationCode) async {
    if (invitationCode.isNotEmpty) {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('invitationCode', isEqualTo: invitationCode)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        String inviterId = query.docs.first.id;

        // Link the current user to the inviter
        await _firestore.collection('users').doc(user.uid).update({
          'invitedBy': inviterId,
        });

        // Update the inviter's document
        await _firestore.collection('users').doc(inviterId).update({
          'invitedUsers': FieldValue.arrayUnion([user.uid]),
        });
      }
    }
  }

  void _checkEmailVerified(User user) async {
    bool emailVerified = false;
    while (!emailVerified) {
      await Future.delayed(Duration(seconds: 2));
      await user.reload();
      User? updatedUser = _auth.currentUser;
      emailVerified = updatedUser?.emailVerified ?? false;
      if (emailVerified) {
        // Add user information to Firestore after email is verified
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': Timestamp.now(),
          'emailVerified': true,
        }, SetOptions(merge: true));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BezProfErstellen()),
        );
      }
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
                    borderRadius: BorderRadius.circular(8.0),
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
                        content: Text(
                            'Die Bestätigungs-E-Mail wurde erneut gesendet.'),
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

  Future<void> _signInWithGoogle() async {
  setState(() {
    _errorMessage = '';
  });

  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await _auth.signInWithCredential(credential);
    
    // Check if the user already exists in Firestore
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
    
    if (userDoc.exists) {
      // User already exists, navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(userId: userCredential.user!.uid)),
      );
    } else {
      // New user, create account and navigate to profile creation
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': userCredential.user!.email,
        'createdAt': Timestamp.now(),
        'emailVerified': true,
      }, SetOptions(merge: true));
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BezProfErstellen()),
      );
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Ein unerwarteter Fehler ist aufgetreten: ${e.toString()}';
    });
  }
}

  Future<void> _signInWithFacebook() async {
    setState(() {
      _errorMessage = 'This does not work yet';
    });
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _errorMessage = 'This does not work yet';
    });
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
                SizedBox(height: 80),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Registrieren',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF414254),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(0xFFF7F7F7),
                    hintText: 'yourusername@domain.com',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      color: Color(0xFFB2B2B2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(0xFFF7F7F7),
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      color: Color(0xFFB2B2B2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      child: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Color(0xFFB2B2B2),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _invitationCodeController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(0xFFF7F7F7),
                    hintText: 'Invitation Code (optional)',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      color: Color(0xFFB2B2B2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                      onTap: _signInWithGoogle,
                      child: Image.asset(
                        'assets/graphics/google_icon.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                    SizedBox(width: 20),
                    GestureDetector(
                      onTap: _signInWithFacebook,
                      child: Image.asset(
                        'assets/graphics/facebook_icon.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                    SizedBox(width: 20),
                    GestureDetector(
                      onTap: _signInWithApple,
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
                        color: Color(0xFF757575),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                      ),
                      children: [
                        TextSpan(
                          text: 'Anmelden',
                          style: TextStyle(
                            color: Color(0xFF7FCCB1),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.normal,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AnmeldenPage()),
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
