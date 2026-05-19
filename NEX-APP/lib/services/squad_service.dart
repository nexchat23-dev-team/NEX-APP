import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SquadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new squad
  Future<String> createSquad({
    required String name,
    required String description,
    String? game,
    int maxMembers = 5,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final squadRef = await _firestore.collection('squads').add({
        'name': name,
        'description': description,
        'game': game,
        'leaderId': currentUserId,
        'members': [currentUserId],
        'maxMembers': maxMembers,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      return squadRef.id;
    } catch (e) {
      debugPrint('Error creating squad: $e');
      rethrow;
    }
  }

  // Join a squad
  Future<void> joinSquad(String squadId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final squadRef = _firestore.collection('squads').doc(squadId);
      final squadDoc = await squadRef.get();

      if (!squadDoc.exists) throw Exception('Squad not found');

      final squadData = squadDoc.data()!;
      final members = List<String>.from(squadData['members'] ?? []);
      final maxMembers = squadData['maxMembers'] ?? 5;

      if (members.contains(currentUserId)) throw Exception('Already a member');
      if (members.length >= maxMembers) throw Exception('Squad is full');

      members.add(currentUserId!);
      await squadRef.update({'members': members});
    } catch (e) {
      debugPrint('Error joining squad: $e');
      rethrow;
    }
  }

  // Leave a squad
  Future<void> leaveSquad(String squadId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final squadRef = _firestore.collection('squads').doc(squadId);
      final squadDoc = await squadRef.get();

      if (!squadDoc.exists) throw Exception('Squad not found');

      final squadData = squadDoc.data()!;
      final members = List<String>.from(squadData['members'] ?? []);
      final leaderId = squadData['leaderId'];

      if (!members.contains(currentUserId)) throw Exception('Not a member');

      // If leaving member is leader, transfer leadership or disband
      if (currentUserId == leaderId && members.length > 1) {
        // Transfer to another member
        members.remove(currentUserId);
        final newLeader = members.first;
        await squadRef.update({
          'members': members,
          'leaderId': newLeader,
        });
      } else if (members.length == 1) {
        // Disband squad
        await squadRef.delete();
      } else {
        members.remove(currentUserId);
        await squadRef.update({'members': members});
      }
    } catch (e) {
      debugPrint('Error leaving squad: $e');
      rethrow;
    }
  }

  // Get squads stream
  Stream<QuerySnapshot> getSquads() {
    try {
      return _firestore
          .collection('squads')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting squads: $e');
      });
    } catch (e) {
      debugPrint('Error setting up squads stream: $e');
      rethrow;
    }
  }

  // Get user's squads
  Stream<QuerySnapshot> getUserSquads() {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return _firestore
          .collection('squads')
          .where('members', arrayContains: currentUserId)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting user squads: $e');
      });
    } catch (e) {
      debugPrint('Error setting up user squads stream: $e');
      rethrow;
    }
  }

  // Send message in squad
  Future<void> sendSquadMessage({
    required String squadId,
    required String text,
    String type = 'text',
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('squads')
          .doc(squadId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'text': text,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending squad message: $e');
      rethrow;
    }
  }

  // Get squad messages
  Stream<QuerySnapshot> getSquadMessages(String squadId) {
    try {
      return _firestore
          .collection('squads')
          .doc(squadId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting squad messages: $e');
      });
    } catch (e) {
      debugPrint('Error setting up squad messages stream: $e');
      rethrow;
    }
  }

  // Create session in squad
  Future<String> createSquadSession({
    required String squadId,
    required String title,
    required DateTime startTime,
    String? description,
    String? gameMode,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final sessionRef = await _firestore
          .collection('squads')
          .doc(squadId)
          .collection('sessions')
          .add({
        'title': title,
        'description': description,
        'gameMode': gameMode,
        'startTime': startTime,
        'creatorId': currentUserId,
        'participants': [currentUserId],
        'status': 'scheduled', // scheduled, active, completed, cancelled
        'createdAt': FieldValue.serverTimestamp(),
      });

      return sessionRef.id;
    } catch (e) {
      debugPrint('Error creating squad session: $e');
      rethrow;
    }
  }

  // Get squad sessions
  Stream<QuerySnapshot> getSquadSessions(String squadId) {
    try {
      return _firestore
          .collection('squads')
          .doc(squadId)
          .collection('sessions')
          .orderBy('startTime')
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting squad sessions: $e');
      });
    } catch (e) {
      debugPrint('Error setting up squad sessions stream: $e');
      rethrow;
    }
  }
}