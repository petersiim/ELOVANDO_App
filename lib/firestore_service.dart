// firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  Future<void> updateUserProfileCompletion(String userId, Map<String, bool> completedQuestions) async {
    try {
      await _db.collection('users').doc(userId).update({
        'profileCompletion': completedQuestions,
      });
    } catch (e) {
      print('Error updating user profile completion: $e');
    }
  }

  Future<Map<String, bool>> getUserProfileCompletion(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      
      if (data != null && data.containsKey('profileCompletion')) {
        Map<String, dynamic> profileCompletion = data['profileCompletion'];
        return profileCompletion.map((key, value) => MapEntry(key, value as bool));
      } else {
        return {};
      }
    } catch (e) {
      print('Error fetching user profile completion: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
      return doc.data() as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('Error fetching user profile: $e');
      return {};
    }
  }
}