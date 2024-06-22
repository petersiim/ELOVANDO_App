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
        Container(
          height: 80, // Increase the height of the BottomNavigationBar
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0), // Add padding
                  child: SvgPicture.asset(
                    'assets/graphics/icon_menu_home.svg',
                    color: currentIndex == 0 ? Color(0xFF7D4666) : Color(0xFF414254),
                  ),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0), // Add padding
                  child: SvgPicture.asset(
                    'assets/graphics/icon_menu_sessions.svg',
                    color: currentIndex == 1 ? Color(0xFF7D4666) : Color(0xFF414254),
                  ),
                ),
                label: 'Sessions',
              ),
              BottomNavigationBarItem(
                icon: SizedBox.shrink(), // Placeholder for the Love Session icon
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0), // Add padding
                  child: SvgPicture.asset(
                    'assets/graphics/icon_menu_inputs.svg',
                    color: currentIndex == 3 ? Color(0xFF7D4666) : Color(0xFF414254),
                  ),
                ),
                label: 'Inputs',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0), // Add padding
                  child: SvgPicture.asset(
                    'assets/graphics/icon_menu_chat.svg',
                    color: currentIndex == 4 ? Color(0xFF7D4666) : Color(0xFF414254),
                  ),
                ),
                label: 'Chat',
              ),
            ],
            selectedItemColor: Color(0xFF7D4666),
            unselectedItemColor: Color(0xFF414254),
            selectedLabelStyle: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'Regular',
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 8,
              fontFamily: 'Regular',
            ),
          ),
        ),
        Positioned(
          top: -19, // Adjust the value to move the icon and text up
          left: MediaQuery.of(context).size.width / 2 - 30, // Center the icon
          child: GestureDetector(
            onTap: () => onTap(2), // Set the index for "Love Session"
            child: Column(
              children: [
                Container(
                  width: 65, // Increase the size of the icon
                  height: 65, // Increase the size of the icon
                  decoration: BoxDecoration(
                    color: Color(0xFF7FCCB1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/graphics/icon_menu_love_session.svg',
                      width: 65,
                      height: 65,
                    ),
                  ),
                ),
                SizedBox(height: 6), // Space between the icon and text
                Text(
                  'Love Session',
                  style: TextStyle(
                    color: Color(0xFF7FCCB1),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Regular',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
