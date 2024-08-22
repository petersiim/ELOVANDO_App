import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'mitteilungen_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userId;
  CustomAppBar({required this.userId});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 10);

  Future<Map<String, dynamic>> _fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    return userDoc.data() as Map<String, dynamic>? ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AppBar(
            title: Text(''),
            centerTitle: true,
          );
        }

        final userData = snapshot.data!;
        final userName = userData['name'] as String? ?? 'User';
        final userImageUrl = userData['profileImageUrl'] as String?;

        return AppBar(
          backgroundColor: Colors.white,
          elevation: 5,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(userId: userId)),
                );
              },
              child: CircleAvatar(
                radius: 23,
                backgroundImage: userImageUrl != null ? NetworkImage(userImageUrl) : null,
                child: userImageUrl == null ? Icon(Icons.person) : null,
              ),
            ),
          ),
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage(userId: userId)),
              );
            },
            child: Text(
              userName,
              style: TextStyle(
                color: Color(0xFF414254),
                fontSize: 18,
                fontFamily: 'Inter',
              ),
            ),
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: IconButton(
                icon: SvgPicture.asset('assets/graphics/bell_icon.svg'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MitteilungenPage(userId: userId)),
                  );
                },
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(30.0),
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