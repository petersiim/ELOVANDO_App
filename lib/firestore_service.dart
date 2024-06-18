// firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      String userId = _auth.currentUser!.uid;
      await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  Future<void> markProfileStepCompleted(String step) async {
    try {
      String userId = _auth.currentUser!.uid;
      await _db.collection('users').doc(userId).update({step: true});
    } catch (e) {
      print('Error marking profile step completed: $e');
    }
  }
}
