import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  AppNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/graphics/icon_menu_home.svg',
            width: 24,
            height: 24,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/graphics/icon_menu_sessions.svg',
            width: 24,
            height: 24,
          ),
          label: 'Sessions',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/graphics/icon_menu_love_session.svg',
            width: 24,
            height: 24,
          ),
          label: 'Love Session',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/graphics/icon_menu_inputs.svg',
            width: 24,
            height: 24,
          ),
          label: 'Inputs',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/graphics/icon_menu_chat.svg',
            width: 24,
            height: 24,
          ),
          label: 'Chat',
        ),
      ],
    );
  }
}
