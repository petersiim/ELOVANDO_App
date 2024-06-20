import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userId;
  CustomAppBar({required this.userId});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

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
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
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
            IconButton(
              icon: SvgPicture.asset('assets/graphics/bell_icon.svg'),
              onPressed: () {
                // Handle notification bell press
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(2.0),
            child: Container(
              color: Color(0xFFDEDEDE),
              height: 2.0,
            ),
          ),
        );
      },
    );
  }
}
