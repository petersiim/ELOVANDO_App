import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'custom_app_bar.dart';
import 'home_page.dart';
import 'firestore_service.dart';

class PartnerEinladungPage extends StatefulWidget {
  @override
  _PartnerEinladungPageState createState() => _PartnerEinladungPageState();
}

class _PartnerEinladungPageState extends State<PartnerEinladungPage> {
  late Future<String> _invitationCodeFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _codeController = TextEditingController();

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
    await Share.share('Trete mir bei ELOVANDO bei! Lade die App herunter und verwende diesen Code, um dich zu verbinden: $invitationCode');
  }

  Future<void> _linkPartner() async {
    String code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte gib einen Einladungscode ein')),
      );
      return;
    }

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      bool success = await _firestoreService.linkPartners(currentUser.uid, code);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erfolgreich mit deinem Partner verbunden!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(userId: currentUser.uid)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verbindung fehlgeschlagen. Bitte überprüfe den Code und versuche es erneut.')),
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
                'Lass uns jetzt noch deinen Partner überzeugen, damit ihr gemeinsam ELOVANDO für eure Beziehung nutzen könnt, denn unsere Love Sessions könnt ihr nur gemeinsam durchführen. Sende deinem Partner eine Einladung oder gib den Code ein, um die ELOVANDO-App gemeinsam zu nutzen.',
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
                    return Text('Fehler: ${snapshot.error}');
                  }
                  return Column(
                    children: [
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
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  hintText: 'Einladungscode des Partners eingeben',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _linkPartner,
                child: Text('Mit Partner verbinden'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7FCCB1),
                  foregroundColor: Colors.white,
                ),
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