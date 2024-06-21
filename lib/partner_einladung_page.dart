import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'custom_app_bar.dart';
import 'firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'invitation_dialog.dart'; // Import the new dialog
import 'home_page.dart'; // Import the Home Page

class PartnerEinladungPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: CustomAppBar(userId: userId),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Container(
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -80,
                    child: SvgPicture.asset(
                      'assets/graphics/anonymus_icon_with_plus.svg',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.transparent,
                    child: FutureBuilder<String>(
                      future: _fetchUserImageUrl(userId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey,
                          );
                        }
                        return CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(snapshot.data!),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Partner-Einladung',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF414254),
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Lass uns jetzt noch deinen Partner überzeugen, damit ihr gemeinsam ELOVANDO für eure Beziehung nutzen könnt, denn unsere Love Sessions könnt ihr nur gemeinsam durchführen. Sende deinem Partner eine Einladung, um die ELOVANDO-App zu nutzen.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Color(0xFF414254),
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                showInvitationDialog(context); // Show the dialog
              },
              icon: Icon(Icons.share),
              label: Text('Partner-Einladung'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7D4666), // Background color
                foregroundColor: Colors.white, // Text color
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size(double.infinity, 56), // Adjust the width of the button
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage(userId: userId)),
                );
              },
              child: Text(
                'Skip',
                style: TextStyle(
                  color: Color(0xFF7FCCB1),
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _fetchUserImageUrl(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return userDoc['profileImageUrl'];
  }
}
