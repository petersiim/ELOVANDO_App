import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'app_nav_bar.dart';

class SessionsPage extends StatelessWidget {
  final String userId;

  const SessionsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      body: Center(
        child: Text('Sessions Page'),
      ),
    );
  }
}
