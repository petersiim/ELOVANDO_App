import 'package:flutter/material.dart';

class LoveSessionPage extends StatelessWidget {
  const LoveSessionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Love Session Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Hello from the Love Session Page!',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}