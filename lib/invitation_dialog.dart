import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void showInvitationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          clipBehavior: Clip.none, // Allow the close button to be outside the dialog
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10), // Space for the close button
                  Text(
                    'Einladung senden über:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF414254),
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF7F7F7), // Grey background color
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInvitationOption('assets/graphics/whatsapp_icon.svg'),
                        _buildInvitationOption('assets/graphics/sms_icon.svg'),
                        _buildInvitationOption('assets/graphics/E-mail_icon.svg'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF7F7F7), // Grey background color
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dein Partner ist gerade hier?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF414254),
                                  fontFamily: 'Inter',
                                ),
                              ),
                              Text(
                                'Lass ihn den QR-Code scannen, um die App direkt zu verbinden.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF414254),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          children: [
                            Container(
                              color: Colors.white,
                              padding: EdgeInsets.all(8),
                              child: Placeholder(
                                fallbackWidth: 80,
                                fallbackHeight: 80,
                                color: Colors.grey,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(height: 8), // Space between the placeholder and the text
                            Container(
                              color: Color(0xFF7FCCB1),
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Text(
                                'Scanne jetzt!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
            Positioned(
              right: -25,
              top: -25,
              child: IconButton(
                icon: SvgPicture.asset('assets/graphics/pop_up_X_button.svg'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildInvitationOption(String iconPath) {
  return SvgPicture.asset(
    iconPath,
    width: 48,
    height: 48,
  );
}
