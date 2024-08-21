import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'custom_app_bar.dart';
import 'home_page.dart';

class PartnerEinladungPage extends StatefulWidget {
  @override
  _PartnerEinladungPageState createState() => _PartnerEinladungPageState();
}

class _PartnerEinladungPageState extends State<PartnerEinladungPage> {
  late Future<String> _invitationCodeFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _invitationCodeFuture = _generateInvitationCode();
  }

  Future<String> _generateInvitationCode() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    String invitationCode = 'ELOVANDO_${userId.substring(0, 6)}';
    
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'invitationCode': invitationCode});

    return invitationCode;
  }

  void _shareInvitation(String invitationCode) async {
    String inviteLink = 'https://elovando.com/invite?code=$invitationCode';
    await Share.share('Join me on ELOVANDO! Download the app and use this code to connect: $invitationCode\n\nOr use this link: $inviteLink');
    
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await _processInvitationCode(currentUser, invitationCode);
    }
  }

  Future<void> _processInvitationCode(User user, String invitationCode) async {
  if (invitationCode.isNotEmpty) {
    QuerySnapshot query = await _firestore
        .collection('users')
        .where('invitationCode', isEqualTo: invitationCode)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      String inviterId = query.docs.first.id;
      String? inviterThreadId;
      
      // Safely access the 'loveSessionThreadId' field
      var data = query.docs.first.data();
      if (data is Map<String, dynamic> && data.containsKey('loveSessionThreadId')) {
        inviterThreadId = data['loveSessionThreadId'] as String?;
      }

      await _firestore.collection('users').doc(user.uid).update({
        'invitedBy': inviterId,
        if (inviterThreadId != null) 'loveSessionThreadId': inviterThreadId,
      });

      await _firestore.collection('users').doc(inviterId).update({
        'invitedUsers': FieldValue.arrayUnion([user.uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully connected with your partner!')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: CustomAppBar(userId: userId),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20),
              Container(
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -80,
                      child: SvgPicture.asset(
                        'assets/graphics/anonymus_icon_with_plus.svg',
                        width: 120,
                        height: 120,
                      ),
                    ),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.transparent,
                      child: FutureBuilder<String>(
                        future: _fetchUserImageUrl(userId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey,
                            );
                          }
                          return CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(snapshot.data!),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Partner-Einladung',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF414254),
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Lass uns jetzt noch deinen Partner überzeugen, damit ihr gemeinsam ELOVANDO für eure Beziehung nutzen könnt, denn unsere Love Sessions könnt ihr nur gemeinsam durchführen. Sende deinem Partner eine Einladung, um die ELOVANDO-App zu nutzen.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF414254),
                  fontFamily: 'Inter',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              FutureBuilder<String>(
                future: _invitationCodeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  return Column(
                    children: [
                      QrImageView(
                        data: snapshot.data!,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Einladungscode: ${snapshot.data!}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF414254),
                          fontFamily: 'Inter',
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _shareInvitation(snapshot.data!),
                        icon: Icon(Icons.share),
                        label: Text('Partner-Einladung teilen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF7D4666),
                          foregroundColor: Colors.white,
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(double.infinity, 56),
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage(userId: userId)),
                  );
                },
                child: Text(
                  'Später einladen',
                  style: TextStyle(
                    color: Color(0xFF7FCCB1),
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _fetchUserImageUrl(String userId) async {
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    return userDoc['profileImageUrl'];
  }
}