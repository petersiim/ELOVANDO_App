// invitation_dialog.dart
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
                  SizedBox(height: 40), // Space for the close button
                  Text(
                    'Einladung senden über:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF414254),
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInvitationOption('Whatsapp', 'assets/graphics/whatsapp_icon.svg'),
                      _buildInvitationOption('SMS', 'assets/graphics/sms_icon.svg'),
                      _buildInvitationOption('E-mail', 'assets/graphics/E-mail_icon.svg'),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  Row(
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
                      SizedBox(width: 16),
                      Container(
                        color: Colors.white,
                        padding: EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/graphics/qr_code.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Handle scan action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7FCCB1),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Scanne jetzt!'),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -10,
              top: -10,
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

Widget _buildInvitationOption(String label, String iconPath) {
  return Column(
    children: [
      SvgPicture.asset(
        iconPath,
        width: 48,
        height: 48,
      ),
      SizedBox(height: 8),
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF414254),
          fontFamily: 'Inter',
        ),
      ),
    ],
  );
}
