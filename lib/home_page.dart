import 'package:flutter/material.dart';
import 'custom_app_bar.dart';

class HomePage extends StatelessWidget {
  final String userId;

  HomePage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: CustomAppBar(userId: userId),
      body: Center(
        child: Text(
          'Welcome to the Home Page',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF414254),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
