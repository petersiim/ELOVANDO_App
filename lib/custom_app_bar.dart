import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userId;
  CustomAppBar({required this.userId});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 20); // Increase the height as needed

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
            child: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(userImageUrl),
            ),
          ),
          title: Text(
            userName,
            style: TextStyle(
              color: Color(0xFF414254),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0), // Add padding here
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
              padding: EdgeInsets.only(bottom: 10.0), // Add padding below the AppBar content
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
