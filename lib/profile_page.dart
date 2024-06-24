import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'kostenpflichtig_dialog.dart'; // Import the KostenpflichtigDialog widget

class ProfilePage extends StatelessWidget {
  final String userId;
  ProfilePage({required this.userId});

  Future<Map<String, dynamic>> _fetchUserData() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    return userDoc.data() as Map<String, dynamic>;
  }

  int _calculateAge(String birthdate) {
    List<String> parts = birthdate.split('/');
    int day = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int year = int.parse(parts[2]);

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
          final userName = userData['name'];
          final userImageUrl = userData['profileImageUrl'];
          final userBirthdate = userData['birthdate']; // Fetch the birthdate
          final userAge = _calculateAge(userBirthdate);

          return SingleChildScrollView(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40.0), // Space for the X icon
                    Center(
                      child: CircleAvatar(
                        radius: 50, // Make the profile picture bigger
                        backgroundImage: NetworkImage(userImageUrl),
                      ),
                    ),
                    SizedBox(
                        height:
                            10), // Add space between the profile picture and the rest of the content
                    Center(
                      child: Text(
                        '$userName, $userAge', // Display name and age
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          fontFamily:
                              'Medium', // Ensure the correct font is loaded in your project
                          color: Color(0xFF414254),
                        ),
                      ),
                    ),
                    SizedBox(
                        height:
                            30), // Add space between the location and the violet box
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF7D4666),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    value: 0.7, // Example progress value
                                    strokeWidth: 6.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFE8C3E6)),
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
                                // Handle edit profile action
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
                    ),
                    SizedBox(
                        height:
                            20), // Adjust space between the violet box and the line
                    Container(
                      height: 1.0,
                      color: Color(0xFF98999D),
                    ),
                    Container(
                      color: Color(0xFFDEDEDE),
                      child: Column(
                        children: [
                          SizedBox(
                              height:
                                  20), // Add space between the line and the first box
                          _buildMenuItem(
                            context,
                            'Einstellungen',
                            'assets/graphics/profile_settings_icon.svg',
                          ),
                          _buildMenuItem(
                            context,
                            'Datenschutz',
                            'assets/graphics/profile_datenschutz_icon.svg',
                          ),
                          _buildMenuItem(
                            context,
                            'Über uns',
                            'assets/graphics/profile_ueberuns_icon.svg',
                          ),
                          SizedBox(height: 20), // Add space before the last box
                          Container(
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 38.0, // Position for the X icon
                  left: 16.0,
                  child: IconButton(
                    icon: SvgPicture.asset(
                      'assets/graphics/profile_screen_X_icon.svg',
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Navigate back
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
}
