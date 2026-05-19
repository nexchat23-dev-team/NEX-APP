import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new clan
  Future<String> createClan({
    required String name,
    required String description,
    String? motto,
    String? bannerUrl,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final clanRef = await _firestore.collection('clans').add({
        'name': name,
        'description': description,
        'motto': motto,
        'bannerUrl': bannerUrl,
        'founderId': currentUserId,
        'admins': [currentUserId],
        'members': [currentUserId],
        'level': 1,
        'experience': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      return clanRef.id;
    } catch (e) {
      debugPrint('Error creating clan: $e');
      rethrow;
    }
  }

  // Join clan request
  Future<void> requestJoinClan(String clanId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _firestore.collection('clanJoinRequests').add({
        'clanId': clanId,
        'userId': currentUserId,
        'status': 'pending', // pending, approved, rejected
        'requestedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error requesting to join clan: $e');
      rethrow;
    }
  }

  // Approve join request (admin only)
  Future<void> approveJoinRequest(String requestId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final requestDoc = await _firestore.collection('clanJoinRequests').doc(requestId).get();
      if (!requestDoc.exists) throw Exception('Request not found');

      final requestData = requestDoc.data()!;
      final clanId = requestData['clanId'];
      final userId = requestData['userId'];

      // Add user to clan members
      final clanRef = _firestore.collection('clans').doc(clanId);
      final clanDoc = await clanRef.get();
      if (!clanDoc.exists) throw Exception('Clan not found');

      final clanData = clanDoc.data()!;
      final members = List<String>.from(clanData['members'] ?? []);
      if (!members.contains(userId)) {
        members.add(userId);
        await clanRef.update({'members': members});
      }

      // Update request status
      await _firestore.collection('clanJoinRequests').doc(requestId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': currentUserId,
      });
    } catch (e) {
      debugPrint('Error approving join request: $e');
      rethrow;
    }
  }

  // Leave clan
  Future<void> leaveClan(String clanId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final clanRef = _firestore.collection('clans').doc(clanId);
      final clanDoc = await clanRef.get();

      if (!clanDoc.exists) throw Exception('Clan not found');

      final clanData = clanDoc.data()!;
      final members = List<String>.from(clanData['members'] ?? []);
      final admins = List<String>.from(clanData['admins'] ?? []);
      final founderId = clanData['founderId'];

      if (!members.contains(currentUserId)) throw Exception('Not a member');

      // Remove from members and admins
      members.remove(currentUserId);
      admins.remove(currentUserId);

      if (members.isEmpty) {
        // Disband clan if no members left
        await clanRef.delete();
      } else {
        // If founder is leaving, assign new founder
        String newFounderId = founderId;
        if (currentUserId == founderId) {
          newFounderId = members.first;
          if (!admins.contains(newFounderId)) {
            admins.add(newFounderId);
          }
        }

        await clanRef.update({
          'members': members,
          'admins': admins,
          'founderId': newFounderId,
        });
      }
    } catch (e) {
      debugPrint('Error leaving clan: $e');
      rethrow;
    }
  }

  // Get clans stream
  Stream<QuerySnapshot> getClans() {
    try {
      return _firestore
          .collection('clans')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting clans: $e');
      });
    } catch (e) {
      debugPrint('Error setting up clans stream: $e');
      rethrow;
    }
  }

  // Get user's clans
  Stream<QuerySnapshot> getUserClans() {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return _firestore
          .collection('clans')
          .where('members', arrayContains: currentUserId)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting user clans: $e');
      });
    } catch (e) {
      debugPrint('Error setting up user clans stream: $e');
      rethrow;
    }
  }

  // Send message in clan
  Future<void> sendClanMessage({
    required String clanId,
    required String text,
    String type = 'text',
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('clans')
          .doc(clanId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'text': text,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending clan message: $e');
      rethrow;
    }
  }

  // Get clan messages
  Stream<QuerySnapshot> getClanMessages(String clanId) {
    try {
      return _firestore
          .collection('clans')
          .doc(clanId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting clan messages: $e');
      });
    } catch (e) {
      debugPrint('Error setting up clan messages stream: $e');
      rethrow;
    }
  }

  // Create clan event
  Future<String> createClanEvent({
    required String clanId,
    required String title,
    required DateTime eventDate,
    String? description,
    String? location,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final eventRef = await _firestore
          .collection('clans')
          .doc(clanId)
          .collection('events')
          .add({
        'title': title,
        'description': description,
        'eventDate': eventDate,
        'location': location,
        'createdBy': currentUserId,
        'attendees': [currentUserId],
        'createdAt': FieldValue.serverTimestamp(),
      });

      return eventRef.id;
    } catch (e) {
      debugPrint('Error creating clan event: $e');
      rethrow;
    }
  }

  // Get clan events
  Stream<QuerySnapshot> getClanEvents(String clanId) {
    try {
      return _firestore
          .collection('clans')
          .doc(clanId)
          .collection('events')
          .orderBy('eventDate')
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting clan events: $e');
      });
    } catch (e) {
      debugPrint('Error setting up clan events stream: $e');
      rethrow;
    }
  }

  // Get join requests for clan (admin only)
  Stream<QuerySnapshot> getClanJoinRequests(String clanId) {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return _firestore
          .collection('clanJoinRequests')
          .where('clanId', isEqualTo: clanId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting clan join requests: $e');
      });
    } catch (e) {
      debugPrint('Error setting up clan join requests stream: $e');
      rethrow;
    }
  }
}