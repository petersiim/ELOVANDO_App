import 'package:flutter/material.dart';

class FirstPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: <Widget>[
                // Background image
                Positioned.fill(
                  child: Image.asset(
                    'graphics/bg_forest.jpg',  // Ensure the image path is correct
                    fit: BoxFit.cover,
                  ),
                ),
                // Gradient overlay with 20% opacity
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF22577A).withOpacity(0.2), // Top color with 20% opacity
                          Color(0xFFF9AC36).withOpacity(0.2), // Bottom color with 20% opacity
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
                // Add your other UI components here
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.1),
                    child: Text(
                      'Welcome to the App!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: constraints.maxWidth * 0.06, // Responsive font size
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
