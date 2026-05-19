import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new session
  Future<String> createSession({
    required String title,
    required DateTime startTime,
    String? description,
    String? game,
    String? gameMode,
    int maxParticipants = 10,
    bool isPublic = true,
    String? squadId, // Optional: session tied to a squad
    String? clanId, // Optional: session tied to a clan
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final sessionRef = await _firestore.collection('sessions').add({
        'title': title,
        'description': description,
        'game': game,
        'gameMode': gameMode,
        'startTime': startTime,
        'endTime': null,
        'creatorId': currentUserId,
        'participants': [currentUserId],
        'maxParticipants': maxParticipants,
        'isPublic': isPublic,
        'status': 'scheduled', // scheduled, active, completed, cancelled
        'squadId': squadId,
        'clanId': clanId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return sessionRef.id;
    } catch (e) {
      debugPrint('Error creating session: $e');
      rethrow;
    }
  }

  // Join a session
  Future<void> joinSession(String sessionId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final sessionRef = _firestore.collection('sessions').doc(sessionId);
      final sessionDoc = await sessionRef.get();

      if (!sessionDoc.exists) throw Exception('Session not found');

      final sessionData = sessionDoc.data()!;
      final participants = List<String>.from(sessionData['participants'] ?? []);
      final maxParticipants = sessionData['maxParticipants'] ?? 10;
      final status = sessionData['status'];

      if (status != 'scheduled') {
        throw Exception('Session is not open for joining');
      }
      if (participants.contains(currentUserId)) {
        throw Exception('Already joined');
      }
      if (participants.length >= maxParticipants) {
        throw Exception('Session is full');
      }

      participants.add(currentUserId!);
      await sessionRef.update({'participants': participants});
    } catch (e) {
      debugPrint('Error joining session: $e');
      rethrow;
    }
  }

  // Leave a session
  Future<void> leaveSession(String sessionId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final sessionRef = _firestore.collection('sessions').doc(sessionId);
      final sessionDoc = await sessionRef.get();

      if (!sessionDoc.exists) throw Exception('Session not found');

      final sessionData = sessionDoc.data()!;
      final participants = List<String>.from(sessionData['participants'] ?? []);
      final creatorId = sessionData['creatorId'];

      if (!participants.contains(currentUserId)) {
        throw Exception('Not a participant');
      }

      participants.remove(currentUserId);

      if (participants.isEmpty) {
        // Cancel session if no participants left
        await sessionRef.update({
          'participants': participants,
          'status': 'cancelled',
        });
      } else {
        // If creator leaves, assign to another participant
        String newCreatorId = creatorId;
        if (currentUserId == creatorId) {
          newCreatorId = participants.first;
        }

        await sessionRef.update({
          'participants': participants,
          'creatorId': newCreatorId,
        });
      }
    } catch (e) {
      debugPrint('Error leaving session: $e');
      rethrow;
    }
  }

  // Start a session
  Future<void> startSession(String sessionId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final sessionRef = _firestore.collection('sessions').doc(sessionId);
      final sessionDoc = await sessionRef.get();

      if (!sessionDoc.exists) throw Exception('Session not found');

      final sessionData = sessionDoc.data()!;
      final creatorId = sessionData['creatorId'];

      if (currentUserId != creatorId) {
        throw Exception('Only creator can start session');
      }

      await sessionRef.update({
        'status': 'active',
        'startedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error starting session: $e');
      rethrow;
    }
  }

  // End a session
  Future<void> endSession(String sessionId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final sessionRef = _firestore.collection('sessions').doc(sessionId);
      final sessionDoc = await sessionRef.get();

      if (!sessionDoc.exists) throw Exception('Session not found');

      final sessionData = sessionDoc.data()!;
      final creatorId = sessionData['creatorId'];

      if (currentUserId != creatorId) {
        throw Exception('Only creator can end session');
      }

      await sessionRef.update({
        'status': 'completed',
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error ending session: $e');
      rethrow;
    }
  }

  // Get sessions stream
  Stream<QuerySnapshot> getSessions({bool publicOnly = false}) {
    try {
      Query query = _firestore.collection('sessions');

      if (publicOnly) {
        query = query.where('isPublic', isEqualTo: true);
      }

      return query
          .where('status', whereIn: ['scheduled', 'active'])
          .orderBy('startTime')
          .snapshots()
          .handleError((e) {
            debugPrint('Error getting sessions: $e');
          });
    } catch (e) {
      debugPrint('Error setting up sessions stream: $e');
      rethrow;
    }
  }

  // Get user's sessions
  Stream<QuerySnapshot> getUserSessions() {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return _firestore
          .collection('sessions')
          .where('participants', arrayContains: currentUserId)
          .orderBy('startTime')
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting user sessions: $e');
      });
    } catch (e) {
      debugPrint('Error setting up user sessions stream: $e');
      rethrow;
    }
  }

  // Fetch available public sessions once
  Future<List<Map<String, dynamic>>> fetchPublicSessions() async {
    try {
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('isPublic', isEqualTo: true)
          .where('status', whereIn: ['scheduled', 'active'])
          .orderBy('startTime')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Unknown Session',
          'game': data['game'] ?? 'Unknown Game',
          'status': data['status'] ?? 'scheduled',
          'participants': List<String>.from(data['participants'] ?? []),
          'maxParticipants': data['maxParticipants'] ?? 10,
          'startTime': data['startTime'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching public sessions: $e');
      rethrow;
    }
  }

  // Get a single session by ID
  Future<Map<String, dynamic>?> getSessionById(String sessionId) async {
    try {
      final sessionDoc = await _firestore.collection('sessions').doc(sessionId).get();
      if (!sessionDoc.exists) return null;
      final data = sessionDoc.data()!;
      return {
        'id': sessionDoc.id,
        'title': data['title'] ?? 'Unknown Session',
        'game': data['game'] ?? 'Unknown Game',
        'description': data['description'] ?? '',
        'status': data['status'] ?? 'scheduled',
        'participants': List<String>.from(data['participants'] ?? []),
        'maxParticipants': data['maxParticipants'] ?? 10,
        'isPublic': data['isPublic'] ?? true,
        'startTime': data['startTime'],
        'creatorId': data['creatorId'],
      };
    } catch (e) {
      debugPrint('Error getting session by ID: $e');
      rethrow;
    }
  }

  // Search public sessions by game title
  Future<List<Map<String, dynamic>>> searchPublicSessions(String query) async {
    try {
      final searchQuery = query.toLowerCase().trim();
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('isPublic', isEqualTo: true)
          .where('status', whereIn: ['scheduled', 'active'])
          .orderBy('startTime')
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Unknown Session',
              'game': data['game'] ?? 'Unknown Game',
              'status': data['status'] ?? 'scheduled',
              'participants': List<String>.from(data['participants'] ?? []),
              'maxParticipants': data['maxParticipants'] ?? 10,
              'startTime': data['startTime'],
            };
          })
          .where((session) {
            final title = (session['title'] as String).toLowerCase();
            final game = (session['game'] as String).toLowerCase();
            return title.contains(searchQuery) || game.contains(searchQuery);
          })
          .toList();
    } catch (e) {
      debugPrint('Error searching public sessions: $e');
      rethrow;
    }
  }

  // Update session metadata
  Future<void> updateSession(String sessionId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update(updates);
    } catch (e) {
      debugPrint('Error updating session: $e');
      rethrow;
    }
  }

  // Send message in session
  Future<void> sendSessionMessage({
    required String sessionId,
    required String text,
    String type = 'text',
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('sessions')
          .doc(sessionId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'text': text,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending session message: $e');
      rethrow;
    }
  }

  // Get session messages
  Stream<QuerySnapshot> getSessionMessages(String sessionId) {
    try {
      return _firestore
          .collection('sessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting session messages: $e');
      });
    } catch (e) {
      debugPrint('Error setting up session messages stream: $e');
      rethrow;
    }
  }

  // Add participant to session (for private sessions)
  Future<void> addParticipant(String sessionId, String userId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final sessionRef = _firestore.collection('sessions').doc(sessionId);
      final sessionDoc = await sessionRef.get();

      if (!sessionDoc.exists) throw Exception('Session not found');

      final sessionData = sessionDoc.data()!;
      final creatorId = sessionData['creatorId'];
      final participants = List<String>.from(sessionData['participants'] ?? []);
      final maxParticipants = sessionData['maxParticipants'] ?? 10;

      if (currentUserId != creatorId) {
        throw Exception('Only creator can add participants');
      }
      if (participants.contains(userId)) {
        throw Exception('User already a participant');
      }
      if (participants.length >= maxParticipants) {
        throw Exception('Session is full');
      }

      participants.add(userId);
      await sessionRef.update({'participants': participants});
    } catch (e) {
      debugPrint('Error adding participant: $e');
      rethrow;
    }
  }

  // Remove participant from session
  Future<void> removeParticipant(String sessionId, String userId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final sessionRef = _firestore.collection('sessions').doc(sessionId);
      final sessionDoc = await sessionRef.get();

      if (!sessionDoc.exists) throw Exception('Session not found');

      final sessionData = sessionDoc.data()!;
      final creatorId = sessionData['creatorId'];
      final participants = List<String>.from(sessionData['participants'] ?? []);

      if (currentUserId != creatorId && currentUserId != userId) {
        throw Exception('Only creator or the participant can remove');
      }

      if (!participants.contains(userId)) {
        throw Exception('User is not a participant');
      }

      participants.remove(userId);

      if (participants.isEmpty) {
        await sessionRef.update({
          'participants': participants,
          'status': 'cancelled',
        });
      } else {
        await sessionRef.update({'participants': participants});
      }
    } catch (e) {
      debugPrint('Error removing participant: $e');
      rethrow;
    }
  }
}
