import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FirstPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Background image
          Positioned.fill(
            child: SvgPicture.asset(
              'graphics/graphic_forest_landing_page.svg',
              fit: BoxFit.cover,
              placeholderBuilder: (BuildContext context) => Center(child: CircularProgressIndicator()),
            ),
          ),
          // Add your other UI components here
          Center(
            child: Text(
              'Welcome to the App!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
