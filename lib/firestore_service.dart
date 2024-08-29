// firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) {
      throw Exception('Invalid user ID');
    }
    try {
      await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfileCompletion(String userId, Map<String, bool> completedQuestions) async {
    if (userId.isEmpty) {
      throw Exception('Invalid user ID');
    }
    try {
      await _db.collection('users').doc(userId).update({
        'profileCompletion': completedQuestions,
      });
    } catch (e) {
      print('Error updating user profile completion: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserInputHistory(String userId) async {
    final userRef = _db.collection('users').doc(userId);
    final inputHistoryRef = userRef.collection('inputHistory');

    final querySnapshot = await inputHistoryRef
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> addUserInput(String userId, String textInput, int moodValue) async {
    final userRef = _db.collection('users').doc(userId);
    final inputHistoryRef = userRef.collection('inputHistory');

    await inputHistoryRef.add({
      'textInput': textInput,
      'moodValue': moodValue,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Keep only the last 10 entries
    final querySnapshot = await inputHistoryRef
        .orderBy('timestamp', descending: true)
        .limit(11)
        .get();

    if (querySnapshot.docs.length > 10) {
      final lastDoc = querySnapshot.docs.last;
      await lastDoc.reference.delete();
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

  Future<bool> linkPartners(String userId, String invitationCode) async {
    try {
      // Find the partner with the given invitation code
      QuerySnapshot query = await _db
          .collection('users')
          .where('invitationCode', isEqualTo: invitationCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return false; // No user found with the given invitation code
      }

      String partnerId = query.docs.first.id;
      
      if (partnerId == userId) {
        return false; // Cannot link with self
      }

      // Get both users' data
      DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();
      DocumentSnapshot partnerDoc = await _db.collection('users').doc(partnerId).get();

      // Check if either user is already linked
      if (userDoc.data() != null && (userDoc.data() as Map<String, dynamic>).containsKey('partnerId') ||
          partnerDoc.data() != null && (partnerDoc.data() as Map<String, dynamic>).containsKey('partnerId')) {
        return false; // One of the users is already linked
      }

      // Create or get the love session thread
      String threadId = await _createOrGetLoveSessionThread(userId, partnerId);

      // Update both users with partner information and thread ID
      await _db.collection('users').doc(userId).update({
        'partnerId': partnerId,
        'loveSessionThreadId': threadId,
      });

      await _db.collection('users').doc(partnerId).update({
        'partnerId': userId,
        'loveSessionThreadId': threadId,
      });

      return true;
    } catch (e) {
      print('Error linking partners: $e');
      return false;
    }
  }

  Future<String> _createOrGetLoveSessionThread(String userId1, String userId2) async {
    // Check if a thread already exists for these users
    QuerySnapshot query = await _db
        .collection('loveSessionThreads')
        .where('participants', arrayContainsAny: [userId1, userId2])
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id; // Return existing thread ID
    }

    // If no thread exists, create a new one
    DocumentReference threadRef = await _db.collection('loveSessionThreads').add({
      'participants': [userId1, userId2],
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return threadRef.id; // Return the new thread ID
  }

  Future<void> resetLoveSessionThread(String userId) async {
    try {
      DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();
      String? threadId = (userDoc.data() as Map<String, dynamic>?)?['loveSessionThreadId'];

      if (threadId != null) {
        // Clear the existing thread content
        await _db.collection('loveSessionThreads').doc(threadId).update({
          'messages': [],
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        print('Love session thread reset successfully');
      } else {
        print('No love session thread found for the user');
      }
    } catch (e) {
      print('Error resetting love session thread: $e');
    }
  }
}