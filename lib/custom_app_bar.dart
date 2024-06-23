import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart'; // Import the ProfilePage

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userId;
  CustomAppBar({required this.userId});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 10); // Increase the height as needed

  Future<Map<String, dynamic>> _fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    return userDoc.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AppBar(
            title: Text('Loading...'),
            centerTitle: true,
          );
        }

        final userData = snapshot.data!;
        final userName = userData['name'];
        final userImageUrl = userData['profileImageUrl'];

        return AppBar(
          backgroundColor: Colors.white,
          elevation: 5,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0), // Adjust the padding value here
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(userId: userId)), // Navigate to the ProfilePage
                );
              },
              child: CircleAvatar(
                radius: 23,
                backgroundImage: NetworkImage(userImageUrl),
              ),
            ),
          ),
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage(userId: userId,)), // Navigate to the ProfilePage
              );
            },
            child: Text(
              userName,
              style: TextStyle(
                color: Color(0xFF414254),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0), // Add padding here
              child: IconButton(
                icon: SvgPicture.asset('assets/graphics/bell_icon.svg'),
                onPressed: () {
                  // Handle notification bell press
                },
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(30.0), // Adjust the height as needed
            child: Container(
              child: Container(
                color: Color(0xFFDEDEDE),
                height: 2.0,
              ),
            ),
          ),
        );
      },
    );
  }
}
