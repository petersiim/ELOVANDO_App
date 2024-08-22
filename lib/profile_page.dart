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

    Map<String, dynamic> userData =
        userDoc.data() as Map<String, dynamic>? ?? {};

    // Ensure profileCompletion exists in the user data
    userData['profileCompletion'] = userData['profileCompletion'] ?? {};

    return userData;
  }

  

  int _calculateAge(String? birthdate) {
    if (birthdate == null) return 0;
    List<String> parts = birthdate.split('/');
    if (parts.length != 3) return 0;
    int day = int.tryParse(parts[0]) ?? 1;
    int month = int.tryParse(parts[1]) ?? 1;
    int year = int.tryParse(parts[2]) ?? DateTime.now().year;
    print(userId);
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading user data'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('No user data found'));
          }

          final userData = snapshot.data!;
          final userName = userData['name'] as String? ?? 'User';
          final userImageUrl = userData['profileImageUrl'] as String?;
          final userBirthdate = userData['birthdate'] as String?;
          final userAge = _calculateAge(userBirthdate);
          final hasInvitedPartner = userData['invitedUsers'] != null &&
              (userData['invitedUsers'] as List).isNotEmpty;
          final completedQuestions =
              Map<String, bool>.from(userData['profileCompletion'] ?? {});
          final isProfileCompleted =
              userData['isProfileCompleted'] as bool? ?? false;

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
                        backgroundImage: userImageUrl != null
                            ? NetworkImage(userImageUrl)
                            : null,
                        child: userImageUrl == null
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
                    if (!isProfileCompleted)
                      _buildCompleteProfileBox(
                          context, userData, completedQuestions),
                    if (!hasInvitedPartner) ...[
                      SizedBox(height: 20),
                      _buildInvitePartnerButton(context),
                    ],
                    SizedBox(height: 20),
                    Container(
                      height: 1.0,
                      color: Color(0xFFDEDEDE),
                    ),
                    Container(
                      color: Color(0xFFF7F7F7),
                      child: Column(
                        children: [
                          SizedBox(height: 20),
                          _buildMenuItem(context, 'Einstellungen',
                              'assets/graphics/profile_settings_icon.svg'),
                          _buildMenuItem(context, 'Datenschutz',
                              'assets/graphics/profile_datenschutz_icon.svg'),
                          _buildMenuItem(context, 'Über uns',
                              'assets/graphics/profile_ueberuns_icon.svg'),
                          SizedBox(height: 20),
                          _buildUpgradeBox(context),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 38.0,
                  left: 16.0,
                  child: IconButton(
                    icon: SvgPicture.asset(
                        'assets/graphics/profile_screen_X_icon.svg'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompleteProfileBox(BuildContext context,
      Map<String, dynamic> userData, Map<String, bool> completedQuestions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF7D4666),
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    value: completedQuestions.values.where((v) => v).length /
                        completedQuestions.length,
                    strokeWidth: 6.0,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFE8C3E6)),
                    backgroundColor: Color(0xFFDDDDDD),
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Vervollständigen \nSie Ihr Profil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompleteProfilePage(
                      userId: userId,
                      completedQuestions: completedQuestions,
                    ),
                  ),
                );
              },
              child: Text(
                'Bearbeiten',
                style: TextStyle(
                  color: Color(0xFF7D4666),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitePartnerButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF7FCCB1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PartnerEinladungPage()),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Partner einladen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, String iconPath) {
    return GestureDetector(
      onTap: () {
        // Handle menu item tap
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 22.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF414254),
                ),
              ),
              Spacer(),
              Icon(
                Icons.chevron_right,
                color: Color(0xFF414254),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeBox(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/graphics/profile_star_icon.svg',
            width: 40,
            height: 40,
          ),
          SizedBox(height: 10),
          Text(
            'Mehr Sitzungen erhalten',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF414254),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Mehr Optionen freischalten, um Konflikte zu entschärfen und Ihre Beziehung zu stärken',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF414254),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7FCCB1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return KostenpflichtigDialog();
                },
              );
            },
            child: Text(
              'Jetzt upgraden!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
