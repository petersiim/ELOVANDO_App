import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allow overflow
      children: [
        BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/graphics/icon_menu_home.svg',
                color: currentIndex == 0 ? Color(0xFF7D4666) : Color(0xFF414254),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/graphics/icon_menu_sessions.svg',
                color: currentIndex == 1 ? Color(0xFF7D4666) : Color(0xFF414254),
              ),
              label: 'Sessions',
            ),
            BottomNavigationBarItem(
              icon: SizedBox.shrink(), // Placeholder for the Love Session icon
              label: '',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/graphics/icon_menu_inputs.svg',
                color: currentIndex == 3 ? Color(0xFF7D4666) : Color(0xFF414254),
              ),
              label: 'Inputs',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/graphics/icon_menu_chat.svg',
                color: currentIndex == 4 ? Color(0xFF7D4666) : Color(0xFF414254),
              ),
              label: 'Chat',
            ),
          ],
          selectedItemColor: Color(0xFF7D4666),
          unselectedItemColor: Color(0xFF414254),
          selectedLabelStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'Regular',
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 10,
            fontFamily: 'Regular',
          ),
        ),
        Positioned(
          top: -30, // Adjust the value to move the icon and text up
          left: MediaQuery.of(context).size.width / 2 - 30, // Center the icon
          child: Column(
            children: [
              Container(
                width: 60, // Increase the size of the icon
                height: 60, // Increase the size of the icon
                decoration: BoxDecoration(
                  color: Color(0xFF7FCCB1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/graphics/icon_menu_love_session.svg',
                    width: 60,
                    height: 60,
                  ),
                ),
              ),
              SizedBox(height: 4), // Space between the icon and text
              Text(
                'Love Session',
                style: TextStyle(
                  color: Color(0xFF7FCCB1),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Regular',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
