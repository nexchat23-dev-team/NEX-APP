import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Post a new status
  Future<String> postStatus({
    required String text,
    String? mediaUrl,
    String mediaType = 'text', // text, image, video
    Duration expiresIn = const Duration(hours: 24),
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final expiresAt = DateTime.now().add(expiresIn);

      final statusRef = await _firestore.collection('statuses').add({
        'userId': currentUserId,
        'text': text,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'expiresAt': expiresAt,
        'createdAt': FieldValue.serverTimestamp(),
        'views': 0,
        'isActive': true,
      });

      return statusRef.id;
    } catch (e) {
      debugPrint('Error posting status: $e');
      rethrow;
    }
  }

  // Get all active statuses (friends/following)
  Stream<QuerySnapshot> getStatuses() {
    try {
      return _firestore
          .collection('statuses')
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThan: DateTime.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting statuses: $e');
      });
    } catch (e) {
      debugPrint('Error setting up statuses stream: $e');
      rethrow;
    }
  }

  // Get user's own statuses
  Stream<QuerySnapshot> getUserStatuses() {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return _firestore
          .collection('statuses')
          .where('userId', isEqualTo: currentUserId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting user statuses: $e');
      });
    } catch (e) {
      debugPrint('Error setting up user statuses stream: $e');
      rethrow;
    }
  }

  // View a status (increment view count)
  Future<void> viewStatus(String statusId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final statusRef = _firestore.collection('statuses').doc(statusId);
      await statusRef.update({
        'views': FieldValue.increment(1),
      });

      // Record that user viewed this status
      await _firestore.collection('statusViews').add({
        'statusId': statusId,
        'userId': currentUserId,
        'viewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error viewing status: $e');
      rethrow;
    }
  }

  // Delete a status
  Future<void> deleteStatus(String statusId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final statusRef = _firestore.collection('statuses').doc(statusId);
      final statusDoc = await statusRef.get();

      if (!statusDoc.exists) throw Exception('Status not found');

      final statusData = statusDoc.data()!;
      if (statusData['userId'] != currentUserId) throw Exception('Not authorized');

      await statusRef.update({'isActive': false});
    } catch (e) {
      debugPrint('Error deleting status: $e');
      rethrow;
    }
  }

  // Get status viewers
  Stream<QuerySnapshot> getStatusViewers(String statusId) {
    try {
      return _firestore
          .collection('statusViews')
          .where('statusId', isEqualTo: statusId)
          .orderBy('viewedAt', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting status viewers: $e');
      });
    } catch (e) {
      debugPrint('Error setting up status viewers stream: $e');
      rethrow;
    }
  }

  // React to a status
  Future<void> reactToStatus(String statusId, String reaction) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _firestore.collection('statusReactions').add({
        'statusId': statusId,
        'userId': currentUserId,
        'reaction': reaction,
        'reactedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error reacting to status: $e');
      rethrow;
    }
  }

  // Get user's own statuses (alias for getUserStatuses for clarity)
  Stream<QuerySnapshot> getMyStatuses() {
    return getUserStatuses();
  }

  // Update a status
  Future<void> updateStatus(
    String statusId, {
    String? text,
    String? mediaUrl,
    String? mediaType,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final statusRef = _firestore.collection('statuses').doc(statusId);
      final statusDoc = await statusRef.get();

      if (!statusDoc.exists) throw Exception('Status not found');

      final statusData = statusDoc.data()!;
      if (statusData['userId'] != currentUserId) throw Exception('Not authorized');

      final updates = <String, dynamic>{};
      if (text != null) updates['text'] = text;
      if (mediaUrl != null) updates['mediaUrl'] = mediaUrl;
      if (mediaType != null) updates['mediaType'] = mediaType;
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await statusRef.update(updates);
    } catch (e) {
      debugPrint('Error updating status: $e');
      rethrow;
    }
  }

  // Get reactions for a status
  Stream<QuerySnapshot> getStatusReactions(String statusId) {
    try {
      return _firestore
          .collection('statusReactions')
          .where('statusId', isEqualTo: statusId)
          .orderBy('reactedAt', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting status reactions: $e');
      });
    } catch (e) {
      debugPrint('Error setting up status reactions stream: $e');
      return const Stream.empty();
    }
  }
}