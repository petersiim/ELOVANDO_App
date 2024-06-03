import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Background image
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/graphics/onboarding_bg.svg',
              fit: BoxFit.cover,
            ),
          ),
          // Bottom SVG
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/graphics/onboarding_bg_bottom.svg',
              fit: BoxFit.cover,
            ),
          ),
          // Add your onboarding content here
        ],
      ),
    );
  }
}
