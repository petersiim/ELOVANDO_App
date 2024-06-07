import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfilErstellenPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
              'assets/graphics/prof_erstellen_back_button.svg'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Profil erstellen',
          style: TextStyle(
            color: Color(0xFF414254),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/graphics/onboarding_bg.svg',
              fit: BoxFit.fill,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 20),
                Text(
                  'So möchtest du von deinem Partner / deiner Partnerin genannt werden:',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF414254),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Name eingeben',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: Color(0xFFF7F7F7),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Partner Name eingeben',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: Color(0xFFF7F7F7),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 100,
            right: 32,
            child: GestureDetector(
              onTap: () {
                // Handle profile creation
              },
              child: Container(
                child: Center(
                  child: SvgPicture.asset(
                    'assets/graphics/prof_erstellen_weiter_button.svg',
                    width: 55,
                    height: 55,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: SvgPicture.asset(
                    'assets/graphics/leave_icon.svg',
                    width: 40,
                    height: 40,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
