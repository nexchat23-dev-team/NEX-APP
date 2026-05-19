import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Initiate a call
  Future<String> initiateCall({
    required String receiverId,
    bool isVideo = false,
    String? groupId, // For group calls
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final callRef = await _firestore.collection('calls').add({
        'callerId': currentUserId,
        'receiverId': receiverId,
        'groupId': groupId,
        'isVideo': isVideo,
        'status': 'calling', // calling, connected, ended, missed, rejected
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'duration': 0,
      });

      // Add to call history
      await _firestore.collection('callHistory').add({
        'callId': callRef.id,
        'callerId': currentUserId,
        'receiverId': receiverId,
        'groupId': groupId,
        'isVideo': isVideo,
        'status': 'calling',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return callRef.id;
    } catch (e) {
      debugPrint('Error initiating call: $e');
      rethrow;
    }
  }

  // Accept a call
  Future<void> acceptCall(String callId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final callRef = _firestore.collection('calls').doc(callId);
      await callRef.update({
        'status': 'connected',
        'connectedAt': FieldValue.serverTimestamp(),
      });

      // Update call history
      final historyQuery = await _firestore
          .collection('callHistory')
          .where('callId', isEqualTo: callId)
          .get();

      for (var doc in historyQuery.docs) {
        await doc.reference.update({'status': 'connected'});
      }
    } catch (e) {
      debugPrint('Error accepting call: $e');
      rethrow;
    }
  }

  // Reject a call
  Future<void> rejectCall(String callId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final callRef = _firestore.collection('calls').doc(callId);
      await callRef.update({
        'status': 'rejected',
        'endTime': FieldValue.serverTimestamp(),
      });

      // Update call history
      final historyQuery = await _firestore
          .collection('callHistory')
          .where('callId', isEqualTo: callId)
          .get();

      for (var doc in historyQuery.docs) {
        await doc.reference.update({'status': 'rejected'});
      }
    } catch (e) {
      debugPrint('Error rejecting call: $e');
      rethrow;
    }
  }

  // End a call
  Future<void> endCall(String callId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final callRef = _firestore.collection('calls').doc(callId);
      final callDoc = await callRef.get();

      if (callDoc.exists) {
        final callData = callDoc.data()!;
        final connectedAt = callData['connectedAt'] as Timestamp?;
        final duration = connectedAt != null
            ? DateTime.now().difference(connectedAt.toDate()).inSeconds
            : 0;

        await callRef.update({
          'status': 'ended',
          'endTime': FieldValue.serverTimestamp(),
          'duration': duration,
        });

        // Update call history
        final historyQuery = await _firestore
            .collection('callHistory')
            .where('callId', isEqualTo: callId)
            .get();

        for (var doc in historyQuery.docs) {
          await doc.reference.update({
            'status': 'ended',
            'duration': duration,
          });
        }
      }
    } catch (e) {
      debugPrint('Error ending call: $e');
      rethrow;
    }
  }

  // Get active calls for current user
  Stream<QuerySnapshot> getActiveCalls() {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return _firestore
          .collection('calls')
          .where('status', whereIn: ['calling', 'connected'])
          .where(Filter.or(
            Filter('callerId', isEqualTo: currentUserId),
            Filter('receiverId', isEqualTo: currentUserId),
          ))
          .orderBy('startTime', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting active calls: $e');
      });
    } catch (e) {
      debugPrint('Error setting up active calls stream: $e');
      rethrow;
    }
  }

  // Get call history
  Stream<QuerySnapshot> getCallHistory() {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return _firestore
          .collection('callHistory')
          .where(Filter.or(
            Filter('callerId', isEqualTo: currentUserId),
            Filter('receiverId', isEqualTo: currentUserId),
          ))
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting call history: $e');
      });
    } catch (e) {
      debugPrint('Error setting up call history stream: $e');
      rethrow;
    }
  }

  // WebRTC: Add ICE candidate
  Future<void> addIceCandidate(String callId, Map<String, dynamic> candidate) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('calls')
          .doc(callId)
          .collection('iceCandidates')
          .add({
        'from': currentUserId,
        'candidate': candidate,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding ICE candidate: $e');
      rethrow;
    }
  }

  // WebRTC: Set SDP offer/answer
  Future<void> setSDP(String callId, String type, String sdp) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final sdpRef = _firestore
          .collection('calls')
          .doc(callId)
          .collection('sdp')
          .doc(type); // 'offer' or 'answer'

      await sdpRef.set({
        'from': currentUserId,
        'type': type,
        'sdp': sdp,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error setting SDP: $e');
      rethrow;
    }
  }

  // WebRTC: Get ICE candidates
  Stream<QuerySnapshot> getIceCandidates(String callId) {
    try {
      return _firestore
          .collection('calls')
          .doc(callId)
          .collection('iceCandidates')
          .orderBy('timestamp')
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting ICE candidates: $e');
      });
    } catch (e) {
      debugPrint('Error setting up ICE candidates stream: $e');
      rethrow;
    }
  }

  // WebRTC: Get SDP
  Stream<QuerySnapshot> getSDP(String callId) {
    try {
      return _firestore
          .collection('calls')
          .doc(callId)
          .collection('sdp')
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting SDP: $e');
      });
    } catch (e) {
      debugPrint('Error setting up SDP stream: $e');
      rethrow;
    }
  }

  // Initiate group call
  Future<String> initiateGroupCall({
    required String groupId,
    bool isVideo = false,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final groupCallRef = await _firestore.collection('groupCalls').add({
        'groupId': groupId,
        'initiatorId': currentUserId,
        'isVideo': isVideo,
        'status': 'calling', // calling, connected, ended
        'participants': [currentUserId],
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
      });

      return groupCallRef.id;
    } catch (e) {
      debugPrint('Error initiating group call: $e');
      rethrow;
    }
  }

  // Join group call
  Future<void> joinGroupCall(String groupCallId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final groupCallRef = _firestore.collection('groupCalls').doc(groupCallId);
      final groupCallDoc = await groupCallRef.get();

      if (!groupCallDoc.exists) throw Exception('Group call not found');

      final groupCallData = groupCallDoc.data()!;
      final participants = List<String>.from(groupCallData['participants'] ?? []);

      if (!participants.contains(currentUserId)) {
        participants.add(currentUserId!);
        await groupCallRef.update({'participants': participants});

        // Add participant record
        await groupCallRef.collection('participants').add({
          'userId': currentUserId,
          'joinedAt': FieldValue.serverTimestamp(),
          'status': 'connected',
        });
      }
    } catch (e) {
      debugPrint('Error joining group call: $e');
      rethrow;
    }
  }

  // Leave group call
  Future<void> leaveGroupCall(String groupCallId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final groupCallRef = _firestore.collection('groupCalls').doc(groupCallId);
      final groupCallDoc = await groupCallRef.get();

      if (groupCallDoc.exists) {
        final groupCallData = groupCallDoc.data()!;
        final participants = List<String>.from(groupCallData['participants'] ?? []);
        final initiatorId = groupCallData['initiatorId'];

        participants.remove(currentUserId);

        if (participants.isEmpty) {
          // End call if no participants left
          await groupCallRef.update({
            'status': 'ended',
            'endTime': FieldValue.serverTimestamp(),
            'participants': participants,
          });
        } else {
          await groupCallRef.update({'participants': participants});

          // If initiator leaves, assign to another participant
          if (currentUserId == initiatorId && participants.isNotEmpty) {
            await groupCallRef.update({'initiatorId': participants.first});
          }
        }

        // Update participant status
        final participantQuery = await groupCallRef
            .collection('participants')
            .where('userId', isEqualTo: currentUserId)
            .get();

        for (var doc in participantQuery.docs) {
          await doc.reference.update({
            'leftAt': FieldValue.serverTimestamp(),
            'status': 'disconnected',
          });
        }
      }
    } catch (e) {
      debugPrint('Error leaving group call: $e');
      rethrow;
    }
  }

  // Get active group calls for user's groups
  Stream<QuerySnapshot> getActiveGroupCalls() {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // This would need to be filtered by groups the user is member of
      // For now, return all active group calls
      return _firestore
          .collection('groupCalls')
          .where('status', whereIn: ['calling', 'connected'])
          .orderBy('startTime', descending: true)
          .snapshots()
          .handleError((e) {
        debugPrint('Error getting active group calls: $e');
      });
    } catch (e) {
      debugPrint('Error setting up active group calls stream: $e');
      rethrow;
    }
  }
}