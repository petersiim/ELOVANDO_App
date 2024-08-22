import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'kostenpflichtig_dialog.dart';
import 'partner_einladung_page.dart';
import 'complete_profile_page.dart';

class ProfilePage extends StatelessWidget {
  final String userId;
  ProfilePage({required this.userId});

  Future<Map<String, dynamic>> _fetchUserData() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};
  
    // Ensure profileCompletion exists in the user data
    userData['profileCompletion'] = userData['profileCompletion'] ?? {};

    return userData;
  }

  bool _isProfileComplete(Map<String, bool> completedQuestions) {
    return completedQuestions.values.every((value) => value);
  }

  Future<Map<String, bool>> _fetchCompletedQuestions() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
    if (data != null && data.containsKey('profileCompletion')) {
      return Map<String, bool>.from(data['profileCompletion']);
    }
    return {};
  }

  int _calculateAge(String? birthdate) {
    if (birthdate == null) return 0;
    List<String> parts = birthdate.split('/');
    if (parts.length != 3) return 0;
    int day = int.tryParse(parts[0]) ?? 1;
    int month = int.tryParse(parts[1]) ?? 1;
    int year = int.tryParse(parts[2]) ?? DateTime.now().year;

    DateTime birthDate = DateTime(year, month, day);
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!;
          final userName = userData['name'] as String? ?? 'Unknown';
          final userImageUrl = userData['profileImageUrl'] as String? ?? '';
          final userBirthdate = userData['birthdate'] as String?;
          final userAge = _calculateAge(userBirthdate);
          final hasInvitedPartner = userData['invitedUsers'] != null &&
              (userData['invitedUsers'] as List).isNotEmpty;
          final completedQuestions =
              Map<String, bool>.from(userData['profileCompletion'] ?? {});

          return SingleChildScrollView(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40.0),
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: userImageUrl.isNotEmpty
                            ? NetworkImage(userImageUrl)
                            : null,
                        child: userImageUrl.isEmpty
                            ? Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        '$userName${userAge > 0 ? ', $userAge' : ''}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Medium',
                          color: Color(0xFF414254),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    // ... Rest of the code remains the same
                  ],
                ),
                Positioned(
                  top: 38.0,
                  left: 16.0,
                  child: IconButton(
                    icon: SvgPicture.asset(
                      'assets/graphics/profile_screen_X_icon.svg',
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ... Rest of the code remains the same
}
