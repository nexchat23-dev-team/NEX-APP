import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class CallService {
  final SupabaseClient _client = SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<String> initiateCall({
    required String receiverId,
    bool isVideo = false,
    String? groupId,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client.from('calls').insert({
        'callerId': currentUserId,
        'receiverId': receiverId,
        'groupId': groupId,
        'isVideo': isVideo,
        'status': 'pending',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'endedAt': null,
        'connectedAt': null,
      }).select().single();

      if (response is! Map<String, dynamic>) {
        throw Exception('Unable to create call');
      }
      final callId = response['id']?.toString();
      if (callId == null) {
        throw Exception('Unable to create call');
      }

      await _client.from('callHistory').insert({
        'callId': callId,
        'callerId': currentUserId,
        'receiverId': receiverId,
        'recipientId': receiverId,
        'groupId': groupId,
        'isVideo': isVideo,
        'status': 'pending',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      return callId;
    } catch (e) {
      debugPrint('Error initiating call: $e');
      rethrow;
    }
  }

  Future<void> updateCallStatus(String callId, String status) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      if (status == 'active') {
        updates['connectedAt'] = DateTime.now().toUtc().toIso8601String();
      }

      if (status == 'ended' || status == 'rejected') {
        updates['endedAt'] = DateTime.now().toUtc().toIso8601String();
      }

      await _client.from('calls').update(updates).eq('id', callId);
      await _client.from('callHistory').update({
        'status': status,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }).eq('callId', callId);
    } catch (e) {
      debugPrint('Error updating call status: $e');
      rethrow;
    }
  }

  Future<void> acceptCall(String callId) async {
    await updateCallStatus(callId, 'active');
  }

  Future<void> rejectCall(String callId) async {
    await updateCallStatus(callId, 'rejected');
  }

  Future<void> endCall(String callId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final callData = await _client.from('calls').select().eq('id', callId).single();
      if (callData == null) return;

      final connectedAt = callData['connectedAt'];
      final now = DateTime.now().toUtc();
      int duration = 0;
      if (connectedAt is String) {
        duration = now.difference(DateTime.parse(connectedAt)).inSeconds;
      }

      await _client.from('calls').update({
        'status': 'ended',
        'endedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'duration': duration,
      }).eq('id', callId);

      await _client.from('callHistory').update({
        'status': 'ended',
        'duration': duration,
        'timestamp': now.toIso8601String(),
      }).eq('callId', callId);
    } catch (e) {
      debugPrint('Error ending call: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getActiveCalls() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return _client
        .from('calls')
        .stream(primaryKey: ['id'])
        .inFilter('status', ['pending', 'active'])
        .order('createdAt', ascending: false)
        .map((rows) {
          return rows.where((row) {
            final callerId = row['callerId']?.toString();
            final receiverId = row['receiverId']?.toString();
            return callerId == currentUserId || receiverId == currentUserId;
          }).toList();
        })
        .handleError((e) {
          debugPrint('Error getting active calls: $e');
        });
  }

  Stream<List<Map<String, dynamic>>> getCallHistory() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return _client
        .from('callHistory')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: false)
        .map((rows) {
          return rows.where((row) {
            final callerId = row['callerId']?.toString();
            final receiverId = row['receiverId']?.toString();
            return callerId == currentUserId || receiverId == currentUserId;
          }).toList();
        })
        .handleError((e) {
          debugPrint('Error getting call history: $e');
        });
  }

  Future<void> addIceCandidate(
      String callId, Map<String, dynamic> candidate) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _client.from('iceCandidates').insert({
        'callId': callId,
        'from': currentUserId,
        'candidate': candidate,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error adding ICE candidate: $e');
      rethrow;
    }
  }

  Future<void> setSDP(String callId, String type, String sdp) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _client.from('sdp').upsert({
        'call_id': callId,
        'from': currentUserId,
        'type': type,
        'sdp': sdp,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error setting SDP: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getIceCandidates(String callId) {
    return _client
        .from('iceCandidates')
        .stream(primaryKey: ['id'])
        .eq('callId', callId)
        .order('timestamp', ascending: true)
        .handleError((e) {
          debugPrint('Error getting ICE candidates: $e');
        });
  }

  Stream<List<Map<String, dynamic>>> getSDP(String callId) {
    return _client
        .from('sdp')
        .stream(primaryKey: ['id'])
        .eq('call_id', callId)
        .handleError((e) {
          debugPrint('Error getting SDP: $e');
        });
  }

  Future<String> initiateGroupCall({
    required String groupId,
    bool isVideo = false,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client.from('groupCalls').insert({
        'groupId': groupId,
        'initiatorId': currentUserId,
        'isVideo': isVideo,
        'status': 'pending',
        'participants': [currentUserId],
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      if (response is! Map<String, dynamic>) {
        throw Exception('Unable to create group call');
      }
      final groupCallId = response['id']?.toString();
      if (groupCallId == null) {
        throw Exception('Unable to create group call');
      }
      return groupCallId;
    } catch (e) {
      debugPrint('Error initiating group call: $e');
      rethrow;
    }
  }

  Future<void> joinGroupCall(String groupCallId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final groupCallData = await _client.from('groupCalls').select().eq('id', groupCallId).single();
      if (groupCallData == null) {
        throw Exception('Group call not found');
      }

      final participants = List<String>.from(groupCallData['participants'] ?? []);
      if (!participants.contains(currentUserId)) {
        participants.add(currentUserId!);
        await _client.from('groupCalls').update({'participants': participants}).eq('id', groupCallId);
        await _client.from('groupCallParticipants').insert({
          'group_call_id': groupCallId,
          'userId': currentUserId!,
          'joinedAt': DateTime.now().toUtc().toIso8601String(),
          'status': 'connected',
        });
      }
    } catch (e) {
      debugPrint('Error joining group call: $e');
      rethrow;
    }
  }

  Future<void> leaveGroupCall(String groupCallId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final groupCallData = await _client.from('groupCalls').select().eq('id', groupCallId).single();
      if (groupCallData == null) {
        return;
      }

      final participants = List<String>.from(groupCallData['participants'] ?? []);
      final initiatorId = groupCallData['initiatorId'];

      participants.remove(currentUserId);

      if (participants.isEmpty) {
        await _client.from('groupCalls').update({
          'status': 'ended',
          'endTime': DateTime.now().toUtc().toIso8601String(),
          'participants': participants,
        }).eq('id', groupCallId);
      } else {
        await _client.from('groupCalls').update({'participants': participants}).eq('id', groupCallId);
        if (currentUserId == initiatorId && participants.isNotEmpty) {
          await _client.from('groupCalls').update({'initiatorId': participants.first}).eq('id', groupCallId);
        }
      }

      await _client.from('groupCallParticipants').update({
        'leftAt': DateTime.now().toUtc().toIso8601String(),
        'status': 'disconnected',
      }).eq('group_call_id', groupCallId).eq('userId', currentUserId!);
    } catch (e) {
      debugPrint('Error leaving group call: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getActiveGroupCalls() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    return _client
        .from('groupCalls')
        .stream(primaryKey: ['id'])
        .inFilter('status', ['pending', 'active'])
        .order('createdAt', ascending: false)
        .handleError((e) {
          debugPrint('Error getting active group calls: $e');
        });
  }
}
