import 'package:flutter/material.dart';

class RegistrationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
      ),
      body: Center(
        child: Text(
          'Registration',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
